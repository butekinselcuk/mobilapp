import os
import asyncio
from typing import List, Dict, Tuple

# Proje içi modüller
from vector_search import search_hadiths
try:
    from ai_models.hadis_model import hadis_ai_model
    _HADIS_AI_AVAILABLE = True
except Exception:
    _HADIS_AI_AVAILABLE = False

import requests


async def search_hadiths_ultimate(question: str, top_k: int = 3) -> List[Dict]:
    """Vektör araması ile ilgili hadisleri bulur ve dict liste döndürür.

    Dönen her öğe aşağıdaki anahtarları içerir:
    - id
    - text (turkish_text öncelikli)
    - source
    - reference
    - full_reference (source + reference)
    """
    results = await search_hadiths(question, top_k=top_k)
    hadith_dicts: List[Dict] = []
    for h in results:
        text = getattr(h, 'turkish_text', None) or getattr(h, 'arabic_text', None) or getattr(h, 'text', '')
        source = getattr(h, 'source', '')
        reference = getattr(h, 'reference', '')
        hadith_dicts.append({
            'id': getattr(h, 'id', None),
            'text': text or '',
            'source': source or '',
            'reference': reference or '',
            'full_reference': f"{source} - {reference}".strip(' - ')
        })
    return hadith_dicts


def _build_hadith_context(hadith_dicts: List[Dict]) -> str:
    # Basit bağlam formatı: "Kaynak: <source> | Referans: <reference> | Metin: <text>"
    lines = []
    for h in hadith_dicts:
        src = h.get('source') or ''
        ref = h.get('reference') or ''
        txt = (h.get('text') or '')[:400]
        lines.append(f"Kaynak: {src} | Referans: {ref} | Metin: {txt}")
    return "\n".join(lines)


def _call_gemini(question: str, hadith_context: str) -> str:
    """Gemini (veya benzeri) HTTP API çağrısı. Ortam değişkenlerinden URL ve API key okur.

    Konfigürasyon yoksa basit bir mesaj döner.
    """
    api_key = os.getenv('GEMINI_API_KEY')
    url = os.getenv('GEMINI_URL')
    if not api_key or not url:
        return "Bu konuda güvenilir hadis kaynağı bulunamadı. Lütfen sorunuzu farklı şekilde ifade edin."
    try:
        payload = {
            'question': question,
            'context': hadith_context,
        }
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        resp = requests.post(url, json=payload, headers=headers, timeout=30)
        if resp.status_code != 200:
            return "Üzgünüm, şu anda yanıt üretilemiyor."
        data = resp.json()
        # Beklenen alan: { "answer": "..." }
        return data.get('answer') or "Üzgünüm, şu anda yanıt üretilemiyor."
    except Exception:
        return "Üzgünüm, şu anda yanıt üretilemiyor."


def generate_ai_response_with_fallback(question: str, hadith_dicts: List[Dict], enable_gemini_fallback: bool = True) -> Tuple[str, bool, str]:
    """Önce yerel Hadis AI ile yanıt üretir, gerekirse Gemini'ye düşer.

    Returns: (answer, used_fallback, response_type)
    response_type: 'hadis_ai' veya 'gemini'
    """
    hadith_context = _build_hadith_context(hadith_dicts)

    # 1) Yerel Hadis AI
    if _HADIS_AI_AVAILABLE:
        try:
            result = hadis_ai_model.generate_response(question, hadith_context)
            answer = result.get('answer') or ''
            confidence = float(result.get('confidence') or 0.0)
            if confidence >= 0.7 and answer:
                return answer, False, 'hadis_ai'
        except Exception:
            # Sessizce Gemini'ye düş
            pass

    # 2) Gemini fallback
    if enable_gemini_fallback:
        answer = _call_gemini(question, hadith_context)
        return answer, True, 'gemini'

    # 3) Son çare: basit mesaj
    return "Sorunuzu daha açık yazar mısınız?", True, 'fallback'