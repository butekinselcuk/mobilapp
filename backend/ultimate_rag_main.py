import os
import asyncio
from typing import List, Dict, Tuple

# Proje içi modüller
from vector_search import search_hadiths, cosine_similarity
from embedding_utils import generate_embedding
try:
    from ai_models.hadis_model import hadis_ai_model
    _HADIS_AI_AVAILABLE = True
except Exception:
    _HADIS_AI_AVAILABLE = False

import requests
import json


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
    # Sorgu embedding'i (varsa) ile puan hesaplamak için hazırla
    query_emb = generate_embedding(question)
    if isinstance(query_emb, str):
        try:
            query_emb = [float(x) for x in query_emb.split(',') if x.strip()]
        except Exception:
            query_emb = None
    hadith_dicts: List[Dict] = []
    for h in results:
        text = (
            getattr(h, 'turkish_text', None)
            or getattr(h, 'english_text', None)
            or getattr(h, 'arabic_text', None)
            or getattr(h, 'text', '')
        )
        source = getattr(h, 'source', '')
        reference = getattr(h, 'reference', '')
        # Skor: embedding mevcutsa kosinüs benzerliği
        score_val = None
        try:
            emb_str = getattr(h, 'embedding', None)
            if emb_str and query_emb:
                emb_vec = [float(x) for x in emb_str.split(',') if x.strip()]
                score_val = float(cosine_similarity(query_emb, emb_vec))
        except Exception:
            score_val = None

        hadith_dicts.append({
            'id': getattr(h, 'id', None),
            'text': text or '',
            'source': source or '',
            'reference': reference or '',
            'full_reference': f"{source} - {reference}".strip(' - '),
            'score': score_val,
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


def _call_gemini(question: str, hadith_context: str, language: str = 'tr') -> str:
    """Gemini HTTP API çağrısı (opsiyonel).

    Ortam değişkenlerinden URL ve API key okur. Yapılandırılmamışsa özel bir işaret döner.
    """
    api_key = os.getenv('GEMINI_API_KEY')
    url = os.getenv('GEMINI_URL')
    if not api_key or not url:
        return "__GEMINI_NOT_CONFIGURED__"
    try:
        payload = {
            'question': question,
            'context': hadith_context,
            'language': language,
        }
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        resp = requests.post(url, json=payload, headers=headers, timeout=30)
        if resp.status_code != 200:
            return "__GEMINI_ERROR__"
        data = resp.json()
        return data.get('answer') or "__GEMINI_ERROR__"
    except Exception:
        return "__GEMINI_ERROR__"

def _call_openai(question: str, hadith_context: str, language: str = 'tr') -> str:
    """OpenAI Chat Completions çağrısı (HTTP üzerinden).

    Gerekli ortam değişkenleri: OPENAI_API_KEY, OPENAI_MODEL, OPENAI_MAX_TOKENS, TEMPERATURE
    """
    api_key = os.getenv('OPENAI_API_KEY')
    model = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
    max_tokens = int(os.getenv('OPENAI_MAX_TOKENS') or 1500)
    temperature = float(os.getenv('TEMPERATURE') or 0.7)
    if not api_key:
        return "__OPENAI_NOT_CONFIGURED__"
    try:
        url = 'https://api.openai.com/v1/chat/completions'
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }
        lang = (language or 'tr').lower()
        if lang == 'en':
            system_prompt = (
                "Answer only using the Qur'an, Kutub al-Sittah and reputable fiqh sources. "
                "Always include sources at the end. Do not add personal opinions."
            )
            answer_lang_directive = "Respond in English."
        elif lang == 'ar':
            system_prompt = (
                "أجب فقط باستخدام القرآن وكتب الستّة ومصادر الفقه المعتبرة. "
                "اذكر المصادر في نهاية كل إجابة. لا تُضِف آراءً شخصية."
            )
            answer_lang_directive = "أجب باللغة العربية."
        else:
            system_prompt = (
                "Sadece Kur'an, Kütüb-i Sitte ve muteber fıkıh kaynaklarından cevap ver. "
                "Her cevabın sonunda kaynak belirt. Kişisel yorum ekleme."
            )
            answer_lang_directive = "Cevabı Türkçe ver."
        user_text = (
            f"Question: {question}\n\n"
            f"Context (hadith excerpts):\n{hadith_context}\n\n"
            "Use the context above to produce a reliable, sourced answer. "
            f"{answer_lang_directive}"
        )
        body = {
            'model': model,
            'temperature': temperature,
            'max_tokens': max_tokens,
            'messages': [
                {'role': 'system', 'content': system_prompt},
                {'role': 'user', 'content': user_text},
            ]
        }
        resp = requests.post(url, headers=headers, data=json.dumps(body), timeout=30)
        if resp.status_code != 200:
            return "__OPENAI_ERROR__"
        data = resp.json()
        try:
            return data['choices'][0]['message']['content']
        except Exception:
            return "__OPENAI_ERROR__"
    except Exception:
        return "__OPENAI_ERROR__"

def _call_claude(question: str, hadith_context: str, language: str = 'tr') -> str:
    """Anthropic Claude Messages API çağrısı.

    Gerekli ortam değişkenleri: CLAUDE_API_KEY, CLAUDE_MODEL, CLAUDE_MAX_TOKENS, TEMPERATURE
    """
    api_key = os.getenv('CLAUDE_API_KEY')
    model = os.getenv('CLAUDE_MODEL', 'claude-3-5-sonnet')
    max_tokens = int(os.getenv('CLAUDE_MAX_TOKENS') or 1500)
    temperature = float(os.getenv('TEMPERATURE') or 0.7)
    if not api_key:
        return "__CLAUDE_NOT_CONFIGURED__"
    try:
        url = 'https://api.anthropic.com/v1/messages'
        headers = {
            'x-api-key': api_key,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json'
        }
        lang = (language or 'tr').lower()
        if lang == 'en':
            system_prompt = (
                "Answer only using the Qur'an, Kutub al-Sittah and reputable fiqh sources. "
                "Always include sources at the end. Do not add personal opinions."
            )
            answer_lang_directive = "Respond in English."
        elif lang == 'ar':
            system_prompt = (
                "أجب فقط باستخدام القرآن وكتب الستّة ومصادر الفقه المعتبرة. "
                "اذكر المصادر في نهاية كل إجابة. لا تُضِف آراءً شخصية."
            )
            answer_lang_directive = "أجب باللغة العربية."
        else:
            system_prompt = (
                "Sadece Kur'an, Kütüb-i Sitte ve muteber fıkıh kaynaklarından cevap ver. "
                "Her cevabın sonunda kaynak belirt. Kişisel yorum ekleme."
            )
            answer_lang_directive = "Cevabı Türkçe ver."
        body = {
            'model': model,
            'max_tokens': max_tokens,
            'temperature': temperature,
            'system': system_prompt,
            'messages': [
                {
                    'role': 'user',
                    'content': [
                        {
                            'type': 'text',
                            'text': (
                                f"Question: {question}\n\nContext (hadith excerpts):\n{hadith_context}\n\n"
                                "Use the context above to produce a reliable, sourced answer. "
                                f"{answer_lang_directive}"
                            )
                        }
                    ]
                }
            ]
        }
        resp = requests.post(url, headers=headers, data=json.dumps(body), timeout=30)
        if resp.status_code != 200:
            return "__CLAUDE_ERROR__"
        data = resp.json()
        try:
            # Claude response: {'content': [{'type': 'text', 'text': '...'}], ...}
            return data['content'][0]['text']
        except Exception:
            return "__CLAUDE_ERROR__"
    except Exception:
        return "__CLAUDE_ERROR__"


def generate_ai_response_with_fallback(question: str, hadith_dicts: List[Dict], enable_gemini_fallback: bool = True, language: str = 'tr') -> Tuple[str, bool, str]:
    """Önce yerel Hadis AI ile yanıt üretir, sonra PRIMARY/FALLBACK AI modeline göre düşer.

    Returns: (answer, used_fallback, response_type)
    response_type: 'hadis_ai' | 'openai' | 'claude' | 'gemini' | 'hadis_compose' | 'fallback'
    """
    hadith_context = _build_hadith_context(hadith_dicts)

    # 1) Yerel Hadis AI (varsa ve güvenilir sonuç üretirse)
    if _HADIS_AI_AVAILABLE:
        try:
            result = hadis_ai_model.generate_response(question, hadith_context)
            answer = result.get('answer') or ''
            confidence = float(result.get('confidence') or 0.0)
            if confidence >= 0.7 and answer:
                return answer, False, 'hadis_ai'
        except Exception:
            # Sessizce dış modele düş
            pass

    # 2) Dış model seçimleri (PRIMARY ve FALLBACK)
    primary = (os.getenv('PRIMARY_AI_MODEL') or '').strip().lower() or 'openai'
    fallback = (os.getenv('FALLBACK_AI_MODEL') or '').strip().lower() or 'openai'

    def _call_by_name(name: str) -> Tuple[str, str]:
        if name == 'openai':
            return _call_openai(question, hadith_context, language), 'openai'
        if name == 'claude':
            return _call_claude(question, hadith_context, language), 'claude'
        if name == 'gemini' and enable_gemini_fallback:
            return _call_gemini(question, hadith_context, language), 'gemini'
        # Tanınmayan isim -> yapılandırılmamış say
        return "__MODEL_NOT_CONFIGURED__", name or 'unknown'

    # Önce PRIMARY
    ans1, t1 = _call_by_name(primary)
    if ans1 not in {"__OPENAI_ERROR__", "__OPENAI_NOT_CONFIGURED__", "__CLAUDE_ERROR__", "__CLAUDE_NOT_CONFIGURED__", "__GEMINI_ERROR__", "__GEMINI_NOT_CONFIGURED__", "__MODEL_NOT_CONFIGURED__"} and ans1:
        return ans1, True, t1

    # Sonra FALLBACK
    ans2, t2 = _call_by_name(fallback)
    if ans2 not in {"__OPENAI_ERROR__", "__OPENAI_NOT_CONFIGURED__", "__CLAUDE_ERROR__", "__CLAUDE_NOT_CONFIGURED__", "__GEMINI_ERROR__", "__GEMINI_NOT_CONFIGURED__", "__MODEL_NOT_CONFIGURED__"} and ans2:
        return ans2, True, t2

    # 3) Son çare: bulunan hadislerden derlenmiş yanıt
    if hadith_dicts:
        return _compose_answer_from_hadiths(question, hadith_dicts), True, 'hadis_compose'
    return "Sorunuzu daha açık yazar mısınız?", True, 'fallback'

def _compose_answer_from_hadiths(question: str, hadith_dicts: List[Dict], max_items: int = 3) -> str:
    """Gemini kapalı olduğunda veya yanıt veremediğinde, bulunan hadislerden
    anlaşılır ve kaynaklı bir cevap oluşturur."""
    if not hadith_dicts:
        return "Bu konuda güvenilir hadis kaynağı bulunamadı. Lütfen sorunuzu farklı şekilde ifade edin."
    parts: List[str] = []
    for h in hadith_dicts[:max_items]:
        txt = (h.get('text') or '').strip()
        src = h.get('source') or ''
        ref = h.get('reference') or ''
        ref_block = (f"Kaynak: {src} - {ref}").strip()
        if txt:
            parts.append(f"{txt}\n{ref_block}")
        else:
            parts.append(ref_block)
    parts.append("Daha isabetli sonuçlar için konuyu biraz daraltarak sorabilirsiniz.")
    return "\n\n".join(parts)
