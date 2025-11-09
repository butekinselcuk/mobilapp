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
    # Kayıt/Giriş ve web istemcisi için her origin'e izin ver (Render + localhost)
    # allow_credentials False iken '*' güvenlidir ve preflight için header'ları ekler.
    allow_origins=["*"],
    allow_origin_regex=None,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
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
            if not hadith_dicts:
                answer = await get_setting(
                    'ai_no_hadith_message',
                    'Bu konuda güvenilir hadis kaynağı bulunamadı. Lütfen sorunuzu farklı şekilde ifade edin.'
                )
            sources = []
            for h in hadith_dicts or []:
                base = f"{h.get('source','')} - {h.get('reference','')}"
                sources.append(SourceItem(type="hadis", name=base))
            response = AskResponse(answer=answer, sources=sources)
    
    # Mesajı session'a kaydet
    async with AsyncSessionLocal() as session:
        # Sequence onarımını güvence altına al (chat_messages.id)
        try:
            await _ensure_sequence(session, "chat_messages", "id")
            print("[RT-SEQ-FIX] chat_messages.id sequence kontrol/onarım tamamlandı")
        except Exception:
            print("[RT-SEQ-FIX] chat_messages.id sequence kontrol/onarım atlandı")
        # Session'ı al veya oluştur
        result = await session.execute(select(ChatSession).where(ChatSession.session_token == request.session_token))
        chat_session = result.scalar_one_or_none()
        if not chat_session:
            chat_session = ChatSession(session_token=request.session_token, user_id=current_user.id if current_user else None)
            session.add(chat_session)
            await session.commit()
            await session.refresh(chat_session)
        # Mesaj ekle
        sources_json = json.dumps([s.dict() for s in response.sources]) if response.sources else None
        chat_message = ChatMessage(
            session_id=chat_session.id,
            message_type="answer",
            content=response.answer,
            sources=sources_json
        )
        session.add(chat_message)
        await session.commit()
    
    return ChatResponse(answer=response.answer, sources=response.sources, session_token=request.session_token)

@app.get("/api/hadith_search")
async def hadith_search(q: str = Query(..., description="Aranacak metin"), top_k: int = 3) -> Any:
    try:
        results = await search_hadiths(q, top_k=top_k)
        return {
            "results": results,
            "count": len(results)
        }
    except Exception as e:
        logging.exception("Hadis arama hatası")
        raise HTTPException(status_code=500, detail="Arama sırasında bir hata oluştu")

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
        if user_id:
            query = query.where(UserQuestionHistory.user_id == user_id)
        if search:
            query = query.where(UserQuestionHistory.question.ilike(f"%{search}%"))
        if category:
            query = query.where(UserQuestionHistory.category == category)
        if source:
            query = query.where(UserQuestionHistory.source == source)
        if date_from:
            try:
                date_from_dt = datetime.strptime(date_from, "%Y-%m-%d")
                query = query.where(UserQuestionHistory.created_at >= date_from_dt)
            except Exception:
                pass
        if date_to:
            try:
                date_to_dt = datetime.strptime(date_to, "%Y-%m-%d")
                query = query.where(UserQuestionHistory.created_at <= date_to_dt)
            except Exception:
                pass
        if sort_by == "created_at":
            query = query.order_by(UserQuestionHistory.created_at.desc() if order == "desc" else UserQuestionHistory.created_at.asc())
        else:
            query = query.order_by(UserQuestionHistory.id.desc() if order == "desc" else UserQuestionHistory.id.asc())
        result = await session.execute(query)
        items = [
            {
                "id": h.id,
                "question": h.question,
                "answer": h.answer[:120] if h.answer else None,
                "created_at": h.created_at.isoformat(),
            }
            for h in result.scalars().all()
        ]
        return {"items": items, "count": len(items)}

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
        query = select(UserFavoriteHadith).join(Hadith, UserFavoriteHadith.hadith_id == Hadith.id)
        if user_id:
            query = query.where(UserFavoriteHadith.user_id == user_id)
        if search:
            query = query.where(Hadith.text.ilike(f"%{search}%"))
        if category:
            query = query.where(Hadith.source.ilike(f"%{category}%"))
        if source:
            query = query.where(Hadith.reference.ilike(f"%{source}%"))
        if sort_by == "id":
            query = query.order_by(UserFavoriteHadith.id.desc() if order == "desc" else UserFavoriteHadith.id.asc())
        else:
            query = query.order_by(Hadith.text.desc() if order == "desc" else Hadith.text.asc())
        result = await session.execute(query)
        items = [
            {
                "id": fav.id,
                "hadith_id": fav.hadith_id,
                "text": fav.hadith.text[:120] if fav.hadith and fav.hadith.text else None,
                "source": fav.hadith.source if fav.hadith else None,
                "reference": fav.hadith.reference if fav.hadith else None,
            }
            for fav in result.scalars().all()
        ]
        return {"items": items, "count": len(items)}

