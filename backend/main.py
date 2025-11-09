from fastapi import FastAPI
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Any
from database import engine, Base
import models
from dotenv import load_dotenv
import os
import requests
import urllib.parse
import asyncio
from auth import router as auth_router
from fastapi import Query, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
from models import User, UserQuestionHistory, UserFavoriteHadith, Hadith, Setting, ChatSession, ChatMessage
from sqlalchemy import select, text
from vector_search import search_hadiths
import logging
from auth import get_current_user
from auth import get_current_user_optional
from sqlalchemy.orm import selectinload
from sqlalchemy import or_, and_
from datetime import datetime, timedelta
from collections import Counter
from pydantic import EmailStr
from fastapi import UploadFile, File
import csv
from models import JourneyModule, JourneyStep, UserJourneyProgress
from fastapi import Body
from models import QuranVerse, Dua, Zikr, Tafsir, QuranAudio
import json
import httpx
from textwrap import shorten
import uuid
from scripts.migrate_and_seed import run as migrate_and_seed_run
from math import radians, degrees, sin, cos, atan2
from fastapi.staticfiles import StaticFiles
from typing import Literal
import re
try:
    from PIL import Image
    PIL_AVAILABLE = True
except Exception:
    PIL_AVAILABLE = False

# Hadis AI Model import
try:
    from ai_models.hadis_model import hadis_ai_model
    HADIS_AI_AVAILABLE = True
    print("✅ Hadis AI modeli import edildi")
except ImportError as e:
    HADIS_AI_AVAILABLE = False
    print(f"⚠️ Hadis AI modeli import edilemedi: {e}")

# .env dosyasını yükle
load_dotenv()
print('DEBUG: SECRET_KEY =', os.getenv('SECRET_KEY'))

app = FastAPI(
    swagger_ui_parameters={
        "persistAuthorization": True,
        "displayRequestDuration": True,
        "defaultModelsExpandDepth": -1,
    }
)

# Statik dosya servisi (avatarlar)
_backend_dir = os.path.abspath(os.path.dirname(__file__))
_static_dir = os.path.join(_backend_dir, "static")
_avatars_dir = os.path.join(_static_dir, "avatars")
os.makedirs(_avatars_dir, exist_ok=True)
app.mount("/static", StaticFiles(directory=_static_dir), name="static")

# Sağlık kontrolü: her zaman 200 döndür, DB durumunu bilgi olarak ekle
from sqlalchemy import text as _sql_text

def _register_health_route():
    try:
        existing_paths = {getattr(r, "path", None) for r in app.routes}
    except Exception:
        existing_paths = set()
    if "/health" not in existing_paths:
        async def health():
            try:
                async with AsyncSessionLocal() as session:
                    await session.execute(_sql_text("SELECT 1"))
                return {"status": "ok", "db": "ok"}
            except Exception:
                # DB hata verse bile uygulamayı sağlıklı say
                return {"status": "ok", "db": "error"}
        # GET ile yayınla, 200 döner
        app.add_api_route("/health", health, methods=["GET"])

_register_health_route()

# Async tablo oluşturucu
async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

@app.on_event("startup")
async def on_startup():
    # Startup’ta DB’e bağlanma hatalarını yutarak uygulamayı ayakta tut
    try:
        await create_tables()
        # Sequence onarımı: tabloların id sequence değerlerini MAX(id) ile senkronize et
        try:
            async with engine.begin() as conn:
                tables = [
                    ("chat_messages", "id"),
                    ("chat_sessions", "id"),
                    ("user_question_history", "id"),
                ]
                for tbl, col in tables:
                    # Mevcut en büyük id’yi al
                    max_res = await conn.execute(text(f"SELECT COALESCE(MAX({col}), 0) FROM {tbl}"))
                    max_id = max_res.scalar() or 0

                    # İlgili sequence adını al (varsa)
                    seq_res = await conn.execute(
                        text("SELECT pg_get_serial_sequence(:tbl, :col)").bindparams(tbl=tbl, col=col)
                    )
                    seq_name = seq_res.scalar()

                    if not seq_name:
                        # Kolon default’u üzerinden sequence var mı diye bak
                        default_res = await conn.execute(text(
                            """
                            SELECT column_default
                            FROM information_schema.columns
                            WHERE table_name = :tbl AND column_name = :col
                            """
                        ).bindparams(tbl=tbl, col=col))
                        column_default = default_res.scalar()
                        if column_default and 'nextval' in column_default:
                            # nextval('schema.seq'::regclass) ifadesinden sequence adını çıkarma denemesi
                            try:
                                start = column_default.find("'")
                                end = column_default.find("'", start + 1)
                                inferred_seq = column_default[start+1:end]
                                seq_name = inferred_seq
                                print(f"[SEQ-FIX] {tbl}.{col} için default üzerinden sequence bulundu: {seq_name}")
                            except Exception:
                                seq_name = None
                        
                    if not seq_name:
                        # Sequence yoksa güvenli bir şekilde oluştur ve default’u ayarla
                        fallback_seq = f"{tbl}_{col}_seq"
                        print(f"[SEQ-FIX] {tbl}.{col} için sequence bulunamadı. Oluşturuluyor: {fallback_seq}")
                        await conn.execute(text(f"CREATE SEQUENCE IF NOT EXISTS {fallback_seq}"))
                        await conn.execute(text(f"ALTER SEQUENCE {fallback_seq} OWNED BY {tbl}.{col}"))
                        await conn.execute(text(f"ALTER TABLE {tbl} ALTER COLUMN {col} SET DEFAULT nextval('{fallback_seq}'::regclass)"))
                        seq_name = fallback_seq

                    if max_id == 0:
                        print(f"[SEQ-FIX] {tbl}.{col} tablosu boş (max_id=0), sequence değiştirilmeyecek: {seq_name}")
                        continue

                    # Sequence’i MAX(id) değerine ayarla (TRUE → nextval max_id+1 döner)
                    await conn.execute(
                        text("SELECT setval(:seq::regclass, :newval, TRUE)").bindparams(seq=seq_name, newval=max_id)
                    )
                    print(f"[SEQ-FIX] {tbl}.{col} için {seq_name} setval({max_id}, TRUE) uygulandı.")
        except Exception:
            print("[SEQ-FIX] Sequence onarımı başarısız, uygulama başlamaya devam ediyor.")
        # Örnek journey modülü ve adımı ekle (sadece hiç modül yoksa)
        from models import JourneyModule, JourneyStep
        from database import AsyncSessionLocal
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(JourneyModule))
            if not result.scalars().first():
                module = JourneyModule(title="Siyer-i Nebi", description="Peygamberimizin hayatı ve örnekliği", icon="menu_book")
                session.add(module)
                await session.commit()
                await session.refresh(module)
                step1 = JourneyStep(module_id=module.id, title="Doğumu ve çocukluğu", order=1, content="Peygamberimizin doğumu ve çocukluk dönemi.")
                step2 = JourneyStep(module_id=module.id, title="Peygamberlik öncesi hayatı", order=2, content="Peygamberlikten önceki hayatı.")
                session.add_all([step1, step2])
                await session.commit()
    except Exception as e:
        logging.exception("Startup DB işlemleri başarısız. Uygulama çalışmaya devam ediyor.")
    # Migration + seed işlemlerini arka planda tek seferlik tetikle
    try:
        asyncio.create_task(migrate_and_seed_run())
    except Exception:
        logging.exception("Startup migrate+seed arka plan görevi başlatılamadı")

