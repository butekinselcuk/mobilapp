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
origins = [
    "http://localhost:8091",      
    "http://localhost:3000",      
    "http://127.0.0.1:8091",      
    "https://islami-app-backend.onrender.com", 
    # "https://your-frontend-domain.com",  # varsa ekle
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,   # Bearer Token olduğundan False kalmalı
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(auth_router, prefix="/auth")

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

            # Gelişmiş kaynaklar kutusu mantığı (ask_ai ile uyumlu)
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

            response = AskResponse(answer=answer, sources=sources)
    # Session'a mesajları kaydet
    async with AsyncSessionLocal() as session:
        # Session'ı bul veya oluştur
        result = await session.execute(
            select(ChatSession).where(ChatSession.session_token == request.session_token)
        )
        chat_session = result.scalar_one_or_none()
        
        if not chat_session:
            # Varsayılan autoincrement ile oluştur
            chat_session = ChatSession(
                user_id=current_user.id if current_user else None,
                session_token=request.session_token
            )
            session.add(chat_session)
            await session.commit()
            await session.refresh(chat_session)
        
        # Kullanıcı mesajını kaydet (DB autoincrement kullan)
        user_message = ChatMessage(
            session_id=chat_session.id,
            message_type="user",
            content=request.question
        )
        session.add(user_message)
        
        # AI cevabını kaydet (DB autoincrement kullan)
        ai_message = ChatMessage(
            session_id=chat_session.id,
            message_type="assistant",
            content=response.answer,
            sources=json.dumps([{"type": s.type, "name": s.name} for s in response.sources])
        )
        session.add(ai_message)
        await session.commit()
    
    return ChatResponse(
        answer=response.answer,
        sources=response.sources,
        session_token=request.session_token
    )

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

# NOT: Gerçek ortamda JWT ile kimlik doğrulama zorunlu olmalı. Demo için user_id parametresiyle ilerleniyor.

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
    resolved_user_id = user_id or (current_user.id if current_user else None)
    if not resolved_user_id:
        raise HTTPException(status_code=401, detail="Kullanıcı kimliği bulunamadı")
    async with AsyncSessionLocal() as session:
        q = select(UserQuestionHistory).where(UserQuestionHistory.user_id == resolved_user_id)
        if search:
            q = q.where(or_(UserQuestionHistory.question.ilike(f"%{search}%"), UserQuestionHistory.answer.ilike(f"%{search}%")))
        if category:
            q = q.where(UserQuestionHistory.answer.ilike(f"%{category}%"))
        if source:
            q = q.where(UserQuestionHistory.answer.ilike(f"%{source}%"))
            
        if date_from:
            q = q.where(UserQuestionHistory.created_at >= date_from)
        if date_to:
            q = q.where(UserQuestionHistory.created_at <= date_to)
        # Sıralama
        sort_col = getattr(UserQuestionHistory, sort_by, UserQuestionHistory.created_at)
        if order == "asc":
            q = q.order_by(sort_col.asc())
        else:
            q = q.order_by(sort_col.desc())
        result = await session.execute(q)
        history = result.scalars().all()
        return [
            {
                "id": h.id,  # id alanı eklendi
                "question": h.question,
                "answer": h.answer,
                "created_at": h.created_at,
                "hadith_id": h.hadith_id,
            } for h in history
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
    resolved_user_id = user_id or (current_user.id if current_user else None)
    if not resolved_user_id:
        raise HTTPException(status_code=401, detail="Kullanıcı kimliği bulunamadı")
    async with AsyncSessionLocal() as session:
        q = select(UserFavoriteHadith).options(selectinload(UserFavoriteHadith.hadith)).where(UserFavoriteHadith.user_id == resolved_user_id)
        if search:
            # Güvenli arama: mevcut sütunlara göre dinamik koşullar oluştur
            conditions = []
            for col in ["turkish_text", "english_text", "arabic_text", "text", "source", "reference"]:
                if hasattr(Hadith, col):
                    conditions.append(
                        UserFavoriteHadith.hadith.has(getattr(Hadith, col).ilike(f"%{search}%"))
                    )
            if conditions:
                q = q.where(or_(*conditions))
        if category:
            q = q.where(UserFavoriteHadith.hadith.has(Hadith.category.ilike(f"%{category}%")))
        if source:
            q = q.where(UserFavoriteHadith.hadith.has(Hadith.source.ilike(f"%{source}%")))
        sort_col = getattr(UserFavoriteHadith, sort_by, UserFavoriteHadith.id)
        if order == "asc":
            q = q.order_by(sort_col.asc())
        else:
            q = q.order_by(sort_col.desc())
        result = await session.execute(q)
        favs = result.scalars().all()
        return [
            {
                "id": f.hadith.id,
                "text": f.hadith.turkish_text or f.hadith.arabic_text,
                "source": f.hadith.source,
                "reference": f.hadith.reference,
                "category": f.hadith.category,
                "language": f.hadith.language
            } for f in favs if f.hadith
        ]

@app.post("/user/favorites")
async def add_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        # Önce var mı kontrol et
        result = await session.execute(
            select(UserFavoriteHadith).where(
                UserFavoriteHadith.user_id == current_user.id,
                UserFavoriteHadith.hadith_id == hadith_id
            )
        )
        existing = result.scalar_one_or_none()
        if existing:
            return {"status": "already_exists"}
        fav = UserFavoriteHadith(user_id=current_user.id, hadith_id=hadith_id)
        session.add(fav)
        await session.commit()
        return {"status": "ok"}

@app.delete("/user/favorites")
async def remove_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(UserFavoriteHadith).where(UserFavoriteHadith.user_id == current_user.id, UserFavoriteHadith.hadith_id == hadith_id)
        )
        fav = result.scalar_one_or_none()
        if not fav:
            raise HTTPException(status_code=404, detail="Favori bulunamadı")
        await session.delete(fav)
        await session.commit()
        return {"status": "deleted"}

class DeleteManyFavoritesRequest(BaseModel):
    hadith_ids: List[int]

class DeleteManyHistoryRequest(BaseModel):
    history_ids: List[int]

@app.post("/user/favorites/delete_many")
async def delete_many_favorites(req: DeleteManyFavoritesRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        await session.execute(
            UserFavoriteHadith.__table__.delete().where(
                UserFavoriteHadith.user_id == current_user.id,
                UserFavoriteHadith.hadith_id.in_(req.hadith_ids)
            )
        )
        await session.commit()
        return {"status": "deleted", "count": len(req.hadith_ids)}

@app.post("/user/history/delete_many")
async def delete_many_history(req: DeleteManyHistoryRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        await session.execute(
            UserQuestionHistory.__table__.delete().where(
                UserQuestionHistory.user_id == current_user.id,
                UserQuestionHistory.id.in_(req.history_ids)
            )
        )
        await session.commit()
        return {"status": "deleted", "count": len(req.history_ids)}

@app.get("/user/recommendations")
async def get_user_recommendations(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        # Kullanıcının en çok favorilediği hadisler (top 3)
        user_favs = await session.execute(
            select(UserFavoriteHadith.hadith_id, Hadith.turkish_text, Hadith.arabic_text, Hadith.source, Hadith.reference, Hadith.category, Hadith.language)
            .join(Hadith, UserFavoriteHadith.hadith_id == Hadith.id)
            .where(UserFavoriteHadith.user_id == current_user.id)
        )
        user_fav_list = user_favs.fetchall()
        # En çok tekrar eden ilk 3 hadisi bul
        user_counter = Counter([row.hadith_id for row in user_fav_list])
        user_top_ids = [item[0] for item in user_counter.most_common(3)]
        user_top_hadiths = [dict(
            id=row.hadith_id,
            text=row.turkish_text or row.arabic_text,
            source=row.source,
            reference=row.reference,
            category=row.category,
            language=row.language
        ) for row in user_fav_list if row.hadith_id in user_top_ids]
        # Haftanın hadisi (son 7 gün)
        week_ago = datetime.utcnow() - timedelta(days=7)
        week_favs = await session.execute(
            select(UserFavoriteHadith.hadith_id, Hadith.turkish_text, Hadith.arabic_text, Hadith.source, Hadith.reference, Hadith.category, Hadith.language)
            .join(Hadith, UserFavoriteHadith.hadith_id == Hadith.id)
            .where(UserFavoriteHadith.created_at >= week_ago)
        )
        week_fav_list = week_favs.fetchall()
        week_counter = Counter([row.hadith_id for row in week_fav_list])
        if week_counter:
            week_top_id = week_counter.most_common(1)[0][0]
            week_top = next((dict(
                id=row.hadith_id,
                text=row.turkish_text or row.arabic_text,
                source=row.source,
                reference=row.reference,
                category=row.category,
                language=row.language
            ) for row in week_fav_list if row.hadith_id == week_top_id), None)
        else:
            week_top = None
        return {
            "user_top_hadiths": user_top_hadiths,
            "week_top_hadith": week_top
        } 

@app.post("/user/activate_premium")
async def activate_premium(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        db_user = await session.get(User, current_user.id)
        if not db_user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        db_user.is_premium = True
        db_user.premium_expiry = datetime.utcnow() + timedelta(days=30)
        await session.commit()
        await session.refresh(db_user)
        return {
            "status": "premium_activated",
            "premium_expiry": db_user.premium_expiry.isoformat()
        } 

async def get_setting(key: str, default=None):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting).where(Setting.key == key))
        setting = result.scalar_one_or_none()
        if setting:
            return setting.value
        return default 

@app.get("/admin/settings")
async def list_settings(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting))
        settings = result.scalars().all()
        return [{"key": s.key, "value": s.value} for s in settings]

class SettingUpdateRequest(BaseModel):
    key: str
    value: str

@app.post("/admin/settings")
async def update_setting(req: SettingUpdateRequest, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting).where(Setting.key == req.key))
        setting = result.scalar_one_or_none()
        if setting:
            setting.value = req.value
        else:
            setting = Setting(key=req.key, value=req.value)
            session.add(setting)
        await session.commit()
        return {"key": req.key, "value": req.value} 

class UserUpdateRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class ThemeUpdateRequest(BaseModel):
    theme: Literal["light", "dark"]

@app.patch("/user/update")
async def update_user_profile(req: UserUpdateRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        user = await session.get(User, current_user.id)
        if req.username:
            user.username = req.username
        if req.email:
            user.email = req.email
        await session.commit()
        return {"status": "updated", "username": user.username, "email": user.email}

@app.post("/user/change_password")
async def change_password(req: ChangePasswordRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        user = await session.get(User, current_user.id)
        from auth import verify_password, get_password_hash
        if not verify_password(req.old_password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Mevcut şifre yanlış.")
        # Şifre karmaşıklık doğrulaması
        npw = req.new_password or ""
        if not (
            len(npw) >= 8 and
            re.search(r"[A-Z]", npw) and
            re.search(r"[a-z]", npw) and
            re.search(r"\d", npw) and
            re.search(r"[^A-Za-z0-9]", npw)
        ):
            raise HTTPException(status_code=400, detail="Yeni şifre karmaşıklık kurallarını sağlamıyor.")
        user.hashed_password = get_password_hash(req.new_password)
        await session.commit()
        return {"status": "password_changed"}

@app.post("/user/theme")
async def update_theme(req: ThemeUpdateRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        user = await session.get(User, current_user.id)
        user.theme_preference = req.theme
        await session.commit()
        return {"status": "updated", "theme_preference": user.theme_preference}

@app.post("/user/avatar")
async def upload_avatar(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    # İçerik türü ve boyut doğrulama
    if file.content_type not in ("image/jpeg", "image/png"):
        raise HTTPException(status_code=400, detail="Sadece JPEG/PNG desteklenir.")
    data = await file.read()
    max_bytes = 2 * 1024 * 1024
    if len(data) > max_bytes:
        raise HTTPException(status_code=400, detail="Dosya boyutu 2MB limitini aşıyor.")

    # Dosya adı ve uzantı belirleme
    ext = "jpg" if file.content_type == "image/jpeg" else "png"
    fname = f"{uuid.uuid4().hex}.{ext}"
    fpath = os.path.join(_avatars_dir, fname)

    # 500x500 center-crop ve kaydetme (Pillow varsa)
    try:
        if PIL_AVAILABLE:
            from io import BytesIO
            buf = BytesIO(data)
            img = Image.open(buf)
            img = img.convert("RGB")
            w, h = img.size
            # Kare kırpma (merkez)
            side = min(w, h)
            left = (w - side) // 2
            top = (h - side) // 2
            img = img.crop((left, top, left + side, top + side))
            img = img.resize((500, 500))
            img.save(fpath, format="JPEG", quality=90)
        else:
            # Pillow yoksa raw veriyi doğrudan yaz (boyut doğrulaması zaten yapıldı)
            with open(fpath, "wb") as f:
                f.write(data)
    except Exception:
        raise HTTPException(status_code=500, detail="Avatar işleme sırasında hata oluştu.")

    url = f"/static/avatars/{fname}"
    async with AsyncSessionLocal() as session:
        user = await session.get(User, current_user.id)
        user.avatar_url = url
        await session.commit()
        return {"status": "uploaded", "avatar_url": url}

@app.delete("/user/delete")
async def delete_account(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        user = await session.get(User, current_user.id)
        await session.delete(user)
        await session.commit()
        return {"status": "deleted"} 

@app.post("/admin/upload_hadiths")
async def upload_hadiths(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    import json
    import sys
    import traceback
    import csv
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    content_bytes = await file.read()
    name = (file.filename or '').lower()
    content_type = getattr(file, 'content_type', '') or ''

    # JSON dosyasıysa esnek bir şekilde parse et
    if name.endswith('.json') or 'json' in content_type:
        try:
            text = content_bytes.decode('utf-8', errors='ignore')
            data = json.loads(text)
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"JSON okunamadı: {e}")

        # Liste ya da {'items': [...]} formatlarını destekle
        if isinstance(data, dict) and isinstance(data.get('items'), list):
            items = data['items']
        elif isinstance(data, list):
            items = data
        else:
            raise HTTPException(status_code=400, detail="Geçersiz JSON formatı. Liste veya 'items' alanı bekleniyor.")

        skipped = []
        eklenen = 0
        async with AsyncSessionLocal() as session:
            for idx, item in enumerate(items, 1):
                try:
                    turkish_text = item.get('turkish_text') or item.get('text_tr') or item.get('text') or item.get('tr_text')
                    source = item.get('source') or item.get('book_name') or item.get('kitap') or item.get('collection')
                    if not turkish_text or not source:
                        print(f"ATLANIYOR (satır {idx}): Eksik zorunlu alan! turkish_text={turkish_text}, source={source}")
                        skipped.append({"row": idx, "reason": "Eksik zorunlu alan (turkish_text/text veya source)"})
                        continue

                    # Opsiyonel alanları esnek eşle
                    reference = item.get('reference')
                    # Bazı datasetlerde numaraları birleştirelim
                    if not reference:
                        parts = []
                        for key in ['hadith_number', 'hadis_no', 'bab']:
                            val = item.get(key)
                            if val:
                                parts.append(str(val))
                        reference = ', '.join(parts) if parts else None
                    category = item.get('category') or item.get('kategori')
                    language = item.get('language') or 'tr'

                    hadith = Hadith(
                        arabic_text=item.get('arabic_text') or item.get('text_ar') or None,
                        turkish_text=turkish_text,
                        source=source,
                        reference=reference,
                        category=category,
                        language=language,
                    )
                    session.add(hadith)
                    eklenen += 1
                except Exception as e:
                    print(f"ATLANIYOR (satır {idx}): HATA: {e}\n{traceback.format_exc()}")
                    skipped.append({"row": idx, "reason": str(e)})
            await session.commit()
        print(f'JSON yükleme tamamlandı. Eklenen: {eklenen}, Atlanan: {len(skipped)}')
        return {"status": "ok", "added": eklenen, "skipped": len(skipped), "skipped_details": skipped}

    # Aksi halde CSV olarak devam et
    decoded_lines = content_bytes.decode('utf-8', errors='ignore').splitlines()
    reader = csv.DictReader(decoded_lines)
    new_hadiths = []
    skipped = []
    eklenen = 0
    atlanan = 0
    async with AsyncSessionLocal() as session:
        for idx, row in enumerate(reader, 1):
            try:
                turkish_text = row.get('turkish_text') or row.get('text')
                if not turkish_text or not row.get('source'):
                    print(f"ATLANIYOR (satır {idx}): Eksik zorunlu alan! hadis_id={row.get('hadis_id')}, turkish_text={turkish_text}, source={row.get('source')}")
                    skipped.append({"row": idx, "reason": "Eksik zorunlu alan (turkish_text/text veya source)"})
                    atlanan += 1
                    continue
                from datetime import datetime
                def force_json_str(val):
                    import json
                    if val is None or val == '' or val == []:
                        return ''
                    if isinstance(val, str):
                        try:
                            loaded = json.loads(val)
                            if isinstance(loaded, list):
                                return val
                            else:
                                return json.dumps([val], ensure_ascii=False)
                        except Exception:
                            return json.dumps([val], ensure_ascii=False)
                    if isinstance(val, list):
                        return json.dumps(val, ensure_ascii=False)
                    return json.dumps([val], ensure_ascii=False)
                # created_at alanını date nesnesine çevir
                created_at_val = row.get('created_at')
                created_at = None
                if created_at_val:
                    try:
                        created_at = datetime.strptime(created_at_val, '%Y-%m-%d').date()
                    except Exception:
                        created_at = None
                hadith = Hadith(
                    hadis_id=row.get('hadis_id'),
                    kitap=row.get('kitap'),
                    bab=row.get('bab'),
                    hadis_no=row.get('hadis_no'),
                    arabic_text=row.get('arabic_text'),
                    turkish_text=turkish_text,
                    tags=force_json_str(row.get('tags')),
                    topic=row.get('topic'),
                    authenticity=row.get('authenticity'),
                    narrator_chain=force_json_str(row.get('narrator_chain')),
                    related_ayah=force_json_str(row.get('related_ayah')),
                    context=row.get('context'),
                    source=row.get('source'),
                    reference=row.get('reference'),
                    category=row.get('category'),
                    language=row.get('language'),
                    embedding=row.get('embedding'),
                    created_at=created_at,
                )
                session.add(hadith)
                new_hadiths.append(hadith)
                print(f"EKLENİYOR (satır {idx}): hadis_id={row.get('hadis_id')}, turkish_text={str(turkish_text)[:30]}")
                eklenen += 1
            except Exception as e:
                print(f"ATLANIYOR (satır {idx}): HATA: {e}\n{traceback.format_exc()}")
                skipped.append({"row": idx, "reason": str(e)})
                atlanan += 1
        await session.commit()
    print(f'CSV yükleme tamamlandı. Eklenen: {eklenen}, Atlanan: {atlanan}')
    return {"status": "ok", "added": len(new_hadiths), "skipped": len(skipped), "skipped_details": skipped}

@app.post("/admin/update_embeddings")
async def update_embeddings(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    from embedding_utils import update_hadith_embeddings
    try:
        updated_count = await update_hadith_embeddings()
        logging.info(f"Embedding güncelleme tamamlandı: {updated_count} kayıt güncellendi")
        return {"status": "ok", "updated_count": updated_count}
    except Exception as e:
        logging.exception("Admin embedding güncelleme HATASI")
        raise HTTPException(status_code=500, detail="Embedding güncelleme hatası")

@app.get("/admin/embedding_status")
async def embedding_status(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    from sqlalchemy import func
    async with AsyncSessionLocal() as session:
        total = (await session.execute(select(func.count(Hadith.id)))).scalar_one()
        with_emb = (await session.execute(select(func.count(Hadith.id)).where(Hadith.embedding.isnot(None)))).scalar_one()
        without_emb = total - with_emb
        return {
            "total_hadiths": total,
            "with_embedding": with_emb,
            "without_embedding": without_emb,
        }

@app.post("/admin/import_tr_json")
async def admin_import_tr_json(current_user: User = Depends(get_current_user)):
    """hadiths_tr.json dosyasını veritabanına import eder."""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    try:
        backend_dir = os.path.abspath(os.path.dirname(__file__))
        tr_path = os.path.join(backend_dir, "hadiths_tr.json")
        from import_hadiths import import_hadiths
        inserted = await import_hadiths(tr_path)
        return {"status": "ok", "inserted": inserted}
    except Exception as e:
        logging.exception("Admin TR JSON import HATASI")
        raise HTTPException(status_code=500, detail="TR JSON import hatası")

@app.post("/admin/import_ar_json")
async def admin_import_ar_json(current_user: User = Depends(get_current_user)):
    """hadiths_ar.json dosyasını mevcut kayıtlarla birleştirir veya ekler."""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    try:
        backend_dir = os.path.abspath(os.path.dirname(__file__))
        ar_path = os.path.join(backend_dir, "hadiths_ar.json")
        if not os.path.exists(ar_path):
            raise HTTPException(status_code=404, detail="AR JSON bulunamadı")
        from import_hadiths import _merge_language_json
        count = await _merge_language_json(ar_path, lang='ar')
        return {"status": "ok", "processed": count}
    except HTTPException:
        raise
    except Exception:
        logging.exception("Admin AR JSON import HATASI")
        raise HTTPException(status_code=500, detail="AR JSON import hatası")

@app.post("/admin/import_en_json")
async def admin_import_en_json(current_user: User = Depends(get_current_user)):
    """hadiths_en.json dosyasını mevcut kayıtlarla birleştirir veya ekler."""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    try:
        backend_dir = os.path.abspath(os.path.dirname(__file__))
        en_path = os.path.join(backend_dir, "hadiths_en.json")
        if not os.path.exists(en_path):
            raise HTTPException(status_code=404, detail="EN JSON bulunamadı")
        from import_hadiths import _merge_language_json
        count = await _merge_language_json(en_path, lang='en')
        return {"status": "ok", "processed": count}
    except HTTPException:
        raise
    except Exception:
        logging.exception("Admin EN JSON import HATASI")
        raise HTTPException(status_code=500, detail="EN JSON import hatası")

@app.post("/admin/import_all_json")
async def admin_import_all_json(current_user: User = Depends(get_current_user)):
    """TR + AR + EN JSON’ları sırayla içeri alır ve birleştirir."""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    try:
        backend_dir = os.path.abspath(os.path.dirname(__file__))
        tr_path = os.path.join(backend_dir, "hadiths_tr.json")
        ar_path = os.path.join(backend_dir, "hadiths_ar.json")
        en_path = os.path.join(backend_dir, "hadiths_en.json")
        from import_hadiths import import_hadiths_all
        processed = await import_hadiths_all(tr_path, ar_path=ar_path, en_path=en_path)
        return {"status": "ok", "processed": processed}
    except Exception:
        logging.exception("Admin ALL JSON import HATASI")
        raise HTTPException(status_code=500, detail="ALL JSON import hatası")

@app.get("/admin/users")
async def list_users(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User))
        users = result.scalars().all()
        return [
            {"id": u.id, "username": u.username, "email": u.email, "is_admin": u.is_admin, "is_premium": u.is_premium}
            for u in users
        ]

@app.delete("/admin/user/delete")
async def delete_user(user_id: int, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    async with AsyncSessionLocal() as session:
        user = await session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        await session.delete(user)
        await session.commit()
        return {"status": "deleted"}

@app.post("/admin/user/premium")
async def make_user_premium(user_id: int, action: str = "activate", days: int = 30, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Yetkisiz erişim")
    async with AsyncSessionLocal() as session:
        user = await session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        if action == "activate":
            user.is_premium = True
            from datetime import datetime, timedelta
            user.premium_expiry = datetime.utcnow() + timedelta(days=days)
            await session.commit()
            return {"status": "premium_activated", "premium_expiry": user.premium_expiry.isoformat()}
        elif action == "deactivate":
            user.is_premium = False
            user.premium_expiry = None
            await session.commit()
            return {"status": "premium_deactivated"}
        else:
            raise HTTPException(status_code=400, detail="Geçersiz action") 

# --- İlim Yolculukları (Journey) Admin Endpointleri ---
from pydantic import BaseModel

class JourneyModuleCreate(BaseModel):
    title: str
    description: str = ''
    icon: str = ''
    category: str = ''
    tags: str = ''

class JourneyStepCreate(BaseModel):
    module_id: int
    title: str
    order: int
    content: str = ''
    media_url: str = ''
    media_type: str = ''
    source: str = ''

class StepReorderItem(BaseModel):
    id: int
    order: int

class StepReorderRequest(BaseModel):
    module_id: int
    steps: List[StepReorderItem]

class JourneyModuleUpdate(BaseModel):
    id: int
    title: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    category: Optional[str] = None
    tags: Optional[str] = None

class JourneyStepUpdate(BaseModel):
    id: int
    title: Optional[str] = None
    order: Optional[int] = None
    content: Optional[str] = None
    media_url: Optional[str] = None
    media_type: Optional[str] = None
    source: Optional[str] = None

@app.get('/admin/journey_modules')
async def list_journey_modules(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(JourneyModule).options(selectinload(JourneyModule.steps)))
        modules = result.scalars().all()
        return [
            {
                'id': m.id,
                'title': m.title,
                'description': m.description,
                'icon': m.icon,
                'category': m.category,
                'tags': m.tags,
                'steps': [
                    {
                        'id': s.id,
                        'title': s.title,
                        'order': s.order,
                        'content': s.content,
                        'media_url': s.media_url,
                        'media_type': s.media_type,
                        'source': s.source,
                    }
                    for s in sorted(m.steps, key=lambda x: x.order)
                ]
            } for m in modules
        ]

@app.post('/admin/journey_module')
async def add_journey_module(req: JourneyModuleCreate, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        module = JourneyModule(title=req.title, description=req.description, icon=req.icon, category=req.category, tags=req.tags)
        session.add(module)
        await session.commit()
        await session.refresh(module)
        return {'id': module.id, 'title': module.title, 'category': module.category, 'tags': module.tags}

@app.post('/admin/journey_step')
async def add_journey_step(req: JourneyStepCreate, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        step = JourneyStep(
            module_id=req.module_id,
            title=req.title,
            order=req.order,
            content=req.content,
            media_url=req.media_url,
            media_type=req.media_type,
            source=req.source,
        )
        session.add(step)
        await session.commit()
        await session.refresh(step)
        return {'id': step.id, 'title': step.title}

@app.post('/admin/journey_step/reorder')
async def reorder_journey_steps(req: StepReorderRequest, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        for step in req.steps:
            db_step = await session.get(JourneyStep, step.id)
            if db_step and db_step.module_id == req.module_id:
                db_step.order = step.order
        await session.commit()
    return {'status': 'ok'}

@app.patch('/admin/journey_module/update')
async def update_journey_module(req: JourneyModuleUpdate, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        module = await session.get(JourneyModule, req.id)
        if not module:
            raise HTTPException(status_code=404, detail='Modül bulunamadı')
        if req.title is not None:
            module.title = req.title
        if req.description is not None:
            module.description = req.description
        if req.icon is not None:
            module.icon = req.icon
        if req.category is not None:
            module.category = req.category
        if req.tags is not None:
            module.tags = req.tags
        await session.commit()
        await session.refresh(module)
        return {
            'id': module.id,
            'title': module.title,
            'description': module.description,
            'icon': module.icon,
            'category': module.category,
            'tags': module.tags,
        }

@app.patch('/admin/journey_step/update')
async def update_journey_step(req: JourneyStepUpdate, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        step = await session.get(JourneyStep, req.id)
        if not step:
            raise HTTPException(status_code=404, detail='Adım bulunamadı')
        if req.title is not None:
            step.title = req.title
        if req.order is not None:
            step.order = req.order
        if req.content is not None:
            step.content = req.content
        if req.media_url is not None:
            step.media_url = req.media_url
        if req.media_type is not None:
            step.media_type = req.media_type
        if req.source is not None:
            step.source = req.source
        await session.commit()
        await session.refresh(step)
        return {
            'id': step.id,
            'title': step.title,
            'order': step.order,
            'content': step.content,
            'media_url': step.media_url,
            'media_type': step.media_type,
            'source': step.source,
        }

@app.delete('/admin/journey_module')
async def delete_journey_module(module_id: int, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        module = await session.get(JourneyModule, module_id)
        if not module:
            raise HTTPException(status_code=404, detail='Modül bulunamadı')
        await session.delete(module)
        await session.commit()
        return {'status': 'deleted'}

@app.delete('/admin/journey_step')
async def delete_journey_step(step_id: int, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    async with AsyncSessionLocal() as session:
        step = await session.get(JourneyStep, step_id)
        if not step:
            raise HTTPException(status_code=404, detail='Adım bulunamadı')
        await session.delete(step)
        await session.commit()
        return {'status': 'deleted'}

# --- Kullanıcı Journey Progress Endpointleri ---
class JourneyProgressUpdate(BaseModel):
    module_id: int
    completed_step: int

@app.get('/user/journey_progress')
async def get_journey_progress(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(UserJourneyProgress).where(UserJourneyProgress.user_id == current_user.id))
        progresses = result.scalars().all()
        return [
            {'module_id': p.module_id, 'completed_step': p.completed_step, 'completed_at': p.completed_at}
            for p in progresses
        ]

@app.post('/user/journey_progress')
async def update_journey_progress(req: JourneyProgressUpdate, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(UserJourneyProgress).where((UserJourneyProgress.user_id == current_user.id) & (UserJourneyProgress.module_id == req.module_id)))
        progress = result.scalar_one_or_none()
        if progress:
            progress.completed_step = req.completed_step
        else:
            progress = UserJourneyProgress(user_id=current_user.id, module_id=req.module_id, completed_step=req.completed_step)
            session.add(progress)
        await session.commit()
        return {'module_id': req.module_id, 'completed_step': req.completed_step} 

@app.get('/api/journey_modules')
async def public_journey_modules(tags: list[str] = Query(None)):
    print(f"[DEBUG] Gelen tags parametresi: {tags}")
    async with AsyncSessionLocal() as session:
        q = select(JourneyModule).options(selectinload(JourneyModule.steps))
        if tags:
            for tag in tags:
                norm_tag = tag.strip().lower()
                # REGEXP ile tam eşleşme (PostgreSQL)
                try:
                    q = q.where(JourneyModule.tags.op('~')(f',({norm_tag}),'))
                except Exception:
                    # Eğer REGEXP desteklenmiyorsa ilike ile başında ve sonunda virgül arayarak
                    q = q.where(JourneyModule.tags.ilike(f'%,{norm_tag},%'))
        print(f"[DEBUG] SQL sorgusu: {q}")
        result = await session.execute(q)
        modules = result.scalars().all()
        return [
            {
                'id': m.id,
                'title': m.title,
                'description': m.description,
                'icon': m.icon,
                'category': m.category,
                'tags': m.tags,
                'steps': [
                    {
                        'id': s.id,
                        'title': s.title,
                        'order': s.order,
                        'content': s.content,
                        'media_url': s.media_url,
                        'media_type': s.media_type,
                        'source': s.source,
                    } for s in m.steps
                ]
            } for m in modules
        ] 

@app.post('/admin/upload_journey_csv')
async def upload_journey_csv(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail='Yetkisiz erişim')
    content = await file.read()
    decoded = content.decode('utf-8').splitlines()
    reader = csv.DictReader(decoded)
    async with AsyncSessionLocal() as session:
        module_map = {}  # (title, description) -> module obj
        for row in reader:
            module_id = row.get('module_id')
            module_title = row.get('module_title', '').strip()
            module_desc = row.get('module_description', '').strip()
            if module_id:
                module = await session.get(JourneyModule, int(module_id))
            else:
                module = None
            if not module and module_title:
                # Aynı başlık ve açıklama ile modül var mı?
                q = await session.execute(select(JourneyModule).where(JourneyModule.title == module_title))
                module = q.scalars().first()
                if not module:
                    module = JourneyModule(title=module_title, description=module_desc, icon='explore')
                    session.add(module)
                    await session.flush()
            if not module:
                continue  # modül yoksa adım eklenemez
            step = JourneyStep(
                module_id=module.id,
                title=row.get('step_title', '').strip(),
                order=int(row.get('step_order', '1')),
                content=row.get('step_content', '').strip(),
                media_url=row.get('media_url', '').strip(),
                media_type=row.get('media_type', '').strip(),
                source=row.get('source', '').strip(),
            )
            session.add(step)
        await session.commit()
    return {'status': 'ok'} 

# Surah numarasını İngilizce sure adına çeviren mapping
SURAH_ID_TO_NAME = {
    1: "Al-Faatiha",
    2: "Al-Baqara",
    3: "Aal-i-Imraan",
    4: "An-Nisaa",
    5: "Al-Maida",
    6: "Al-An'aam",
    7: "Al-A'raaf",
    8: "Al-Anfaal",
    9: "At-Tawba",
    10: "Yunus",
    11: "Hud",
    12: "Yusuf",
    13: "Ar-Ra'd",
    14: "Ibrahim",
    15: "Al-Hijr",
    16: "An-Nahl",
    17: "Al-Israa",
    18: "Al-Kahf",
    19: "Maryam",
    20: "Ta-Ha",
    21: "Al-Anbiya",
    22: "Al-Hajj",
    23: "Al-Mu'minoon",
    24: "An-Noor",
    25: "Al-Furqan",
    26: "Ash-Shu'ara",
    27: "An-Naml",
    28: "Al-Qasas",
    29: "Al-Ankaboot",
    30: "Ar-Rum",
    31: "Luqman",
    32: "As-Sajda",
    33: "Al-Ahzaab",
    34: "Saba",
    35: "Faatir",
    36: "Yaseen",
    37: "As-Saaffaat",
    38: "Saad",
    39: "Az-Zumar",
    40: "Ghafir",
    41: "Fussilat",
    42: "Ash-Shura",
    43: "Az-Zukhruf",
    44: "Ad-Dukhaan",
    45: "Al-Jaathiya",
    46: "Al-Ahqaf",
    47: "Muhammad",
    48: "Al-Fath",
    49: "Al-Hujuraat",
    50: "Qaaf",
    51: "Adh-Dhaariyat",
    52: "At-Tur",
    53: "An-Najm",
    54: "Al-Qamar",
    55: "Ar-Rahman",
    56: "Al-Waqia",
    57: "Al-Hadid",
    58: "Al-Mujadila",
    59: "Al-Hashr",
    60: "Al-Mumtahina",
    61: "As-Saff",
    62: "Al-Jumua",
    63: "Al-Munafiqoon",
    64: "At-Taghabun",
    65: "At-Talaq",
    66: "At-Tahrim",
    67: "Al-Mulk",
    68: "Al-Qalam",
    69: "Al-Haaqqa",
    70: "Al-Maarij",
    71: "Nuh",
    72: "Al-Jinn",
    73: "Al-Muzzammil",
    74: "Al-Muddathir",
    75: "Al-Qiyama",
    76: "Al-Insan",
    77: "Al-Mursalat",
    78: "An-Naba",
    79: "An-Nazi'at",
    80: "Abasa",
    81: "At-Takwir",
    82: "Al-Infitar",
    83: "Al-Mutaffifin",
    84: "Al-Inshiqaq",
    85: "Al-Burooj",
    86: "At-Tariq",
    87: "Al-Ala",
    88: "Al-Ghashiya",
    89: "Al-Fajr",
    90: "Al-Balad",
    91: "Ash-Shams",
    92: "Al-Lail",
    93: "Ad-Duha",
    94: "Ash-Sharh",
    95: "At-Tin",
    96: "Al-Alaq",
    97: "Al-Qadr",
    98: "Al-Bayyina",
    99: "Az-Zalzalah",
    100: "Al-Adiyat",
    101: "Al-Qaria",
    102: "At-Takathur",
    103: "Al-Asr",
    104: "Al-Humazah",
    105: "Al-Fil",
    106: "Quraish",
    107: "Al-Ma'un",
    108: "Al-Kawthar",
    109: "Al-Kafiroon",
    110: "An-Nasr",
    111: "Al-Masad",
    112: "Al-Ikhlas",
    113: "Al-Falaq",
    114: "An-Nas"
}

@app.get('/api/quran')
async def get_quran(surah: str = None, ayah: int = None, language: str = 'tr', q: str = None, reciter: str = None):
    async with AsyncSessionLocal() as session:
        surah_param = surah
        if surah and surah.isdigit():
            surah_param = SURAH_ID_TO_NAME.get(int(surah))
        query = select(QuranVerse)
        if surah_param:
            query = query.where(QuranVerse.surah == surah_param)
        if ayah:
            query = query.where(QuranVerse.ayah == ayah)
        if language:
            query = query.where(QuranVerse.language == language)
        if q:
            query = query.where(QuranVerse.text.ilike(f'%{q}%'))
        result = await session.execute(query)
        verses = result.scalars().all()
        import re

        def build_audio_url(v, reciter_code: str | None):
            if not reciter_code:
                return None
            # Varsayılan: DB’deki audio_url’den global ayet numarasını çıkar, yoksa ayah_number’a düş.
            global_num = None
            if getattr(v, 'audio_url', None):
                m = re.search(r"/(\d+)\.mp3$", v.audio_url)
                if m:
                    try:
                        global_num = int(m.group(1))
                    except Exception:
                        global_num = None
            verse_num = global_num or getattr(v, 'ayah_number', None) or getattr(v, 'ayah', None)
            if not verse_num:
                return None
            return f'https://cdn.islamic.network/quran/audio/128/{reciter_code}/{verse_num}.mp3'

        # Eğer DB’de veri yoksa, ilgili sureyi dış API’den getirerek zarif ve non-blocking bir fallback uygula.
        if not verses and (surah or q or ayah):
            try:
                import httpx
                # Surah ID’yi bul
                surah_id = None
                if surah and surah.isdigit():
                    surah_id = int(surah)
                elif surah_param:
                    # isimden ID’ye ters map
                    for sid, sname in SURAH_ID_TO_NAME.items():
                        if sname.lower() == str(surah_param).lower():
                            surah_id = sid
                            break
                if not surah_id:
                    # Surah verilmemişse veya çözülemediyse, kısa bir sure ile örnek döndür (İhlas)
                    surah_id = 112

                ayahs_ar: list = []
                data_ar: dict = {}
                ayahs_tr_map: dict[int, str] = {}

                async with httpx.AsyncClient(timeout=15) as client:
                    # Arapça metin ve ses
                    base_url_ar = f'https://api.alquran.cloud/v1/surah/{surah_id}/ar.alafasy'
                    try:
                        r_ar = await client.get(base_url_ar)
                        if r_ar.status_code == 200:
                            data_ar = r_ar.json().get('data', {})
                            ayahs_ar = data_ar.get('ayahs', []) or []
                        else:
                            ayahs_ar = []
                    except Exception as e:
                        print('[quran fallback] AR fetch hatası:', str(e))
                        ayahs_ar = []

                    # İstenen dil Türkçe ise meal eklemeyi dene
                    if (language or '').lower().startswith('tr'):
                        base_url_tr = f'https://api.alquran.cloud/v1/surah/{surah_id}/tr.yildirim'
                        try:
                            r_tr = await client.get(base_url_tr)
                            if r_tr.status_code == 200:
                                data_tr = r_tr.json().get('data', {})
                                for a in data_tr.get('ayahs', []) or []:
                                    try:
                                        ayahs_tr_map[int(a.get('numberInSurah', 0))] = a.get('text')
                                    except Exception:
                                        pass
                        except Exception as e:
                            print('[quran fallback] TR fetch hatası:', str(e))

                # Fallback sonucu
                fallback = []
                surah_name_from_api = data_ar.get('englishName') or data_ar.get('name')
                for a in ayahs_ar:
                    try:
                        num_in_surah = int(a.get('numberInSurah', 0))
                    except Exception:
                        num_in_surah = a.get('numberInSurah') or a.get('ayah_number') or a.get('ayah') or None
                    text_ar = a.get('text')
                    audio_url = a.get('audio')
                    tr_text = ayahs_tr_map.get(num_in_surah)
                    item = {
                        'id': None,
                        'surah': surah_name_from_api,
                        'ayah': num_in_surah,
                        'text': text_ar,
                        'translation': tr_text,
                        'language': (language or 'tr'),
                        'surah_id': surah_id,
                        'surah_name': surah_name_from_api,
                        'ayah_number': num_in_surah,
                        'text_ar': text_ar,
                        'text_tr': tr_text,
                        'audio_url': audio_url,
                    }
                    # Reciter istendiyse global numaraya göre ses URL’sini üret
                    if reciter:
                        try:
                            # alquran.cloud yanıtındaki 'number' global ayet numarasıdır
                            global_num = int(a.get('number')) if a.get('number') else None
                        except Exception:
                            global_num = None
                        if global_num:
                            item['audio_url'] = f'https://cdn.islamic.network/quran/audio/128/{reciter}/{global_num}.mp3'
                    fallback.append(item)

                # İsteğe bağlı: küçük bir cache olarak DB’ye yaz (yalnızca boşken ve bir sure istenmişse)
                try:
                    if fallback and surah_id:
                        async with AsyncSessionLocal() as s2:
                            for it in fallback:
                                s2.add(QuranVerse(
                                    surah=it['surah_name'] or it['surah'] or str(surah_id),
                                    ayah=it['ayah'],
                                    text=it['text_ar'] or it['text'],
                                    translation=it['text_tr'],
                                    language=it['language'],
                                    surah_id=surah_id,
                                    surah_name=it['surah_name'] or it['surah'],
                                    ayah_number=it['ayah'],
                                    text_ar=it['text_ar'],
                                    text_tr=it['text_tr'],
                                    audio_url=it['audio_url'],
                                ))
                            await s2.commit()
                except Exception as e:
                    print('[quran seed fallback] yazma hatası:', str(e))
                return fallback
            except Exception as e:
                print('[quran fallback] exception:', str(e))
                # Sessizce boş dön, istemci tarafı kullanıcıya uygun mesaj gösterebilir
                return []

        return [
            {
                'id': v.id,
                'surah': v.surah,
                'ayah': v.ayah,
                'text': v.text,
                'translation': v.translation,
                'language': v.language,
                'surah_id': v.surah_id,
                'surah_name': v.surah_name,
                'ayah_number': v.ayah_number,
                'text_ar': v.text_ar,
                'text_tr': v.text_tr,
                # Eğer reciter verilmişse doğru global ayet numarasını kullanarak URL üret, aksi halde DB’deki mevcut URL’yi bırak.
                'audio_url': build_audio_url(v, reciter) if reciter else (v.audio_url or None)
            } for v in verses
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
            query = query.where(Dua.text.ilike(f'%{q}%'))
        result = await session.execute(query)
        duas = result.scalars().all()
        return [
            {
                'id': d.id,
                'title': d.title,
                'text': d.text,
                'translation': d.translation,
                'category': d.category,
                'language': d.language
            } for d in duas
        ]

@app.get('/api/zikr')
async def get_zikr(category: str = None, language: str = 'tr', q: str = None):
    async with AsyncSessionLocal() as session:
        query = select(Zikr)
        if category:
            query = query.where(Zikr.category == category)
        if language:
            query = query.where(Zikr.language == language)
        if q:
            query = query.where(Zikr.text.ilike(f'%{q}%'))
        result = await session.execute(query)
        zikrs = result.scalars().all()
        return [
            {
                'id': z.id,
                'title': z.title,
                'text': z.text,
                'translation': z.translation,
                'count': z.count,
                'category': z.category,
                'language': z.language
            } for z in zikrs
        ]

@app.get('/api/tefsir')
async def get_tefsir(surah: str = None, ayah: int = None, author: str = None, language: str = 'tr', q: str = None):
    async with AsyncSessionLocal() as session:
        query = select(Tafsir)
        if surah:
            query = query.where(Tafsir.surah == surah)
        if ayah:
            query = query.where(Tafsir.ayah == ayah)
        if author:
            query = query.where(Tafsir.author == author)
        if language:
            query = query.where(Tafsir.language == language)
        if q:
            query = query.where(Tafsir.text.ilike(f'%{q}%'))
        result = await session.execute(query)
        tafsirs = result.scalars().all()
        return [
            {
                'id': t.id,
                'surah': t.surah,
                'ayah': t.ayah,
                'text': t.text,
                'author': t.author,
                'language': t.language
            } for t in tafsirs
        ] 

@app.get('/api/reciters')
async def get_reciters():
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(models.Reciter))
        reciters = result.scalars().all()
        return [
            {
                'id': r.id,
                'name': r.name,
                'description': r.description
            } for r in reciters
        ] 

# Günün Ayeti (SQL’den deterministik seçim)
@app.get('/api/daily_ayah')
async def get_daily_ayah(language: str = 'tr'):
    from sqlalchemy import func
    from datetime import datetime
    async with AsyncSessionLocal() as session:
        # Toplam ayet sayısı (dil filtresiyle)
        count_res = await session.execute(
            select(func.count()).where(QuranVerse.language == language)
        )
        total = count_res.scalar() or 0
        if total == 0:
            return { 'text': '', 'reference': '' }
        # Yılın günü ile deterministik index
        day_idx = datetime.utcnow().timetuple().tm_yday % total
        verse_res = await session.execute(
            select(QuranVerse)
            .where(QuranVerse.language == language)
            .order_by(QuranVerse.id)
            .offset(day_idx)
            .limit(1)
        )
        v = verse_res.scalars().first()
        if not v:
            return { 'text': '', 'reference': '' }
        return {
            'text': getattr(v, 'text', None) or getattr(v, 'text_tr', None) or '',
            'reference': f"{getattr(v, 'surah', '')} {getattr(v, 'ayah', '')}"
        }

# Günün Hadisi (SQL’den deterministik seçim)
@app.get('/api/daily_hadith')
async def get_daily_hadith(language: str = 'tr'):
    from sqlalchemy import func
    from datetime import datetime
    async with AsyncSessionLocal() as session:
        count_res = await session.execute(
            select(func.count()).where(Hadith.language == language)
        )
        total = count_res.scalar() or 0
        if total == 0:
            return { 'text': '', 'reference': '' }
        day_idx = datetime.utcnow().timetuple().tm_yday % total
        hadith_res = await session.execute(
            select(Hadith)
            .where(Hadith.language == language)
            .order_by(Hadith.id)
            .offset(day_idx)
            .limit(1)
        )
        h = hadith_res.scalars().first()
        if not h:
            return { 'text': '', 'reference': '' }
        # Hadis metni alan önceliği
        text_val = (
            getattr(h, 'turkish_text', None)
            or getattr(h, 'text_tr', None)
            or getattr(h, 'text', None)
            or getattr(h, 'english_text', None)
            or getattr(h, 'arabic_text', None)
            or ''
        )
        ref = (
            f"{getattr(h, 'source', '')} {getattr(h, 'reference', '')}"
        ).strip()
        return {
            'text': text_val,
            'reference': ref,
        }

@app.get('/user/profile')
async def get_user_profile(current_user: User = Depends(get_current_user)):
    return {
        "username": current_user.username,
        "email": current_user.email,
        "is_admin": current_user.is_admin,
        "isPremium": current_user.is_premium,
        "premium_expiry": current_user.premium_expiry.isoformat() if current_user.premium_expiry else None,
        "theme_preference": current_user.theme_preference or "light",
        "avatar_url": current_user.avatar_url or None,
    }


def safe_json_field(val):
    if val is None or val == "" or val == []:
        return ""
    if isinstance(val, list):
        return json.dumps(val, ensure_ascii=False)
    return str(val)
# -------------------------
# Yakın Camiler & Rota API
# -------------------------

def _google_api_key() -> str:
    key = os.getenv("GOOGLE_MAPS_API_KEY") or os.getenv("GOOGLE_API_KEY") or ""
    # Anahtar yoksa artık 500 fırlatmayıp boş döneceğiz; çağıran fonksiyon zarifçe boş liste ile yanıtlar.
    return key

@app.get("/api/mosques/nearby")
def nearby_mosques(lat: float = Query(...), lng: float = Query(...), radius: float = Query(3.0, description="km cinsinden")):
    """Yakındaki camileri döndürür.
    Öncelik Google Places; API anahtarı yoksa veya hata alınırsa Overpass (OSM) fallback kullanılır.
    """
    def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat/2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2) ** 2
        c = 2 * atan2(a ** 0.5, (1 - a) ** 0.5)
        return R * c

    radius_m = int(max(0.1, radius) * 1000)
    api_key = _google_api_key()

    # 1) Google Places dene
    if api_key:
        url = (
            f"https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            f"?location={lat},{lng}&radius={radius_m}&type=mosque&key={api_key}"
        )
        try:
            r = requests.get(url, timeout=10)
            if r.status_code == 200:
                data = r.json()
                results = data.get("results", [])
                mosques = []
                for item in results:
                    geom = item.get("geometry", {}).get("location", {})
                    mlat = float(geom.get("lat", 0.0))
                    mlon = float(geom.get("lng", 0.0))
                    mosques.append({
                        "id": item.get("place_id") or item.get("id") or "",
                        "name": item.get("name", "Cami"),
                        "latitude": mlat,
                        "longitude": mlon,
                        "address": item.get("vicinity") or item.get("formatted_address"),
                        "rating": (item.get("rating") or None),
                        "photo_reference": (item.get("photos", [{}])[0].get("photo_reference") if item.get("photos") else None),
                        "distance_km": round(haversine_km(lat, lng, mlat, mlon), 2),
                    })
                return mosques
            else:
                print("[nearby_mosques] Google non-200:", r.status_code, r.text[:200])
        except Exception as e:
            print("[nearby_mosques] Google exception:", str(e))

    # 2) Overpass (OSM) fallback
    try:
        overpass_url = "https://overpass-api.de/api/interpreter"
        # amenity=place_of_worship ve religion=muslim filtreleriyle çevredeki noktaları al
        query = (
            f"[out:json];"
            f"node(around:{radius_m},{lat},{lng})[\"amenity\"=\"place_of_worship\"][\"religion\"=\"muslim\"];"
            f"out center;"
        )
        resp = requests.post(overpass_url, data=query, timeout=20)
        if resp.status_code != 200:
            print("[nearby_mosques] Overpass non-200:", resp.status_code, resp.text[:200])
            return []
        payload = resp.json()
        elements = payload.get("elements", [])
        mosques = []
        for el in elements:
            mlat = float(el.get("lat", el.get("center", {}).get("lat", 0.0)))
            mlon = float(el.get("lon", el.get("center", {}).get("lon", 0.0)))
            name = (el.get("tags", {}) or {}).get("name") or "Cami"
            mosques.append({
                "id": str(el.get("id") or ""),
                "name": name,
                "latitude": mlat,
                "longitude": mlon,
                "address": (el.get("tags", {}) or {}).get("addr:full") or None,
                "rating": None,
                "photo_reference": None,
                "distance_km": round(haversine_km(lat, lng, mlat, mlon), 2),
            })
        return mosques
    except Exception as e:
        print("[nearby_mosques] Overpass exception:", str(e))
        return []

@app.get("/api/mosques/photo")
def mosque_photo(ref: str = Query(..., description="Google Places photo_reference"), maxwidth: int = Query(400)):
    """Google Places Photo için güvenli proxy: API anahtarını istemciye sızdırmadan fotoğrafa yönlendirir."""
    api_key = _google_api_key()
    if not ref:
        raise HTTPException(status_code=400, detail="ref gerekli")
    url = (
        "https://maps.googleapis.com/maps/api/place/photo"
        f"?maxwidth={maxwidth}&photoreference={ref}&key={api_key}"
    )
    return RedirectResponse(url=url)

@app.get("/api/directions")
def directions(origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float, mode: str = "driving"):
    """Google Directions ile rota bilgisini döndürür (sunucu tarafı proxy)."""
    api_key = _google_api_key()
    url = (
        f"https://maps.googleapis.com/maps/api/directions/json"
        f"?origin={origin_lat},{origin_lng}&destination={dest_lat},{dest_lng}&mode={mode}&key={api_key}"
    )
    r = requests.get(url, timeout=10)
    if r.status_code != 200:
        raise HTTPException(status_code=r.status_code, detail=r.text)
    return r.json()

# --- Kıble Yönü ---
def _initial_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """(lat1, lon1) -> (lat2, lon2) için başlangıç açısını (true North'a göre derece) hesaplar."""
    phi1, phi2 = radians(lat1), radians(lat2)
    d_lambda = radians(lon2 - lon1)
    x = sin(d_lambda) * cos(phi2)
    y = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(d_lambda)
    bearing = (degrees(atan2(x, y)) + 360.0) % 360.0
    return bearing

@app.get("/api/qibla_direction")
def qibla_direction(lat: float = Query(...), lng: float = Query(...)):
    """Verilen konumdan Kıble yönü: true North referanslı derece döndürür."""
    kaaba_lat, kaaba_lng = 21.4225, 39.8262
    b = _initial_bearing(lat, lng, kaaba_lat, kaaba_lng)
    return {
        "bearing_deg": round(b, 2),
        "origin": {"lat": lat, "lng": lng},
        "kaaba": {"lat": kaaba_lat, "lng": kaaba_lng},
    }

# --- Namaz Vakitleri Proxy ---
@app.get("/api/prayer_times")
def prayer_times(city: str, country: str = "Turkey", method: int = 2):
    """Aladhan API üzerinden şehir bazlı namaz vakitlerini döndürür.
    Frontend şehir adını gönderir; backend proxy olarak dış API ile konuşur.
    """
    try:
        city_q = urllib.parse.quote(city)
        country_q = urllib.parse.quote(country)
        url = (
            f"https://api.aladhan.com/v1/timingsByCity?city={city_q}&country={country_q}&method={method}"
        )
        r = requests.get(url, timeout=10)
        if r.status_code != 200:
            raise HTTPException(status_code=r.status_code, detail=r.text)
        data = r.json()
        if not isinstance(data, dict) or "data" not in data:
            raise HTTPException(status_code=500, detail="Geçersiz yanıt")
        d = data["data"]
        return {
            "city": city,
            "country": country,
            "date": d.get("date", {}),
            "timings": d.get("timings", {}),
            "meta": d.get("meta", {}),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def _get_sequence_name(session, tbl: str, col: str) -> str:
    # Sequence adını bulur; yoksa oluşturup bağlar ve döner
    seq_res = await session.execute(
        text("SELECT pg_get_serial_sequence(:tbl, :col)").bindparams(tbl=tbl, col=col)
    )
    seq_name = seq_res.scalar()
    if not seq_name:
        default_res = await session.execute(text(
            """
            SELECT column_default
            FROM information_schema.columns
            WHERE table_name = :tbl AND column_name = :col
            """
        ).bindparams(tbl=tbl, col=col))
        column_default = default_res.scalar()
        if column_default and 'nextval' in column_default:
            try:
                start = column_default.find("'")
                end = column_default.find("'", start + 1)
                seq_name = column_default[start+1:end]
            except Exception:
                seq_name = None
    if not seq_name:
        fallback_seq = f"{tbl}_{col}_seq"
        await session.execute(text(f"CREATE SEQUENCE IF NOT EXISTS {fallback_seq}"))
        await session.execute(text(f"ALTER SEQUENCE {fallback_seq} OWNED BY {tbl}.{col}"))
        await session.execute(text(f"ALTER TABLE {tbl} ALTER COLUMN {col} SET DEFAULT nextval('{fallback_seq}'::regclass)"))
        seq_name = fallback_seq
    return seq_name
