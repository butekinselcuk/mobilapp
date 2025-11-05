# API_DOCS.md (prompt/ klasörü)

> **Not:** Bu dosya, context engine ve LLM tabanlı araçlar için projenin API endpointlerinin merkezi ve tekil kaynağıdır. Tüm önemli endpointler, parametreler, örnek istek/yanıtlar ve ilgili veri modelleri burada tutulur. Diğer md dosyaları için referans noktasıdır. Yeni API'ler geldikçe burası güncellenmelidir.

---

# API Endpointleri ve Akışlar

## 1. Soru Sorma (AI Asistanı) - Hibrit AI Sistemi
- **Endpoint:** `/api/ask`
- **Yöntem:** `POST`
- **Amaç:** Kullanıcıdan gelen dini soruya, hibrit AI sistemi (Fine-tuned Hadis AI + Gemini Pro geri dönüş) ile güvenilir kaynaklardan referanslı cevap döndürür.
- **Hibrit Mantık:**
  1. Vektör arama ile ilgili hadisler bulunur
  2. Fine-tuned Hadis AI modeli önce denenir
  3. Güven skoru ≥ 0.7 ise Hadis AI cevabı kullanılır
  4. Güven skoru < 0.7 ise Gemini Pro'ya geri dönülür
  5. AI kaynak takibi ile hangi modelin kullanıldığı belirtilir
- **Parametreler:**
  - `question` (str): Kullanıcı sorusu
  - `source_filter` (str): "quran", "hadis", "all"
- **Örnek İstek:**
```json
{
  "question": "Oruçluyken misvak kullanılır mı?",
  "source_filter": "all"
}
```
- **Örnek Yanıt (Hadis AI):**
```json
{
  "answer": "Evet, oruçluyken misvak kullanmak caizdir. (Tirmizî, Savm, 29)",
  "sources": [
    { "type": "hadis", "name": "Tirmizî - Savm, 29 - Oruçluyken misvak..." },
    { "type": "ai", "name": "Hadis AI (Güven: 0.9)" }
  ]
}
```
- **Örnek Yanıt (Gemini Geri Dönüş):**
```json
{
  "answer": "Bu konuda güvenilir hadis kaynağından cevap...",
  "sources": [
    { "type": "hadis", "name": "Buhari - Savm, 15 - Misvak hakkında..." },
    { "type": "ai", "name": "Gemini Pro AI" }
  ]
}
```
- **İlgili Veri Modelleri:** [bkz: prompt/PROJECT_STRUCTURE.md > Backend]

---

## 2. Kaynak Listesi
- **Endpoint:** `/api/sources`
- **Yöntem:** `GET`
- **Amaç:** Kullanılabilir kaynakların listesini döndürür.
- **Örnek Yanıt:**
```json
[
  { "type": "quran", "name": "Kur'an-ı Kerim" },
  { "type": "hadis", "name": "Buhari" }
]
```

---

## 3. Kullanıcı Favorileri
- **Endpoint:** `/user/favorites`
- **Yöntem:** `GET`
- **Amaç:** Kullanıcının favori hadislerini döndürür (JWT ile kimlik doğrulama gerekir).
- **Örnek Yanıt:**
```json
[
  { "id": 1, "text": "Ameller niyetlere göredir.", ... }
]
```

---

## 4. Admin: Premium Kullanıcı Yönetimi
- **Endpoint:** `/admin/user/premium`
- **Yöntem:** `POST`
- **Amaç:** Kullanıcıya premium ver/kaldır (JWT ile kimlik doğrulama gerekir).
- **Parametreler:**
  - `user_id` (int)
  - `action` (str): "add" veya "remove"

---

## 5. (Yeni API'ler geldikçe buraya eklenmeli)
- Her yeni endpoint için: Amaç, parametreler, örnek istek/yanıt, ilgili veri modeli ve referanslar eklenmeli.

---

> **Not:** API endpointleri ve veri modelleri ile ilgili detaylar için [bkz: prompt/CONTEXT_OVERVIEW.md > API ve Akışlar] ve [prompt/PROJECT_STRUCTURE.md > Backend]. Diğer md dosyalarında tekrar veya bağlam kaybı tespit edilirse, bu dosyaya referans verilerek sadeleştirilmelidir.