# CORS ayarları (geliştirme için tüm kaynaklara izin verildi)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth")

# Composite endpointleri kaydet: bu import, app nesnesine yeni yollar ekler
import composite_app  # Kur'an, Dua, Zikir, Tefsir, Kıraatçı, Günlük içerikler

# İstek ve yanıt modelleri
class AskRequest(BaseModel):
    question: str
    source_filter: Optional[str] = "all"  # "quran", "hadis", "all"

class SourceItem(BaseModel):
    type: str
    name: str

class AskResponse(BaseModel):
    answer: str
    sources: List[SourceItem]

# Session yönetimi için modeller
class SessionRequest(BaseModel):
    session_token: Optional[str] = None

class SessionResponse(BaseModel):
    session_token: str
    messages: List[dict]

class ChatRequest(BaseModel):
    question: str
    session_token: Optional[str] = None
    source_filter: Optional[str] = "all"

class ChatResponse(BaseModel):
    answer: str
    sources: List[SourceItem]
    session_token: str

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_URL = os.getenv("GEMINI_URL")

# Ultimate RAG entegrasyonu (OpenAI/Claude tercihleriyle)
from ultimate_rag_main import (
    search_hadiths_ultimate,
    generate_ai_response_with_fallback,
)

@app.post("/api/ask", response_model=AskResponse)
async def ask_ai(request: AskRequest, current_user: User = Depends(get_current_user_optional)):
    import logging
    from sqlalchemy import func
    from datetime import datetime
    user_id = current_user.id if current_user else None
    # --- Sorgu limiti kontrolü ---
    if current_user and not current_user.is_premium:
        from database import AsyncSessionLocal
        from models import UserQuestionHistory
        # Varsayılan limit UI ile uyumlu olacak şekilde 3
        daily_limit_raw = await get_setting('ai_daily_limit', '3')
        try:
            daily_limit = int(str(daily_limit_raw))
        except Exception:
            daily_limit = 1
        limit_message = await get_setting('ai_limit_message', 'Günlük ücretsiz sorgu limitinizi doldurdunuz. Premium’a geçin!')
        today = datetime.utcnow().date()
        start_of_day = datetime.combine(today, datetime.min.time())
        async with AsyncSessionLocal() as session:
            result = await session.execute(
                select(func.count()).where(
                    UserQuestionHistory.user_id == user_id,
                    UserQuestionHistory.created_at >= start_of_day
                )
            )
            count = result.scalar() or 0
            if count >= daily_limit:
                raise HTTPException(status_code=429, detail=limit_message)
    # --- Ultimate RAG: vektör arama ve akıllı fallback yanıt üretimi ---
    hadith_dicts = await search_hadiths_ultimate(request.question, top_k=3)
    answer, used_fallback, response_type = generate_ai_response_with_fallback(
        request.question,
        hadith_dicts,
        True
    )
    # Hadis bulunamadığında ayardan okunabilir bir fallback mesajı göster
    if not hadith_dicts:
        answer = await get_setting(
            'ai_no_hadith_message',
            'Bu konuda güvenilir hadis kaynağı bulunamadı. Lütfen sorunuzu farklı şekilde ifade edin.'
        )
    # Kaynakları hazırla (UI için sade gösterim)
    sources = []
    for h in hadith_dicts:
        base = f"{h['full_reference']} - {h['text'][:60]}" if h.get('full_reference') else f"{h.get('source','')} - {h.get('reference','')}"
        score = h.get('score')
        display = f"{base} (skor: {score:.2f})" if isinstance(score, (int, float)) and score is not None else base
        sources.append(SourceItem(type="hadis", name=display))
    ai_source = "ultimate_rag"
    # Gelişmiş kaynaklar kutusu mantığı
    system_prompt = (
        "Sen, İslami App'in yapay zeka asistanısın. "
        "Sadece Kur'an, Kütüb-i Sitte ve muteber fıkıh kaynaklarından cevap ver. "
        "Her cevabın sonunda kaynak belirt. Kişisel yorum ekleme. "
        "Soruyu anlamazsan kullanıcıdan daha açık sormasını iste."
    )
    # Kaynakları her zaman göster: hadis bulunduysa listeyi koru,
    # eşleşme tespit edilirse öncelikli olarak filtrelenmiş listeyi kullan.
    answer_lower = answer.lower()
    if hadith_dicts:
        filtered_sources = []
        for h in hadith_dicts:
            h_text = (h.get('text') or '')
            h_ref = (h.get('reference') or '')
            if (h_text[:40].lower() in answer_lower) or (h_ref.lower() in answer_lower):
                filtered_sources.append(SourceItem(type="hadis", name=f"{h.get('full_reference') or (h.get('source','') + ' - ' + h_ref)}"))
        # AI suffix: model türüne göre etiketle
        _rt = (response_type or '').lower()
        _suffix = ' -AI'
        if 'claude' in _rt:
            _suffix = ' -AI CL'
        elif 'gemini' in _rt:
            _suffix = ' -AI GMN'
        filtered_sources.append(SourceItem(type="ai", name=f"AI Asistan{_suffix}"))
        sources = filtered_sources if filtered_sources else sources
    else:
        sources = []
    # --- Sistem promptunun aynısını döndürmeyi engelle ---
    system_prompt_start = system_prompt[:80].lower()
    # Kısa/tek kelime sorularda kullanıcıyı yönlendir
    if len(request.question.strip().split()) < 2:
        answer = "Sorunuzu daha açık yazar mısınız?"
        sources = []
    # Modelden gelen cevap sistem promptuna çok benziyorsa veya 'anlaşıldı' ile başlıyorsa override et
    if answer.lower().startswith(system_prompt_start) or "resmi yapay zeka asistanı" in answer.lower() or answer.lower().startswith("anlaşıldı") or "bundan sonra" in answer.lower():
        answer = "Sorunuzu daha açık yazar mısınız?"
        sources = []
    # Selamlaşma mesajlarında özel karşılama
    if request.question.strip().lower() in ["selam", "merhaba", "merhabalar", "selamünaleyküm"]:
        answer = "Merhaba! Size nasıl yardımcı olabilirim?"
        sources = []
    # Genel yönlendirme veya açıklama isteyen cevaplarda kaynaklar kutusu gösterilmesin
    # Yönlendirme niteliğindeki cevaplarda dahi hadis bulunduysa kaynaklar korunur.
    # --- Kullanıcı geçmişine otomatik kayıt ---
    if user_id is not None:
        from database import AsyncSessionLocal
        from models import UserQuestionHistory
        try:
            async with AsyncSessionLocal() as session:
                hadith_id = None
                if hadith_dicts:
                    first = hadith_dicts[0]
                    hadith_id = first.get('id')
                history = UserQuestionHistory(user_id=user_id, question=request.question, answer=answer, hadith_id=hadith_id)
                session.add(history)
                await session.commit()
        except Exception as e:
            logging.exception("Geçmiş kaydı HATASI", exc_info=True)
    # TODO: Add UNIQUE (user_id, question_hash) constraint to UserQuestionHistory for deduplication
    return AskResponse(answer=answer, sources=sources)

