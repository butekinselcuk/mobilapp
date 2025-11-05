# CHANGELOG.md (prompt/ klasörü)

> **Not:** Bu dosya, context engine ve LLM tabanlı araçlar için projenin sürüm notlarının merkezi ve tekil kaynağıdır. Tüm önemli değişiklikler, güncellemeler ve geriye dönük uyumluluk notları burada tutulur. Diğer md dosyaları için referans noktasıdır.

---

# Sürüm Notları (Changelog)

## [2024-12-19]
- **Hadis AI Entegrasyonu:** Fine-tuned hadis AI modeli entegre edildi
- **Hibrit AI Sistemi:** Hadis AI (güven skoru ≥ 0.7) + Gemini Pro geri dönüş mantığı
- **AI Kaynak Takibi:** Hangi AI modelinin kullanıldığı sources kısmında gösteriliyor
- **Backend Güncellemeleri:** `ai_models/hadis_model.py` modülü, hibrit mantık, güven skoru sistemi
- **Flutter UI Güncellemeleri:** AI kaynak göstergesi, ikon destekli kaynak görünümü
- **Paket Güncellemeleri:** torch, transformers, peft, accelerate, safetensors eklendi

## [2024-07-16]
- Namaz vakti bildirim altyapısı ve profil ekranı entegrasyonu: flutter_local_notifications 19.x ile timezone uyumlu, şehir bazlı, kullanıcıya özel dakika seçimiyle tam entegre çalışıyor.

## [2024-07-15]
- Dua metni okutma (TTS/text-to-speech) özelliği, gelişmiş kontroller ve erişilebilirlik ile kitaplık/dua detayında aktif.
- Bildirimler ve kişiselleştirme: flutter_local_notifications ile test bildirimi, izin kontrolü ve altyapı kuruldu.
- Premium üyelik akışı ve avantajlar: demo aktivasyon, avantajlar, premium bitiş tarihi, admin panelinden premium yapma/kaldırma, profil ve premium ekranında gösterim tamamlandı.
- AI asistanı referanslı cevap ve kaynak filtreleme: source_filter parametresi ile API ve UI'da kaynak seçimi aktif.
- Journey modüllerinde kullanıcı ilerlemesi ve zengin içerik: ilerleme barı, API'den ilerleme çekme/güncelleme, UI'da gösterim tamamlandı.

## [2024-07-14]
- Kitaplık ekranında Kur’an, Hadis, Dua, Zikir, Tefsir içeriklerinin listelenmesi ve detay ekranları modern UI ile tamamlandı.
- Kitaplık ekranı temel iskelet ve veri modeli, API ile canlı veri, kategori kartları, detay modalı, paylaş/kopyala/TTS, erişilebilirlik ve örnek veri yükleme tamamlandı.
- Ana sayfa kartları ve hızlı erişim butonları modernleştirildi, yönlendirme fonksiyonları ve canlı veri entegrasyonu tamamlandı.

## [2024-07-13]
- Journey modüllerinde etiketle filtreleme, arama, modern UI, Youtube video oynatıcı, drag & drop, CSV ile toplu yükleme tamamlandı.

## [2024-07-11]
- Favoriler, geçmiş, premium, profil, JWT, paylaş/kopyala, toplu silme, gelişmiş arama/filtreleme gibi tüm kullanıcı akışları eksiksiz ve modern UI/UX ile tamamlandı.

---

> **Not:** Sürüm notları ve değişiklikler ile ilgili detaylar için [bkz: prompt/CONTEXT_OVERVIEW.md > Yol Haritası ve Durum]. Diğer md dosyalarında tekrar veya bağlam kaybı tespit edilirse, bu dosyaya referans verilerek sadeleştirilmelidir.