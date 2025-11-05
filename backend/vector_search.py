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
        hadiths = (await session.execute(select(Hadith).where(Hadith.embedding != None))).scalars().all()
    if not hadiths:
        return []
    scored = []
    for h in hadiths:
        try:
            emb = [float(x) for x in h.embedding.split(",") if x.strip()]
            sim = cosine_similarity(query_emb, emb)
            scored.append((sim, h))
        except Exception:
            continue
    scored.sort(reverse=True, key=lambda x: x[0])
    return [h for _, h in scored[:top_k]]

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Kullanım: python vector_search.py <sorgu>")
        exit(1)
    query = sys.argv[1]
    results = asyncio.run(search_hadiths(query))
    for h in results:
        print(f"Hadis: {h.text}\nKaynak: {h.source}\n---")