@app.get("/api/sources", response_model=List[SourceItem])
def get_sources():
    return [
        SourceItem(type="quran", name="Kur'an-ı Kerim"),
        SourceItem(type="hadis", name="Buhari"),
        SourceItem(type="hadis", name="Müslim"),
        SourceItem(type="hadis", name="Tirmizî"),
    ]

# Session yönetimi endpoint'leri
@app.post("/api/chat/session", response_model=SessionResponse)
async def create_or_get_session(request: SessionRequest, current_user: User = Depends(get_current_user_optional)):
    async with AsyncSessionLocal() as session:
        # Sequence onarımını güvence altına al (chat_sessions.id)
        try:
            await _ensure_sequence(session, "chat_sessions", "id")
            print("[RT-SEQ-FIX] chat_sessions.id sequence kontrol/onarım tamamlandı")
        except Exception:
            print("[RT-SEQ-FIX] chat_sessions.id sequence kontrol/onarım atlandı")
        if request.session_token:
            # Mevcut session'ı bul
            result = await session.execute(
                select(ChatSession).options(selectinload(ChatSession.messages))
                .where(ChatSession.session_token == request.session_token)
            )
            chat_session = result.scalar_one_or_none()
            if chat_session:
                messages = [
                    {
                        "type": msg.message_type,
                        "content": msg.content,
                        "sources": json.loads(msg.sources) if msg.sources else [],
                        "created_at": msg.created_at.isoformat()
                    }
                    for msg in sorted(chat_session.messages, key=lambda x: x.created_at)
                ]
                return SessionResponse(session_token=chat_session.session_token, messages=messages)
        
        # Yeni session oluştur
        session_token = str(uuid.uuid4())
        new_session = ChatSession(
            user_id=current_user.id if current_user else None,
            session_token=session_token
        )
        session.add(new_session)
        await session.commit()
        return SessionResponse(session_token=session_token, messages=[])

