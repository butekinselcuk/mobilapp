import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
from models import Hadith
from embedding_utils import generate_embedding
from sqlalchemy import select, or_
import numpy as np
import json

def simple_distance(a: str, b: str) -> int:
    # Dummy: hash stringlerinin farkı (gerçek projede cosine similarity vs. kullanılmalı)
    return abs(int(a) - int(b))

def cosine_similarity(a, b):
    a = np.array(a)
    b = np.array(b)
    if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
        return 0.0
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

async def search_hadiths(query: str, top_k: int = 3):
    query_emb = generate_embedding(query)
    if isinstance(query_emb, str):
        query_emb = [float(x) for x in query_emb.split(",") if x.strip()]
    async with AsyncSessionLocal() as session:
        hadiths = (await session.execute(select(Hadith).where(Hadith.embedding != None))).scalars().all()
    if not hadiths:
        return []
    # Vektör benzerliği (cosine similarity)
    def cosine_sim(a, b):
        a = np.array(a)
        b = np.array(b)
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    scored = []
    for h in hadiths:
        try:
            emb = [float(x) for x in h.embedding.split(",") if x.strip()]
            sim = cosine_sim(query_emb, emb)
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