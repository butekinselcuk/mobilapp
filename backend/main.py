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
from models import Mosque
import json
import httpx
from textwrap import shorten
import uuid
from scripts.migrate_and_seed import run as migrate_and_seed_run
from math import radians, degrees, sin, cos, atan2

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
            result = await session execute(
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
