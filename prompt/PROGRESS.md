# PROGRESS.md (prompt/ klasörü)

> **Not:** Bu dosya, context engine ve LLM tabanlı araçlar için projenin yol haritası ve güncel durumunun merkezi ve tekil kaynağıdır. Tüm ilerleme, yapılacaklar ve tamamlanan işler burada tutulur. Diğer md dosyaları için referans noktasıdır.

---

# Proje İlerleme ve Yol Haritası (Güncel Takip)

## Tamamlananlar
- [x] Kitaplık ekranında Kur’an, Hadis, Dua, Zikir, Tefsir içeriklerinin listelenmesi ve detay ekranları modern UI ile tamamlandı. (2024-07-14)
- [x] Kitaplık ekranı temel iskelet ve veri modeli, API ile canlı veri, kategori kartları, detay modalı, paylaş/kopyala/TTS, erişilebilirlik ve örnek veri yükleme tamamlandı. (2024-07-14)
- [x] Ana sayfa kartları ve hızlı erişim butonları modernleştirildi, yönlendirme fonksiyonları ve canlı veri entegrasyonu tamamlandı. (2024-07-14)
- [x] Journey modüllerinde etiketle filtreleme, arama, modern UI, Youtube video oynatıcı, drag & drop, CSV ile toplu yükleme tamamlandı. (2024-07-13)
- [x] Favoriler, geçmiş, premium, profil, JWT, paylaş/kopyala, toplu silme, gelişmiş arama/filtreleme gibi tüm kullanıcı akışları eksiksiz ve modern UI/UX ile tamamlandı. (2024-07-11)
- [x] Dua metni okutma (TTS/text-to-speech) özelliği, gelişmiş kontroller ve erişilebilirlik ile kitaplık/dua detayında aktif. (2024-07-15)
- [x] Bildirimler ve kişiselleştirme: flutter_local_notifications ile test bildirimi, izin kontrolü ve altyapı kuruldu. (2024-07-15)
- [x] Namaz vakti bildirim altyapısı ve profil ekranı entegrasyonu: flutter_local_notifications 19.x ile timezone uyumlu, şehir bazlı, kullanıcıya özel dakika seçimiyle tam entegre çalışıyor. (2024-07-16)
- [x] Premium üyelik akışı ve avantajlar: demo aktivasyon, avantajlar, premium bitiş tarihi, admin panelinden premium yapma/kaldırma, profil ve premium ekranında gösterim tamamlandı. (2024-07-15)
- [x] AI asistanı referanslı cevap ve kaynak filtreleme: source_filter parametresi ile API ve UI'da kaynak seçimi aktif. (2024-07-15)
- [x] Journey modüllerinde kullanıcı ilerlemesi ve zengin içerik: ilerleme barı, API'den ilerleme çekme/güncelleme, UI'da gösterim tamamlandı. (2024-07-15)
- [x] Onboarding ekranı: 3 sayfalı, özel illüstrasyonlu, renk paletli, butonlu ve persistent onboarding akışı eklendi. (2024-07-17)
- [x] Çıkış Yap (Logout): Profil ekranının en altına modern, kırmızı ve geniş Çıkış Yap butonu eklendi. Tüm oturum verileri temizleniyor ve login ekranına yönlendiriyor. (2024-07-17)
- [x] UI/UX iyileştirmeleri: Ana sayfa, profil ve kartlar Material 3, Inter font, modern kart/buton stilleri ve profesyonel renk paletiyle güncellendi. (2024-07-17)
- [x] Onboarding ekranı manuel test için ana sayfaya geçici buton eklendi. (2024-07-17)
- [x] Flutter frontend'de overflow/taşma hatası giderildi, ana sayfa tekrar kaydırılabilir hale getirildi. (2024-07-17)
- [x] Hadis AI entegrasyonu: Fine-tuned model altyapısı, hibrit AI mantığı (Hadis AI + Gemini geri dönüş), AI kaynak takibi, güven skoru sistemi ve Flutter UI güncellemeleri tamamlandı. (2024-12-19)

## Yapılacaklar
- [ ] Yayınlama ve dağıtım (App Store, Google Play, Web)
- [ ] Test altyapısı ve CI/CD entegrasyonu
- [ ] Vektör veritabanı ve kaynak yükleme
- [ ] Premium üyelik ve ödeme altyapısı (canlı ödeme entegrasyonu)
- [ ] Uygulama içi bildirimler ve kişiselleştirme (gelişmiş)
- [ ] Dışa aktarma (CSV/Excel, raporlar)

## Devam Edenler
- [ ] Admin panelinin genişletilmesi (kitaplık ve journey içerik yönetimi, toplu silme/güncelleme, dışa aktarma)
- [ ] Local notification/alarma (flutter_local_notifications) ile namaz vakti ve özel günler için bildirim/hatırlatıcı altyapısı kurulumu ve test bildirimi (izin, gösterim)

---

> **Not:** Yol haritası ve ilerleme ile ilgili detaylar için [bkz: prompt/CONTEXT_OVERVIEW.md > Yol Haritası ve Durum]. Diğer md dosyalarında tekrar veya bağlam kaybı tespit edilirse, bu dosyaya referans verilerek sadeleştirilmelidir.