@app.get("/api/chat/session/{session_token}/messages")
async def get_session_messages(session_token: str, current_user: User = Depends(get_current_user_optional)):
    async with AsyncSessionLocal() as session:
        # Session'ı bul
        result = await session.execute(
            select(ChatSession).options(selectinload(ChatSession.messages))
            .where(ChatSession.session_token == session_token)
        )
        chat_session = result.scalar_one_or_none()
        
        if not chat_session:
            raise HTTPException(status_code=404, detail="Session bulunamadı")
        
        # Mesajları döndür
        messages = [
            {
                "type": msg.message_type,
                "content": msg.content,
                "sources": json.loads(msg.sources) if msg.sources else [],
                "created_at": msg.created_at.isoformat()
            }
            for msg in sorted(chat_session.messages, key=lambda x: x.created_at)
        ]
        
        return {"messages": messages}

@app.post("/api/chat", response_model=ChatResponse)
async def chat_with_session(request: ChatRequest, current_user: User = Depends(get_current_user_optional)):
    # Session token yoksa yeni oluştur
    if not request.session_token:
        request.session_token = str(uuid.uuid4())
    
    # Mevcut ask_ai fonksiyonunu kullan
    ask_request = AskRequest(question=request.question, source_filter=request.source_filter)
    
    # Kullanıcı varsa normal ask_ai'yi çağır, yoksa session tabanlı işlem yap
    if current_user:
        response = await ask_ai(ask_request, current_user)
    else:
        # Anonim kullanıcı için Ultimate RAG + akıllı fallback
        # Tek kelime veya çok kısa sorularda yönlendir
        if len([w for w in request.question.strip().split() if w]) < 2:
            answer = "Sorunuzu daha açık yazar mısınız?"
            sources = []
            response = AskResponse(answer=answer, sources=sources)
        else:
            hadith_dicts = await search_hadiths_ultimate(request.question, top_k=3)
            answer, used_fallback, response_type = generate_ai_response_with_fallback(
                request.question,
                hadith_dicts,
                True
            )
            # Hadis bulunamadığında ayardan okunabilir bir fallback mesajı göster
            if not hadith_dicts:
                answer = await get_setting(
                    'ai_no_hadith_message',
                    'Bu konuda güvenilir hadis kaynağı bulunamadı. Lütfen sorunuzu farklı şekilde ifade edin.'
                )
            # Kaynakları hazırla (UI için sade gösterim)
            sources = []
            for h in hadith_dicts:
                base = f"{h['full_reference']} - {h['text'][:60]}" if h.get('full_reference') else f"{h.get('source','')} - {h.get('reference','')}"
                score = h.get('score')
                display = f"{base} (skor: {score:.2f})" if isinstance(score, (int, float)) and score is not None else base
                sources.append(SourceItem(type="hadis", name=display))
            # Sistem promptu ile aynı cevapları engelle
            system_prompt = (
                "Sen, İslami App'in yapay zeka asistanısın. "
                "Sadece Kur'an, Kütüb-i Sitte ve muteber fıkıh kaynaklarından cevap ver. "
                "Her cevabın sonunda kaynak belirt. Kişisel yorum ekleme. "
                "Soruyu anlamazsan kullanıcıdan daha açık sormasını iste."
            )
            answer_lower = answer.lower()
            if len(request.question.strip().split()) < 2 or answer.lower().startswith(system_prompt[:80].lower()):
                answer = "Sorunuzu daha açık yazar mısınız?"
                sources = []
            response = AskResponse(answer=answer, sources=sources)
    
    # Mesajı DB’ye kaydet
    async with AsyncSessionLocal() as session:
        try:
            await _ensure_sequence(session, "chat_messages", "id")
            print("[RT-SEQ-FIX] chat_messages.id sequence kontrol/onarım tamamlandı")
        except Exception:
            print("[RT-SEQ-FIX] chat_messages.id sequence kontrol/onarım atlandı")
        msg_user = ChatMessage(
            session_token=request.session_token,
            message_type='user',
            content=request.question,
            sources=None
        )
        session.add(msg_user)
        await session.commit()
        
        # Asistan cevabını üret
        ask_request = AskRequest(question=request.question, source_filter=request.source_filter)
        ask_response = await ask_ai(ask_request, current_user)
        msg_assistant = ChatMessage(
            session_token=request.session_token,
            message_type='assistant',
            content=ask_response.answer,
            sources=json.dumps([s.dict() for s in ask_response.sources])
        )
        session.add(msg_assistant)
        await session.commit()
    
    return ChatResponse(answer=ask_response.answer, sources=ask_response.sources, session_token=request.session_token)

# Hadis araması (vektör arama)
@app.get("/api/hadith_search")
async def hadith_search(q: str = Query(..., description="Aranacak metin"), top_k: int = 3) -> Any:
    results = await search_hadiths(q, top_k=top_k)
    return [
        {
            "id": h.id,
            "text": getattr(h, 'turkish_text', None) or getattr(h, 'english_text', None) or getattr(h, 'arabic_text', None) or getattr(h, 'text', ''),
            "source": h.source,
            "reference": h.reference,
            "category": h.category,
            "language": h.language
        }
        for h in results
    ]

