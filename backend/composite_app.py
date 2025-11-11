from typing import Any, Optional, List
from fastapi import Query, Depends, HTTPException
from sqlalchemy import select, or_, and_, func

# Mevcut FastAPI uygulamasını ana dosyadan içe aktar
from main import app

# DB session
from database import AsyncSessionLocal

# Modeller
from models import (
    QuranVerse, Dua, Zikr, Tafsir, Hadith, Reciter,
)

# Vektör arama yardımcıları
from vector_search import search_hadiths

# --- Mevcut endpoint: Hadis vektör arama ---
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

# --- Yardımcı: sure numarasını isme çevir ---
SURAH_ID_TO_NAME = {
    1: "Fatiha", 2: "Bakara", 3: "Al-i İmran", 4: "Nisa", 5: "Maide",
    6: "En'am", 7: "A'raf", 8: "Enfal", 9: "Tevbe", 10: "Yunus",
    11: "Hud", 12: "Yusuf", 13: "Ra'd", 14: "İbrahim", 15: "Hicr",
    16: "Nahl", 17: "İsra", 18: "Kehf", 19: "Meryem", 20: "Taha",
    21: "Enbiya", 22: "Hac", 23: "Mü'minun", 24: "Nur", 25: "Furkan",
    26: "Şuara", 27: "Neml", 28: "Kasas", 29: "Ankebut", 30: "Rum",
    31: "Lokman", 32: "Secde", 33: "Ahzab", 34: "Sebe", 35: "Fatır",
    36: "Yasin", 37: "Saffat", 38: "Sad", 39: "Zümer", 40: "Mümin",
    41: "Fussilet", 42: "Şura", 43: "Zuhruf", 44: "Duhan", 45: "Casiye",
    46: "Ahkaf", 47: "Muhammed", 48: "Fetih", 49: "Hucurat", 50: "Kaf",
    51: "Zariyat", 52: "Tur", 53: "Necm", 54: "Kamer", 55: "Rahman",
    56: "Vakia", 57: "Hadid", 58: "Mücadele", 59: "Haşr", 60: "Mümtehine",
    61: "Saff", 62: "Cuma", 63: "Münafikun", 64: "Tegabun", 65: "Talak",
    66: "Tahrim", 67: "Mülk", 68: "Kalem", 69: "Hakka", 70: "Mearic",
    71: "Nuh", 72: "Cin", 73: "Müzzemmil", 74: "Müddessir", 75: "Kıyamet",
    76: "İnsan", 77: "Mürselat", 78: "Nebe", 79: "Naziat", 80: "Abese",
    81: "Tekvir", 82: "İnfitar", 83: "Mutaffifin", 84: "İnşikak", 85: "Büruc",
    86: "Tarık", 87: "Ala", 88: "Gaşiye", 89: "Fecr", 90: "Beled",
    91: "Şems", 92: "Leyl", 93: "Duha", 94: "İnşirah", 95: "Tin",
    96: "Alak", 97: "Kadir", 98: "Beyyine", 99: "Zilzal", 100: "Adiyat",
    101: "Karia", 102: "Tekasur", 103: "Asr", 104: "Hümeze", 105: "Fil",
    106: "Kureyş", 107: "Maun", 108: "Kevser", 109: "Kafirun", 110: "Nasr",
    111: "Tebbet", 112: "İhlas", 113: "Felak", 114: "Nas",
}

# --- Kur'an ayetleri ---
@app.get("/api/quran")
async def get_quran(
    surah: Optional[str] = Query(None, description="Surenin adı veya numarası"),
    ayah: Optional[int] = Query(None, description="Ayet numarası"),
    language: Optional[str] = Query("tr", description="Dil: tr/en/ar"),
    search: Optional[str] = Query(None, description="Metin arama"),
    reciter: Optional[str] = Query(None, description="Okuyucu adı")
):
    async with AsyncSessionLocal() as session:
        q = select(QuranVerse)
        # Surah filtre
        if surah:
            try:
                surah_num = int(surah)
                surah_name = SURAH_ID_TO_NAME.get(surah_num)
                if surah_name:
                    q = q.where(or_(QuranVerse.surah == surah_name, QuranVerse.surah == str(surah_num)))
                else:
                    q = q.where(or_(QuranVerse.surah == str(surah_num)))
            except ValueError:
                q = q.where(QuranVerse.surah == surah)
        # Ayet filtre
        if ayah is not None:
            q = q.where(QuranVerse.ayah == ayah)
        # Dil filtre
        if language:
            q = q.where(QuranVerse.language == language)
        # Metin arama
        if search:
            like = f"%{search}%"
            q = q.where(or_(QuranVerse.text.ilike(like)))
        res = await session.execute(q)
        verses = res.scalars().all()
        # Audio desteği: reciter adı varsa audio_url üret
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

