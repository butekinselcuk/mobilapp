import os
import requests
from sqlalchemy.ext.asyncio import AsyncSession
from database import AsyncSessionLocal
from models import Hadith
import asyncio
from sqlalchemy import select
from dotenv import load_dotenv
load_dotenv()

# Sağlayıcı anahtarları ve uç noktaları
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
OPENAI_EMBEDDING_MODEL = os.getenv('OPENAI_EMBEDDING_MODEL', 'text-embedding-3-small')
OPENAI_EMBEDDING_URL = 'https://api.openai.com/v1/embeddings'

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
GEMINI_EMBEDDING_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-exp-03-07:embedContent"

def _generate_openai_embedding(text: str):
    if not OPENAI_API_KEY:
        return None
    try:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}",
        }
        payload = {
            "model": OPENAI_EMBEDDING_MODEL,
            "input": text or "",
        }
        resp = requests.post(OPENAI_EMBEDDING_URL, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        vec = data.get('data', [{}])[0].get('embedding')
        if not vec:
            return None
        return ','.join(map(str, vec))
    except Exception as e:
        print(f"OpenAI embedding hatası: {e}")
        return None

def _generate_gemini_embedding(text: str):
    if not GEMINI_API_KEY:
        return None
    try:
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": GEMINI_API_KEY,
        }
        payload = {
            "model": "models/gemini-embedding-exp-03-07",
            "content": {"parts": [{"text": text or ""}]},
            "taskType": "SEMANTIC_SIMILARITY",
        }
        response = requests.post(GEMINI_EMBEDDING_URL, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        data = response.json()
        embedding = data.get('embedding', {}).get('values')
        if not embedding:
            return None
        return ','.join(map(str, embedding))
    except Exception as e:
        print(f"Gemini embedding hatası: {e}")
        return None

# Sağlayıcı-agnostik embedding üretici: Önce OpenAI, sonra Gemini
def generate_embedding(text: str):
    emb = _generate_openai_embedding(text)
    if emb:
        return emb
    return _generate_gemini_embedding(text)

async def update_hadith_embeddings() -> int:
    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Hadith).where((Hadith.embedding == None) | (Hadith.embedding == ''))
        )
        hadiths = result.scalars().all()
        updated = 0
        for hadith in hadiths:
            # Yeni şemada embedding için turkish_text kullanılmalı
            text = hadith.turkish_text or ''
            if not text:
                continue
            emb = generate_embedding(text)
            hadith.embedding = emb if emb is not None else ''
            session.add(hadith)
            updated += 1
        await session.commit()
        print(f"{updated} hadisin embeddingi güncellendi.")
        return updated

if __name__ == "__main__":
    asyncio.run(update_hadith_embeddings())