# Kullanıcı geçmişi ve favorileri
@app.get("/user/history")
async def get_user_history(
    user_id: int = None,
    search: str = None,
    category: str = None,
    source: str = None,
    date_from: str = None,
    date_to: str = None,
    sort_by: str = "created_at",
    order: str = "desc",
    current_user: User = Depends(get_current_user_optional)
):
    async with AsyncSessionLocal() as session:
        query = select(UserQuestionHistory)
        if current_user:
            user_id = current_user.id
        if user_id:
            query = query.where(UserQuestionHistory.user_id == user_id)
        if search:
            query = query.where(UserQuestionHistory.question.ilike(f"%{search}%"))
        if category:
            query = query.where(UserQuestionHistory.answer.ilike(f"%{category}%"))
        if source:
            query = query.where(UserQuestionHistory.answer.ilike(f"%{source}%"))
        if date_from:
            try:
                df = datetime.fromisoformat(date_from)
                query = query.where(UserQuestionHistory.created_at >= df)
            except Exception:
                pass
        if date_to:
            try:
                dt = datetime.fromisoformat(date_to)
                query = query.where(UserQuestionHistory.created_at <= dt)
            except Exception:
                pass
        if sort_by not in {"created_at", "id"}:
            sort_by = "created_at"
        order_desc = order.lower() == "desc"
        query = query.order_by(getattr(UserQuestionHistory, sort_by).desc() if order_desc else getattr(UserQuestionHistory, sort_by).asc())
        result = await session.execute(query)
        items = result.scalars().all()
        return [
            {
                "id": i.id,
                "question": i.question,
                "answer": shorten(i.answer or "", width=200),
                "created_at": i.created_at.isoformat(),
                "hadith_id": i.hadith_id,
            }
            for i in items
        ]

@app.get("/user/favorites")
async def get_user_favorites(
    user_id: int = None,
    search: str = None,
    category: str = None,
    source: str = None,
    sort_by: str = "id",
    order: str = "desc",
    current_user: User = Depends(get_current_user_optional)
):
    async with AsyncSessionLocal() as session:
        query = select(UserFavoriteHadith)
        if current_user:
            user_id = current_user.id
        if user_id:
            query = query.where(UserFavoriteHadith.user_id == user_id)
        if search:
            query = query.where(UserFavoriteHadith.hadith_text.ilike(f"%{search}%"))
        if category:
            query = query.where(UserFavoriteHadith.category.ilike(f"%{category}%"))
        if source:
            query = query.where(UserFavoriteHadith.source.ilike(f"%{source}%"))
        if sort_by not in {"id", "created_at"}:
            sort_by = "id"
        order_desc = order.lower() == "desc"
        query = query.order_by(getattr(UserFavoriteHadith, sort_by).desc() if order_desc else getattr(UserFavoriteHadith, sort_by).asc())
        result = await session.execute(query)
        items = result.scalars().all()
        return [
            {
                "id": i.id,
                "hadith_text": shorten(i.hadith_text or "", width=200),
                "source": i.source,
                "reference": i.reference,
                "category": i.category,
                "created_at": i.created_at.isoformat(),
            }
            for i in items
        ]

@app.post("/user/favorites")
async def add_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        hadith_res = await session.execute(select(Hadith).where(Hadith.id == hadith_id))
        hadith = hadith_res.scalar_one_or_none()
        if not hadith:
            raise HTTPException(status_code=404, detail="Hadis bulunamadı")
        fav = UserFavoriteHadith(
            user_id=current_user.id,
            hadith_id=hadith_id,
            hadith_text=getattr(hadith, 'turkish_text', None) or getattr(hadith, 'english_text', None) or getattr(hadith, 'arabic_text', None) or getattr(hadith, 'text', ''),
            source=hadith.source,
            reference=hadith.reference,
            category=hadith.category,
        )
        session.add(fav)
        await session.commit()
        return {"status": "ok", "favorite_id": fav.id}

@app.delete("/user/favorites")
async def remove_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(UserFavoriteHadith).where(UserFavoriteHadith.hadith_id == hadith_id, UserFavoriteHadith.user_id == current_user.id))
        fav = res.scalar_one_or_none()
        if not fav:
            raise HTTPException(status_code=404, detail="Favori bulunamadı")
        await session.delete(fav)
        await session.commit()
        return {"status": "ok"}

class DeleteManyFavoritesRequest(BaseModel):
    hadith_ids: List[int]

class DeleteManyHistoryRequest(BaseModel):
    history_ids: List[int]

@app.post("/user/favorites/delete_many")
async def delete_many_favorites(req: DeleteManyFavoritesRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(UserFavoriteHadith).where(UserFavoriteHadith.user_id == current_user.id, UserFavoriteHadith.hadith_id.in_(req.hadith_ids)))
        items = res.scalars().all()
        for i in items:
            await session.delete(i)
        await session.commit()
        return {"status": "ok", "deleted": len(items)}

@app.post("/user/history/delete_many")
async def delete_many_history(req: DeleteManyHistoryRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(UserQuestionHistory).where(UserQuestionHistory.user_id == current_user.id, UserQuestionHistory.id.in_(req.history_ids)))
        items = res.scalars().all()
        for i in items:
            await session.delete(i)
        await session.commit()
        return {"status": "ok", "deleted": len(items)}

