import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
from models import Hadith
from embedding_utils import generate_embedding
from sqlalchemy import select, or_
import math
import json

def simple_distance(a: str, b: str) -> int:
    # Dummy: hash stringlerinin farkı (gerçek projede cosine similarity vs. kullanılmalı)
    return abs(int(a) - int(b))

def cosine_similarity(a, b):
    # Numpy olmadan kosinüs benzerliği
    if not a or not b:
        return 0.0
    # Farklı uzunluklarda ise eşleşen kısmı kullan
    length = min(len(a), len(b))
    if length == 0:
        return 0.0
    dot = sum(a[i] * b[i] for i in range(length))
    norm_a = math.sqrt(sum(x * x for x in a[:length]))
    norm_b = math.sqrt(sum(x * x for x in b[:length]))
    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return float(dot / (norm_a * norm_b))

async def search_hadiths(query: str, top_k: int = 3):
    query_emb = generate_embedding(query)
    if isinstance(query_emb, str):
        query_emb = [float(x) for x in query_emb.split(",") if x.strip()]

    async with AsyncSessionLocal() as session:
        # Geçerli embedding’i olanları al (None veya boş olmayanlar)
        hadiths_with_emb = (await session.execute(
            select(Hadith).where((Hadith.embedding != None) & (Hadith.embedding != ""))
        )).scalars().all()

        # Embedding’ler ve sorgu embedding’i varsa vektör benzerliği kullan
        if hadiths_with_emb and query_emb:
            scored = []
            for h in hadiths_with_emb:
                try:
                    emb = [float(x) for x in h.embedding.split(",") if x.strip()]
                    sim = cosine_similarity(query_emb, emb)
                    scored.append((sim, h))
                except Exception:
                    continue
            if scored:
                scored.sort(reverse=True, key=lambda x: x[0])
                return [h for _, h in scored[:top_k]]

        # Aksi halde basit metin eşleşmesi ile geri dönüş (güvenli çok aşamalı fallback)
        like = f"%{query}%"
        
        # 1) Tercih edilen sütunlar: turkish_text, english_text, arabic_text
        # 2) Minimal şema: text
        # Tüm denemeleri try/except ile sarmalayarak, sütun eksikliği gibi hatalarda
        # bir sonraki stratejiye düşüyoruz.
        def try_query(columns):
            conditions = [getattr(Hadith, c).ilike(like) for c in columns if hasattr(Hadith, c)]
            # Her zaman mevcut olduğunu bildiğimiz destekleyici alanlar
            conditions.extend([Hadith.source.ilike(like), Hadith.reference.ilike(like)])
            q = select(Hadith).where(or_(*conditions)).limit(top_k)
            return q

        # Deneme sırası: zengin metin alanları → minimal text → sadece source/reference
        for cols in (["turkish_text", "english_text", "arabic_text"], ["text"]):
            try:
                result = await session.execute(try_query(cols))
                rows = result.scalars().all()
                if rows:
                    return rows
            except Exception:
                # Bu strateji başarısızsa bir sonrakine geç
                pass

        # Son çare: sadece source/reference üzerinde arama
        try:
            result = await session.execute(
                select(Hadith).where(
                    or_(Hadith.source.ilike(like), Hadith.reference.ilike(like))
                ).limit(top_k)
            )
            rows = result.scalars().all()
            return rows
        except Exception:
            # Hiçbiri çalışmazsa boş döndür
            return []

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Kullanım: python vector_search.py <sorgu>")
        exit(1)
    query = sys.argv[1]
    results = asyncio.run(search_hadiths(query))
    for h in results:
        print(f"Hadis: {h.text}\nKaynak: {h.source}\n---")
