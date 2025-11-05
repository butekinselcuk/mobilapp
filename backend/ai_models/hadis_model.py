import logging
import re
from typing import Dict, Any

class HadisAI:
    def __init__(self):
        """
        Basit hadis AI sınıfı - gerçek model olmadan çalışır
        Canlı sistemde gerçek model entegre edilebilir
        """
        self.is_available = True
        logging.info("Hadis AI modeli (demo modu) başlatıldı")
    
    def _analyze_question_confidence(self, question: str, hadith_context: str) -> float:
        """
        Sorunun hadis bağlamıyla uyumunu analiz eder
        
        Args:
            question (str): Kullanıcı sorusu
            hadith_context (str): Hadis bağlamı
            
        Returns:
            float: Güven skoru (0.0-1.0)
        """
        question_lower = question.lower()
        context_lower = hadith_context.lower()
        
        # Hadis ile ilgili anahtar kelimeler
        hadis_keywords = [
            'hadis', 'hadith', 'peygamber', 'rasul', 'sahabe', 'rivayet',
            'buhari', 'müslim', 'tirmizi', 'ebu davud', 'nesai', 'ibn mace',
            'sünnet', 'hadis-i şerif', 'rivayette', 'nakledilir'
        ]
        
        # Dini terimler
        religious_terms = [
            'namaz', 'oruç', 'zekât', 'hac', 'abdest', 'gusül', 'temizlik',
            'dua', 'zikir', 'tövbe', 'istiğfar', 'salavat', 'tesbih',
            'helal', 'haram', 'mekruh', 'müstehab', 'farz', 'vacip',
            'allah', 'peygamber', 'islam', 'iman', 'ihsan', 'takva'
        ]
        
        confidence = 0.0
        
        # Hadis anahtar kelimesi varsa +0.3
        if any(keyword in question_lower for keyword in hadis_keywords):
            confidence += 0.3
        
        # Dini terim varsa +0.2
        if any(term in question_lower for term in religious_terms):
            confidence += 0.2
        
        # Bağlamda ilgili kelimeler varsa +0.3
        question_words = set(re.findall(r'\b\w+\b', question_lower))
        context_words = set(re.findall(r'\b\w+\b', context_lower))
        common_words = question_words.intersection(context_words)
        
        if len(common_words) > 2:
            confidence += 0.3
        elif len(common_words) > 0:
            confidence += 0.1
        
        # Soru uzunluğu kontrolü (çok kısa sorular düşük güven)
        if len(question.split()) < 3:
            confidence *= 0.7
        
        # Maksimum 1.0 ile sınırla
        return min(confidence, 1.0)
    
    def generate_response(self, question: str, hadith_context: str) -> Dict[str, Any]:
        """
        Verilen soru ve hadis bağlamına göre cevap üretir
        
        Args:
            question (str): Kullanıcı sorusu
            hadith_context (str): İlgili hadis metinleri
            
        Returns:
            Dict[str, Any]: {"answer": str, "confidence": float}
        """
        try:
            # Güven skorunu hesapla
            confidence = self._analyze_question_confidence(question, hadith_context)
            
            # Eğer güven skoru yeterli ise basit bir cevap üret
            if confidence >= 0.7:
                # Hadis bağlamından bilgi çıkar
                answer = self._generate_simple_answer(question, hadith_context)
            else:
                # Düşük güven skoru - Gemini'ye bırak
                answer = "Bu konuda daha detaylı araştırma gerekiyor."
                confidence = 0.0
            
            return {
                "answer": answer,
                "confidence": confidence
            }
            
        except Exception as e:
            logging.error(f"Hadis AI cevap üretme hatası: {e}")
            return {
                "answer": "Üzgünüm, şu anda cevap üretemiyorum.",
                "confidence": 0.0
            }
    
    def _generate_simple_answer(self, question: str, hadith_context: str) -> str:
        """
        Basit cevap üretir (gerçek model olmadan)
        
        Args:
            question (str): Kullanıcı sorusu
            hadith_context (str): Hadis bağlamı
            
        Returns:
            str: Üretilen cevap
        """
        # Hadis kaynaklarını çıkar
        sources = []
        lines = hadith_context.split('\n')
        for line in lines:
            if 'Kaynak:' in line and 'Referans:' in line:
                parts = line.split('|')
                if len(parts) >= 2:
                    source = parts[0].replace('Kaynak:', '').strip()
                    reference = parts[1].replace('Referans:', '').strip()
                    sources.append(f"{source} - {reference}")
        
        # Basit cevap şablonu
        if sources:
            source_text = ", ".join(sources[:2])  # İlk 2 kaynağı al
            answer = f"Bu konuda {source_text} kaynaklarında bilgi bulunmaktadır. Detaylı bilgi için güvenilir hadis kaynaklarına başvurmanız önerilir."
        else:
            answer = "Bu konuda hadis kaynaklarında bilgi bulunmaktadır. Detaylı bilgi için güvenilir kaynaklara başvurmanız önerilir."
        
        return answer
    
# Global instance
hadis_ai_model = HadisAI()