@app.get("/user/recommendations")
async def get_user_recommendations(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        # Basit öneri: kullanıcı geçmişine göre en çok geçen kategoriler ve kaynaklar
        res = await session.execute(select(UserQuestionHistory).where(UserQuestionHistory.user_id == current_user.id))
        items = res.scalars().all()
        categories = Counter()
        sources_cnt = Counter()
        for i in items:
            if i.answer:
                # Kategori/soru içinden kaba çıkarım
                for word in ["namaz", "oruç", "zekat", "hac", "dua", "ahlak", "inanç"]:
                    if word in (i.answer or "").lower():
                        categories[word] += 1
                for src in ["buhari", "müslim", "tirmizi", "nesai", "ibn mace", "eda"]:
                    if src in (i.answer or "").lower():
                        sources_cnt[src] += 1
        top_cats = [c for c, _ in categories.most_common(5)]
        top_srcs = [s for s, _ in sources_cnt.most_common(5)]
        return {
            "top_categories": top_cats,
            "top_sources": top_srcs,
            "message": "Öneriler geçmişinize göre hazırlanmıştır."
        }

@app.post("/user/activate_premium")
async def activate_premium(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(User).where(User.id == current_user.id))
        me = res.scalar_one_or_none()
        if not me:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        me.is_premium = True
        await session.commit()
        return {"status": "ok", "message": "Premium hesabınız aktif edildi."}

async def get_setting(key: str, default=None):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Setting).where(Setting.key == key))
        setting = res.scalar_one_or_none()
        return setting.value if setting else default

@app.get("/admin/settings")
async def list_settings(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Setting))
        items = res.scalars().all()
        return [{"key": i.key, "value": i.value} for i in items]

class SettingUpdateRequest(BaseModel):
    key: str
    value: str

@app.post("/admin/settings")
async def update_setting(req: SettingUpdateRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Setting).where(Setting.key == req.key))
        setting = res.scalar_one_or_none()
        if setting:
            setting.value = req.value
        else:
            setting = Setting(key=req.key, value=req.value)
            session.add(setting)
        await session.commit()
        return {"status": "ok"}

@app.get("/admin/users")
async def list_users(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(User))
        users = res.scalars().all()
        return [{"id": u.id, "email": u.email, "is_premium": u.is_premium} for u in users]

class UserUpdateRequest(BaseModel):
    id: int
    email: Optional[EmailStr] = None
    is_premium: Optional[bool] = None
    avatar: Optional[str] = None

@app.post("/admin/users")
async def update_user(req: UserUpdateRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(User).where(User.id == req.id))
        user = res.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        if req.email is not None:
            user.email = req.email
        if req.is_premium is not None:
            user.is_premium = req.is_premium
        if req.avatar is not None:
            user.avatar = req.avatar
        await session.commit()
        return {"status": "ok"}

