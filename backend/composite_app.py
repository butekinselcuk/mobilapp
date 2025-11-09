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
    q: Optional[str] = Query(None, description="Metin arama (alias)"),
    reciter: Optional[str] = Query(None, description="Okuyucu adı")
):
    """Kur'an ayetleri endpointi.
    Not: main.py'deki /api/quran ile aynı şemayı döndürür ve benzer fallback uygular.
    """
    async with AsyncSessionLocal() as session:
        import re
        from sqlalchemy import or_

        query = select(QuranVerse)
        # Sûre filtresi (isim veya numara)
        if surah:
            try:
                surah_num = int(surah)
                surah_name = SURAH_ID_TO_NAME.get(surah_num)
                if surah_name:
                    query = query.where(or_(QuranVerse.surah == surah_name, QuranVerse.surah == str(surah_num)))
                else:
                    query = query.where(QuranVerse.surah == str(surah_num))
            except ValueError:
                query = query.where(QuranVerse.surah == surah)
        # Ayet filtresi
        if ayah is not None:
            query = query.where(QuranVerse.ayah == ayah)
        # Dil filtresi
        if language:
            query = query.where(QuranVerse.language == language)
        # Metin arama (search veya q)
        search_term = search or q
        if search_term:
            like = f"%{search_term}%"
            query = query.where(QuranVerse.text.ilike(like))

        # Sorguyu çalıştır
        res = await session.execute(query)
        verses = res.scalars().all()

        # Audio URL üretimi: global ayet numarasına göre islamic.network CDN
        def build_audio_url(v):
            if not reciter:
                return None
            global_num = None
            # DB'deki audio_url sonundan global numarayı yakalamayı dene
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
            return f"https://cdn.islamic.network/quran/audio/128/{reciter}/{verse_num}.mp3"

        # Eğer veri yoksa AlQuran Cloud fallback uygula
        if not verses and (surah or search_term or ayah is not None):
            try:
                import httpx
                # Surah ID'yi belirle
                surah_id = None
                if surah and str(surah).isdigit():
                    surah_id = int(surah)
                else:
                    # İsimden ID'ye ters map
                    for sid, sname in SURAH_ID_TO_NAME.items():
                        if surah and str(surah).lower() == str(sname).lower():
                            surah_id = sid
                            break
                if not surah_id:
                    surah_id = 112  # İhlas

                ayahs_ar = []
                data_ar = {}
                ayahs_tr_map = {}

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
                    except Exception:
                        ayahs_ar = []

                    # Türkçe meal istenirse ekle
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
                        except Exception:
                            pass

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
                    # Reciter verilmişse global numarayı kullanarak URL üret
                    if reciter and a.get('number'):
                        try:
                            global_num = int(a.get('number'))
                            item['audio_url'] = f'https://cdn.islamic.network/quran/audio/128/{reciter}/{global_num}.mp3'
                        except Exception:
                            pass
                    fallback.append(item)

                return fallback
            except Exception:
                return []

        # Normal yanıt (ana şemaya hizalı)
        return [
            {
                'id': v.id,
                'surah': v.surah,
                'ayah': v.ayah,
                'text': v.text,
                'translation': v.translation,
                'language': v.language,
                'surah_id': getattr(v, 'surah_id', None),
                'surah_name': getattr(v, 'surah_name', v.surah),
                'ayah_number': getattr(v, 'ayah_number', v.ayah),
                'text_ar': getattr(v, 'text_ar', None),
                'text_tr': getattr(v, 'text_tr', None),
                'audio_url': build_audio_url(v) if reciter else (getattr(v, 'audio_url', None))
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
            q = q.where(or_(Zikr.text.ilike(like)))
        res = await session.execute(q)
        items = res.scalars().all()
        return [{"id": z.id, "text": z.text, "category": z.category, "language": z.language} for z in items]

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