@app.post("/user/favorites")
async def add_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        fav = UserFavoriteHadith(user_id=current_user.id, hadith_id=hadith_id)
        session.add(fav)
        await session.commit()
        return {"status": "ok"}

@app.delete("/user/favorites")
async def remove_favorite(hadith_id: int, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(UserFavoriteHadith).where(UserFavoriteHadith.user_id == current_user.id, UserFavoriteHadith.hadith_id == hadith_id))
        fav = result.scalar_one_or_none()
        if fav:
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
        await session.execute(text("DELETE FROM user_favorite_hadith WHERE user_id = :uid AND hadith_id = ANY(:ids)").bindparams(uid=current_user.id, ids=req.hadith_ids))
        await session.commit()
        return {"status": "ok"}

@app.post("/user/history/delete_many")
async def delete_many_history(req: DeleteManyHistoryRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        await session.execute(text("DELETE FROM user_question_history WHERE user_id = :uid AND id = ANY(:ids)").bindparams(uid=current_user.id, ids=req.history_ids))
        await session.commit()
        return {"status": "ok"}

@app.get("/user/recommendations")
async def get_user_recommendations(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(UserQuestionHistory).where(UserQuestionHistory.user_id == current_user.id))
        histories = result.scalars().all()
        texts = [h.question for h in histories]
        counter = Counter()
        for t in texts:
            for w in t.split():
                counter[w.lower()] += 1
        common_words = [w for w, c in counter.most_common(5)]
        suggestions = [f"'{w}' hakkında daha fazla bilgi almak ister misiniz?" for w in common_words]
        return {"suggestions": suggestions}

@app.post("/user/activate_premium")
async def activate_premium(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.id == current_user.id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        user.is_premium = True
        await session.commit()
        return {"status": "ok"}

async def get_setting(key: str, default=None):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting).where(Setting.key == key))
        s = result.scalar_one_or_none()
        return s.value if s else default

@app.get("/admin/settings")
async def list_settings(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting))
        items = [
            {
                "key": s.key,
                "value": s.value,
            }
            for s in result.scalars().all()
        ]
        return {"items": items}

class SettingUpdateRequest(BaseModel):
    key: str
    value: str

@app.post("/admin/settings")
async def update_setting(req: SettingUpdateRequest, current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(Setting).where(Setting.key == req.key))
        s = result.scalar_one_or_none()
        if not s:
            s = Setting(key=req.key, value=req.value)
            session.add(s)
        else:
            s.value = req.value
        await session.commit()
        return {"status": "ok"}

# Avatar upload
@app.post("/user/avatar")
async def upload_avatar(file: UploadFile = File(...), current_user: User = Depends(get_current_user)):
    filename = f"{current_user.id}_{uuid.uuid4().hex}.png"
    filepath = os.path.join(_avatars_dir, filename)
    # Dosyayı kaydet
    content = await file.read()
    with open(filepath, "wb") as f:
        f.write(content)
    # Opsiyonel: boyutlandırma
    if PIL_AVAILABLE:
        try:
            img = Image.open(filepath)
            img = img.convert("RGBA") if img.mode != "RGBA" else img
            img.thumbnail((512, 512))
            img.save(filepath)
        except Exception:
            pass
    # Profil güncelle
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.id == current_user.id))
        user = result.scalar_one_or_none()
        if user:
            user.avatar_url = f"/static/avatars/{filename}"
            await session.commit()
    return {"avatar_url": f"/static/avatars/{filename}"}