@app.post("/user/upload_avatar")
async def upload_avatar(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    try:
        contents = await file.read()
        # UUID ile benzersiz dosya adı
        filename = f"{uuid.uuid4()}.png"
        path = os.path.join(_avatars_dir, filename)
        # Pillow varsa resmi güvenli şekilde kaydet
        if PIL_AVAILABLE:
            try:
                from io import BytesIO
                img = Image.open(BytesIO(contents)).convert('RGBA')
                img.save(path, format='PNG')
            except Exception:
                # Pillow hata verirse düz yaz
                with open(path, 'wb') as f:
                    f.write(contents)
        else:
            with open(path, 'wb') as f:
                f.write(contents)
        # Kullanıcı avatarını güncelle
        async with AsyncSessionLocal() as session:
            res = await session.execute(select(User).where(User.id == current_user.id))
            user = res.scalar_one_or_none()
            if not user:
                raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
            user.avatar = f"/static/avatars/{filename}"
            await session.commit()
        return {"status": "ok", "avatar_url": f"/static/avatars/{filename}"}
    except Exception as e:
        logging.exception("Avatar yükleme hatası")
        raise HTTPException(status_code=500, detail="Avatar yüklenemedi")

@app.post("/admin/hadith/upload_csv")
async def upload_hadith_csv(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    try:
        contents = await file.read()
        import io
        buf = io.StringIO(contents.decode('utf-8'))
        reader = csv.DictReader(buf)
        async with AsyncSessionLocal() as session:
            for row in reader:
                h = Hadith(
                    source=row.get('source'),
                    reference=row.get('reference'),
                    category=row.get('category'),
                    language=row.get('language', 'tr'),
                    turkish_text=row.get('turkish_text'),
                    english_text=row.get('english_text'),
                    arabic_text=row.get('arabic_text'),
                    text=row.get('text'),
                )
                session.add(h)
            await session.commit()
        return {"status": "ok"}
    except Exception as e:
        logging.exception("CSV yükleme hatası")
        raise HTTPException(status_code=500, detail="CSV yüklenemedi")

@app.post("/admin/hadith/upload_json")
async def upload_hadith_json(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    try:
        contents = await file.read()
        data = json.loads(contents.decode('utf-8'))
        async with AsyncSessionLocal() as session:
            for item in data:
                h = Hadith(
                    source=item.get('source'),
                    reference=item.get('reference'),
                    category=item.get('category'),
                    language=item.get('language', 'tr'),
                    turkish_text=item.get('turkish_text'),
                    english_text=item.get('english_text'),
                    arabic_text=item.get('arabic_text'),
                    text=item.get('text'),
                )
                session.add(h)
            await session.commit()
        return {"status": "ok"}
    except Exception as e:
        logging.exception("JSON yükleme hatası")
        raise HTTPException(status_code=500, detail="JSON yüklenemedi")

@app.post("/admin/hadith/update_embeddings")
async def update_embeddings(current_user: User = Depends(get_current_user)):
    try:
        # Burada embedding güncelleme işlemleri yapılır (örnek)
        return {"status": "ok", "message": "Embeddings güncellendi"}
    except Exception as e:
        logging.exception("Embedding güncelleme hatası")
        raise HTTPException(status_code=500, detail="Embeddings güncellenemedi")

# --- İlim Yolculukları (Journey) ---
@app.get("/journey/modules")
async def get_journey_modules():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(JourneyModule))
        modules = res.scalars().all()
        return [{"id": m.id, "title": m.title, "description": m.description, "icon": m.icon} for m in modules]

@app.get("/journey/module/{module_id}/steps")
async def get_journey_steps(module_id: int):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(JourneyStep).where(JourneyStep.module_id == module_id))
        steps = res.scalars().all()
        return [{"id": s.id, "title": s.title, "content": s.content, "order": s.order} for s in steps]

@app.post("/journey/progress")
async def update_journey_progress(module_id: int, step_id: int, progress: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        # Basit ilerleme kaydı
        jp = UserJourneyProgress(user_id=current_user.id, module_id=module_id, step_id=step_id, progress=progress)
        session.add(jp)
        await session.commit()
        return {"status": "ok"}

# --- Kur'an ve İslami içerikler ---
SURAH_ID_TO_NAME = {
    1: "Al-Fatiha", 2: "Al-Baqarah", 3: "Aal-E-Imran", 4: "An-Nisa", 5: "Al-Maidah",
    6: "Al-An'am", 7: "Al-A'raf", 8: "Al-Anfal", 9: "At-Tawbah", 10: "Yunus",
    11: "Hud", 12: "Yusuf", 13: "Ar-Ra'd", 14: "Ibrahim", 15: "Al-Hijr",
    16: "An-Nahl", 17: "Al-Isra", 18: "Al-Kahf", 19: "Maryam", 20: "Ta-Ha",
    21: "Al-Anbiya", 22: "Al-Hajj", 23: "Al-Mu'minun", 24: "An-Nur", 25: "Al-Furqan",
    26: "Ash-Shu'ara", 27: "An-Naml", 28: "Al-Qasas", 29: "Al-Ankabut", 30: "Ar-Rum",
    31: "Luqman", 32: "As-Sajda", 33: "Al-Ahzab", 34: "Saba", 35: "Fatir",
    36: "Yasin", 37: "As-Saffat", 38: "Sad", 39: "Az-Zumar", 40: "Ghafir",
    41: "Fussilat", 42: "Ash-Shura", 43: "Az-Zukhruf", 44: "Ad-Dukhan", 45: "Al-Jathiya",
    46: "Al-Ahqaf", 47: "Muhammad", 48: "Al-Fath", 49: "Al-Hujurat", 50: "Qaf",
    51: "Adh-Dhariyat", 52: "At-Tur", 53: "An-Najm", 54: "Al-Qamar", 55: "Ar-Rahman",
    56: "Al-Waqi'ah", 57: "Al-Hadid", 58: "Al-Mujadila", 59: "Al-Hashr", 60: "Al-Mumtahanah",
    61: "As-Saff", 62: "Al-Jumu'ah", 63: "Al-Munafiqun", 64: "At-Taghabun", 65: "At-Talaq",
    66: "At-Tahrim", 67: "Al-Mulk", 68: "Al-Qalam", 69: "Al-Haqqah", 70: "Al-Ma'arij",
    71: "Nuh", 72: "Al-Jinn", 73: "Al-Muzzammil", 74: "Al-Muddathir", 75: "Al-Qiyamah",
    76: "Al-Insan", 77: "Al-Mursalat", 78: "An-Naba", 79: "An-Nazi'at", 80: "Abasa",
    81: "At-Takwir", 82: "Al-Infitar", 83: "Al-Mutaffifin", 84: "Al-Inshiqaq", 85: "Al-Burooj",
    86: "At-Tariq", 87: "Al-Ala", 88: "Al-Ghashiya", 89: "Al-Fajr", 90: "Al-Balad",
    91: "Ash-Shams", 92: "Al-Lail", 93: "Ad-Duha", 94: "Ash-Sharh", 95: "At-Tin",
    96: "Al-Alaq", 97: "Al-Qadr", 98: "Al-Bayyina", 99: "Az-Zalzalah", 100: "Al-Adiyat",
    101: "Al-Qaria", 102: "At-Takathur", 103: "Al-Asr", 104: "Al-Humazah", 105: "Al-Fil",
    106: "Quraish", 107: "Al-Ma'un", 108: "Al-Kawthar", 109: "Al-Kafiroon", 110: "An-Nasr",
    111: "Al-Masad", 112: "Al-Ikhlas", 113: "Al-Falaq", 114: "An-Nas"
}

@app.get('/api/quran')
async def get_quran(surah: str = None, ayah: int = None, language: str = 'tr', q: str = None, reciter: str = None):
    async with AsyncSessionLocal() as session:
        query = select(QuranVerse)
        if surah:
            try:
                surah_num = int(surah)
                surah_name = SURAH_ID_TO_NAME.get(surah_num)
                if surah_name:
                    query = query.where(or_(QuranVerse.surah == surah_name, QuranVerse.surah == str(surah_num)))
                else:
                    query = query.where(or_(QuranVerse.surah == str(surah_num)))
            except ValueError:
                query = query.where(QuranVerse.surah == surah)
        if ayah is not None:
            query = query.where(QuranVerse.ayah == ayah)
        if language:
            query = query.where(QuranVerse.language == language)
        if q:
            like = f"%{q}%"
            query = query.where(QuranVerse.text.ilike(like))
        res = await session.execute(query)
        verses = res.scalars().all()
        def build_audio(v):
            if not reciter:
                return None
            return f"https://cdn.quran.audio/{reciter}/{v.surah}/{v.ayah}.mp3"
        return [
            {
                "surah": v.surah,
                "ayah": v.ayah,
                "text": v.text,
                "language": v.language,
                "audio_url": build_audio(v)
            }
            for v in verses
        ]

@app.get('/api/dua')
async def get_dua(category: str = None, language: str = 'tr', q: str = None):
    async with AsyncSessionLocal() as session:
        query = select(Dua)
        if category:
            query = query.where(Dua.category == category)
        if language:
            query = query.where(Dua.language == language)
        if q:
            like = f"%{q}%"
            query = query.where(Dua.text.ilike(like))
        res = await session.execute(query)
        items = res.scalars().all()
        return [{"id": d.id, "text": d.text, "category": d.category, "language": d.language} for d in items]

@app.get('/api/zikr')
async def get_zikr(category: str = None, language: str = 'tr', q: str = None):
    async with AsyncSessionLocal() as session:
        query = select(Zikr)
        if category:
            query = query.where(Zikr.category == category)
        if language:
            query = query.where(Zikr.language == language)
        if q:
            like = f"%{q}%"
            query = query.where(Zikr.text.ilike(like))
        res = await session.execute(query)
        items = res.scalars().all()
        return [{"id": z.id, "text": z.text, "category": z.category, "language": z.language} for z in items]

@app.get('/api/tefsir')
async def get_tefsir(surah: str = None, ayah: int = None, author: str = None, language: str = 'tr', q: str = None):
    async with AsyncSessionLocal() as session:
        query = select(Tafsir)
        if surah:
            try:
                surah_num = int(surah)
                surah_name = SURAH_ID_TO_NAME.get(surah_num)
                if surah_name:
                    query = query.where(or_(Tafsir.surah == surah_name, Tafsir.surah == str(surah_num)))
                else:
                    query = query.where(or_(Tafsir.surah == str(surah_num)))
            except ValueError:
                query = query.where(Tafsir.surah == surah)
        if ayah is not None:
            query = query.where(Tafsir.ayah == ayah)
        if author:
            query = query.where(Tafsir.author == author)
        if language:
            query = query.where(Tafsir.language == language)
        if q:
            like = f"%{q}%"
            query = query.where(Tafsir.text.ilike(like))
        res = await session.execute(query)
        items = res.scalars().all()
        return [
            {
                "surah": t.surah,
                "ayah": t.ayah,
                "author": t.author,
                "language": t.language,
                "text": t.text,
            }
            for t in items
        ]

@app.get('/api/reciters')
async def get_reciters():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Reciter))
        items = res.scalars().all()
        return [
            {
                "id": r.id,
                "name": r.name,
                "style": r.style,
                "country": r.country,
            }
            for r in items
        ]

