from fastapi import Query
from typing import Any

# Mevcut FastAPI uygulamasını ana dosyadan içe aktar
from main import app

# Vektör arama yardımcılarını içe aktar
from vector_search import search_hadiths

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
