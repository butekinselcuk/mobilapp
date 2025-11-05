import os
import requests
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
from models import Hadith
import asyncio
from sqlalchemy import select
from dotenv import load_dotenv
load_dotenv()
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
GEMINI_EMBEDDING_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-exp-03-07:embedContent"

# Dummy embedding fonksiyonu (örnek, ileride gerçek API ile değiştirilebilir)
def generate_embedding(text: str):
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY
    }
    payload = {
        "model": "models/gemini-embedding-exp-03-07",
        "content": {
            "parts": [{"text": text}]
        },
        "taskType": "SEMANTIC_SIMILARITY"
    }
    try:
        response = requests.post(GEMINI_EMBEDDING_URL, headers=headers, json=payload)
        response.raise_for_status()
        data = response.json()
        embedding = data.get('embedding', {}).get('values')
        if embedding is None:
            raise ValueError('Embedding Gemini API yanıtında bulunamadı!')
        return ','.join(map(str, embedding))
    except Exception as e:
        print(f"Embedding alınamadı: {e}")
        return None

async def update_hadith_embeddings():
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Hadith).where((Hadith.embedding == None) | (Hadith.embedding == ''))
        )
        hadiths = result.scalars().all()
        for hadith in hadiths:
            # Yeni şemada embedding için turkish_text kullanılmalı
            text = hadith.turkish_text or ''
            emb = generate_embedding(text)
            hadith.embedding = emb if emb is not None else ''
            session.add(hadith)
        await session.commit()
        print(f"{len(hadiths)} hadisin embeddingi güncellendi.")

if __name__ == "__main__":
    asyncio.run(update_hadith_embeddings()) 