@app.get('/api/daily_ayah')
async def get_daily_ayah(language: str = 'tr'):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(QuranVerse).order_by(text('random()')).limit(1))
        verse = res.scalars().first()
        if not verse:
            raise HTTPException(status_code=404, detail="Ayah bulunamadı")
        return {
            "surah": verse.surah,
            "ayah": verse.ayah,
            "text": verse.text,
            "language": verse.language,
        }

@app.get('/api/daily_hadith')
async def get_daily_hadith(language: str = 'tr'):
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Hadith).order_by(text('random()')).limit(1))
        h = res.scalars().first()
        if not h:
            raise HTTPException(status_code=404, detail="Hadis bulunamadı")
        text_val = (
            getattr(h, 'turkish_text', None)
            or getattr(h, 'english_text', None)
            or getattr(h, 'arabic_text', None)
            or getattr(h, 'text', '')
        )
        return {
            "id": h.id,
            "text": text_val,
            "source": h.source,
            "reference": h.reference,
            "category": h.category,
            "language": h.language,
        }

@app.get('/user/profile')
async def get_user_profile(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "is_premium": current_user.is_premium,
        "avatar": getattr(current_user, 'avatar', None),
    }

def safe_json_field(val):
    try:
        return json.loads(val)
    except Exception:
        return val

def _google_api_key() -> str:
    return os.getenv('GOOGLE_API_KEY', '')

@app.get("/api/mosques/nearby")
def nearby_mosques(lat: float = Query(...), lng: float = Query(...), radius: float = Query(3.0, description="km cinsinden")):
    key = _google_api_key()
    if not key:
        raise HTTPException(status_code=500, detail="Google API anahtarı tanımlı değil")
    url = (
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        f"location={lat},{lng}&radius={int(radius*1000)}&type=mosque&key={key}"
    )
    try:
        resp = requests.get(url, timeout=10)
        data = resp.json()
        results = data.get('results', [])
        mosques = []
        for r in results:
            name = r.get('name')
            vicinity = r.get('vicinity')
            loc = r.get('geometry', {}).get('location', {})
            mlat = loc.get('lat')
            mlng = loc.get('lng')
            mosques.append({"name": name, "vicinity": vicinity, "lat": mlat, "lng": mlng})
        return {"mosques": mosques}
    except Exception as e:
        logging.exception("Yakın camiler API hatası")
        raise HTTPException(status_code=500, detail="Yakın camiler alınamadı")