# Kullanıcıya ait basit profil
@app.get('/user/profile')
async def profile(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.id == current_user.id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        return {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "avatar_url": user.avatar_url,
            "is_premium": user.is_premium,
        }

# Basit yeniden yönlendirme
@app.get("/")
def root_redirect():
    return RedirectResponse(url="/docs")

# Runtime sırasında sequence onarımını güvence altına alan yardımcı
async def _ensure_sequence(session: AsyncSession, table: str, column: str):
    try:
        seq_res = await session.execute(text("SELECT pg_get_serial_sequence(:tbl, :col)").bindparams(tbl=table, col=column))
        seq_name = seq_res.scalar()
        if not seq_name:
            fallback_seq = f"{table}_{column}_seq"
            await session.execute(text(f"CREATE SEQUENCE IF NOT EXISTS {fallback_seq}"))
            await session.execute(text(f"ALTER SEQUENCE {fallback_seq} OWNED BY {table}.{column}"))
            await session.execute(text(f"ALTER TABLE {table} ALTER COLUMN {column} SET DEFAULT nextval('{fallback_seq}'::regclass)"))
            seq_name = fallback_seq
        await session.execute(text("SELECT setval(:seq::regclass, COALESCE((SELECT MAX(" + column + ") FROM " + table + "), 0), TRUE)").bindparams(seq=seq_name))
    except Exception:
        # Sessizce yut, uygulama akışı devam etsin
        pass

QURAN_SURA_NAMES = {
    1: "Al-Fatiha",
    2: "Al-Baqara",
    3: "Al-Imran",
    4: "An-Nisa",
    5: "Al-Ma'idah",
    6: "Al-An'am",
    7: "Al-A'raf",
    8: "Al-Anfal",
    9: "At-Tawbah",
    10: "Yunus",
    11: "Hud",
    12: "Yusuf",
    13: "Ar-Ra'd",
    14: "Ibrahim",
    15: "Al-Hijr",
    16: "An-Nahl",
    17: "Al-Isra",
    18: "Al-Kahf",
    19: "Maryam",
    20: "Ta-Ha",
    21: "Al-Anbiya",
    22: "Al-Hajj",
    23: "Al-Mu'minun",
    24: "An-Nur",
    25: "Al-Furqan",
    26: "Ash-Shu'ara",
    27: "An-Naml",
    28: "Al-Qasas",
    29: "Al-Ankabut",
    30: "Ar-Rum",
    31: "Luqman",
    32: "As-Sajda",
    33: "Al-Ahzab",
    34: "Saba",
    35: "Fatir",
    36: "Ya-Sin",
    37: "As-Saffat",
    38: "Sad",
    39: "Az-Zumar",
    40: "Ghafir",
    41: "Fussilat",
    42: "Ash-Shura",
    43: "Az-Zukhruf",
    44: "Ad-Dukhan",
    45: "Al-Jathiya",
    46: "Al-Ahqaf",
    47: "Muhammad",
    48: "Al-Fath",
    49: "Al-Hujurat",
    50: "Qaf",
    51: "Adh-Dhariyat",
    52: "At-Tur",
    53: "An-Najm",
    54: "Al-Qamar",
    55: "Ar-Rahman",
    56: "Al-Waqi'a",
    57: "Al-Hadid",
    58: "Al-Mujadila",
    59: "Al-Hashr",
    60: "Al-Mumtahina",
    61: "As-Saff",
    62: "Al-Jumu'a",
    63: "Al-Munafiqun",
    64: "At-Taghabun",
    65: "At-Talaq",
    66: "At-Tahrim",
    67: "Al-Mulk",
    68: "Al-Qalam",
    69: "Al-Haqqah",
    70: "Al-Ma'arij",
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
    try:
        async with AsyncSessionLocal() as session:
            query = select(QuranVerse)
            if surah:
                query = query.where(QuranVerse.surah == surah)
            if ayah:
                query = query.where(QuranVerse.ayah == ayah)
            if language:
                query = query.where(QuranVerse.language == language)
            if q:
                query = query.where(QuranVerse.text.ilike(f"%{q}%"))
            result = await session.execute(query)
            verses = result.scalars().all()
            items = [
                {
                    "surah": v.surah,
                    "ayah": v.ayah,
                    "text": v.text,
                    "language": v.language
                }
                for v in verses
            ]
            # Opsiyonel: ses dosyalarını döndür
            if reciter:
                audio_query = select(QuranAudio).where(QuranAudio.reciter == reciter)
                audio_result = await session.execute(audio_query)
                audio_items = [
                    {
                        "surah": a.surah,
                        "ayah": a.ayah,
                        "url": a.url
                    }
                    for a in audio_result.scalars().all()
                ]
                return {"items": items, "audio": audio_items}
            return {"items": items}
    except Exception:
        logging.exception("Kuran ayetleri çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/dua')
async def get_dua(category: str = None, language: str = 'tr', q: str = None):
    try:
        async with AsyncSessionLocal() as session:
            query = select(Dua)
            if category:
                query = query.where(Dua.category == category)
            if language:
                query = query.where(Dua.language == language)
            if q:
                query = query.where(Dua.text.ilike(f"%{q}%"))
            result = await session.execute(query)
            duas = result.scalars().all()
            items = [
                {
                    "category": d.category,
                    "text": d.text,
                    "language": d.language
                }
                for d in duas
            ]
            return {"items": items}
    except Exception:
        logging.exception("Dua çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/zikr')
async def get_zikr(category: str = None, language: str = 'tr', q: str = None):
    try:
        async with AsyncSessionLocal() as session:
            query = select(Zikr)
            if category:
                query = query.where(Zikr.category == category)
            if language:
                query = query.where(Zikr.language == language)
            if q:
                query = query.where(Zikr.text.ilike(f"%{q}%"))
            result = await session.execute(query)
            zikrs = result.scalars().all()
            items = [
                {
                    "category": z.category,
                    "text": z.text,
                    "language": z.language
                }
                for z in zikrs
            ]
            return {"items": items}
    except Exception:
        logging.exception("Zikr çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/tefsir')
async def get_tefsir(surah: str = None, ayah: int = None, author: str = None, language: str = 'tr', q: str = None):
    try:
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
                query = query.where(Tafsir.text.ilike(f"%{q}%"))
            result = await session.execute(query)
            tafsirs = result.scalars().all()
            items = [
                {
                    "author": t.author,
                    "surah": t.surah,
                    "ayah": t.ayah,
                    "text": t.text,
                    "language": t.language
                }
                for t in tafsirs
            ]
            return {"items": items}
    except Exception:
        logging.exception("Tefsir çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/reciters')
async def get_reciters():
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(QuranAudio.reciter).distinct())
            reciters = [r[0] for r in result.all()]
            items = [
                {
                    "name": r,
                }
                for r in reciters
            ]
            return {"items": items}
    except Exception:
        logging.exception("Kıraatçılar çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/daily_ayah')
async def get_daily_ayah(language: str = 'tr'):
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(QuranVerse).order_by(QuranVerse.created_at.desc()))
            verse = result.scalars().first()
            if not verse:
                return JSONResponse(status_code=404, content={"detail": "Ayet bulunamadı"})
            return {
                "surah": verse.surah,
                "ayah": verse.ayah,
                "text": verse.text,
                "language": verse.language
            }
    except Exception:
        logging.exception("Günlük ayet çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/api/daily_hadith')
async def get_daily_hadith(language: str = 'tr'):
    try:
        async with AsyncSessionLocal() as session:
            result = await session.execute(select(Hadith).order_by(Hadith.id.desc()))
            hadith = result.scalars().first()
            if not hadith:
                return JSONResponse(status_code=404, content={"detail": "Hadis bulunamadı"})
            return {
                "text": hadith.text,
                "source": hadith.source,
                "reference": hadith.reference,
                "language": hadith.language
            }
    except Exception:
        logging.exception("Günlük hadis çekme hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")

@app.get('/user/profile')
async def get_user_profile(current_user: User = Depends(get_current_user)):
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.id == current_user.id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        return {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "avatar_url": user.avatar_url,
            "is_premium": user.is_premium,
        }

def safe_json_field(val):
    try:
        return json.loads(val)
    except Exception:
        return None

def _google_api_key() -> str:
    return os.getenv('GOOGLE_MAPS_API_KEY') or ''

@app.get("/api/mosques/nearby")
def nearby_mosques(lat: float = Query(...), lng: float = Query(...), radius: float = Query(3.0, description="km cinsinden")):
    api_key = _google_api_key()
    if not api_key:
        raise HTTPException(status_code=400, detail="Google Maps API anahtarı eksik")
    # km → metre
    radius_m = float(radius) * 1000.0
    # Google Places API çağrısı
    url = (
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?" +
        urllib.parse.urlencode({
            "location": f"{lat},{lng}",
            "radius": int(radius_m),
            "type": "mosque",
            "key": api_key
        })
    )
    try:
        resp = requests.get(url, timeout=15)
        data = resp.json()
        items = []
        for p in data.get("results", []):
            name = p.get("name")
            geo = p.get("geometry", {}).get("location", {})
            plat = geo.get("lat")
            plng = geo.get("lng")
            rating = p.get("rating")
            vicinity = p.get("vicinity")
            items.append({
                "name": name,
                "lat": plat,
                "lng": plng,
                "rating": rating,
                "vicinity": vicinity
            })
        return {"items": items}
    except Exception:
        logging.exception("Cami arama hatası")
        raise HTTPException(status_code=500, detail="Bir hata oluştu")