# --- Dua listesi ---
@app.get("/api/dua")
async def get_dua(
    category: Optional[str] = Query(None, description="Kategori"),
    language: Optional[str] = Query("tr", description="Dil"),
    search: Optional[str] = Query(None, description="Metin arama")
):
    async with AsyncSessionLocal() as session:
        q = select(Dua)
        if category:
            q = q.where(Dua.category == category)
        if language:
            q = q.where(Dua.language == language)
        if search:
            like = f"%{search}%"
            q = q.where(or_(Dua.text.ilike(like)))
        res = await session.execute(q)
        items = res.scalars().all()
        return [{"id": d.id, "text": d.text, "category": d.category, "language": d.language} for d in items]

# --- Zikir listesi ---
@app.get("/api/zikr")
async def get_zikr(
    category: Optional[str] = Query(None, description="Kategori"),
    language: Optional[str] = Query("tr", description="Dil"),
    search: Optional[str] = Query(None, description="Metin arama")
):
    async with AsyncSessionLocal() as session:
        q = select(Zikr)
        if category:
            q = q.where(Zikr.category == category)
        if language:
            q = q.where(Zikr.language == language)
        if search:
            like = f"%{search}%"
            q = q.where(or_(Zikr.name.ilike(like), Zikr.slug.ilike(like)))
        res = await session.execute(q)
        items = res.scalars().all()
        # Frontend beklenen yapıya uyum: title=name, count=default_target
        return [{"id": z.id, "title": z.name, "count": z.default_target, "category": z.category, "language": z.language} for z in items]

# --- Tefsir ---
@app.get("/api/tafsir")
async def get_tafsir(
    surah: Optional[str] = Query(None, description="Surenin adı veya numarası"),
    ayah: Optional[int] = Query(None, description="Ayet numarası"),
    author: Optional[str] = Query(None, description="Müfessir"),
    language: Optional[str] = Query("tr", description="Dil"),
    search: Optional[str] = Query(None, description="Metin arama")
):
    async with AsyncSessionLocal() as session:
        q = select(Tafsir)
        if surah:
            try:
                surah_num = int(surah)
                surah_name = SURAH_ID_TO_NAME.get(surah_num)
                if surah_name:
                    q = q.where(or_(Tafsir.surah == surah_name, Tafsir.surah == str(surah_num)))
                else:
                    q = q.where(or_(Tafsir.surah == str(surah_num)))
            except ValueError:
                q = q.where(Tafsir.surah == surah)
        if ayah is not None:
            q = q.where(Tafsir.ayah == ayah)
        if author:
            q = q.where(Tafsir.author == author)
        if language:
            q = q.where(Tafsir.language == language)
        if search:
            like = f"%{search}%"
            q = q.where(or_(Tafsir.text.ilike(like)))
        res = await session.execute(q)
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

# --- Kıraatçılar ---
@app.get("/api/reciters")
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

# --- Günün Ayeti ---
@app.get("/api/daily_ayah")
async def get_daily_ayah():
    async with AsyncSessionLocal() as session:
        # Basit bir seçim: rastgele veya sırayla
        # Burada RAND yerine mod tabanlı bir seçim kullanıyoruz ki her gün değişsin
        today = func.date_trunc('day', func.now())
        res = await session.execute(select(QuranVerse).order_by(func.random()).limit(1))
        verse = res.scalars().first()
        if not verse:
            raise HTTPException(status_code=404, detail="Ayah bulunamadı")
        return {
            "surah": verse.surah,
            "ayah": verse.ayah,
            "text": verse.text,
            "language": verse.language,
        }

# --- Günün Hadisi ---
@app.get("/api/daily_hadith")
async def get_daily_hadith():
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Hadith).order_by(func.random()).limit(1))
        h = res.scalars().first()
        if not h:
            raise HTTPException(status_code=404, detail="Hadis bulunamadı")
        text = (
            getattr(h, 'turkish_text', None)
            or getattr(h, 'english_text', None)
            or getattr(h, 'arabic_text', None)
            or getattr(h, 'text', '')
        )
        return {
            "id": h.id,
            "text": text,
            "source": h.source,
            "reference": h.reference,
            "category": h.category,
            "language": h.language,
        }
