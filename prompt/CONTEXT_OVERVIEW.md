# CONTEXT_OVERVIEW.md (prompt/ klasörü)

> **Not:** Bu dosya, context engine ve LLM tabanlı araçlar için projenin merkezi ve tekil bağlam kaynağıdır. Tüm önemli proje bağlamı, dosya yapısı, veri modelleri, mimari ve kurallar burada tutulur. Diğer md dosyaları için referans noktasıdır.

# Proje Context Overview (Tekil Bağlam Kaynağı)

Bu dosya, projenin tüm kritik bağlamını, dosya yapısını, veri modellerini, mimariyi, kuralları ve referansları tek bir yerde toplar. Diğer md dosyalarına referans verir ve tekrarları önler.

---

## 1. Proje Amacı ve Kullanım Senaryosu
- **Amaç:** Dijital çağda güvenilir İslami bilgiye erişim için modern, kaynak referanslı bir mobil uygulama sunmak.
- **Kullanıcılar:** Herkes (özellikle güvenilir dini bilgi arayanlar)
- **Senaryolar:** Namaz vakti bildirimi, AI asistanı ile kaynaklı dini soru-cevap, kitaplık, ilim yolculukları, premium üyelik.

---

## 2. Mimari ve Teknolojiler
- **Frontend:** Flutter (Dart) (`islami_app_new/` ANA frontend)
- **Backend:** FastAPI (Python)
- **Veritabanı:** PostgreSQL
- **AI:** OpenAI GPT-4 veya Google Gemini Pro, RAG (vektör veritabanı)
- **State Management:** Provider/Riverpod
- **Tasarım:** Figma, modern/minimalist UI
- [Detay: README.md > Mimari](README.md)

---

## 3. Dosya ve Modül Yapısı (Tekil Kaynak)
- **Kök Dizin:**
  - README.MD: Proje genel tanımı, kurulum, yol haritası
  - prompt/: Tüm context engine md dosyaları (CONTEXT_OVERVIEW.md, PROJECT_STRUCTURE.md, DATABASE.md, API_DOCS.md, PROGRESS.md, CHANGELOG.md, CONTRIBUTING.md)
  - backend/: FastAPI backend kodları, modeller, migration, testler
    - main.py, models.py, auth.py, database.py, vector_search.py, embedding_utils.py, hadith_loader.py, add_sample_data.py, requirements.txt, .env, tests/, venv/
  - islami_app_new/: Flutter frontend kodları (ANA frontend)
    - pubspec.yaml, pubspec.lock, assets/, lib/, test/, android/, ios/, macos/, linux/, windows/, web/
      - lib/main.dart, lib/screens/ (home_screen.dart, profile_screen.dart, ...)
      - assets/.env, assets/turkey_cities.json
      - test/widget_test.dart
      - web/index.html, web/manifest.json, web/icons/
      - android/app/build.gradle.kts, android/app/src/
  - islami_app/: ❗UYARI: Bu klasör eski, silinecek! (Kullanmayın, islami_app_new/ kullanılmalı)
  - alembic/: Migration dosyaları
  - alembic.ini: Alembic ayar dosyası
  - drop_all.sql: Veritabanı sıfırlama scripti
  - .github/: CI/CD ve issue/pr şablonları
  - .venv/: Sanal ortam
  - .vscode/: VSCode ayarları
  - android/: (Kökteki, Flutter dışı Android ayarları)
  - index.html, İslami App-2.1.pptx: Kökteki diğer dosyalar
- [Detay: PROJECT_STRUCTURE.md]

---

## 4. Veri Modelleri ve Database Akışı
- **Ana Modeller:** Kullanıcı, Hadis, Dua, Zikir, Journey, Favori, Geçmiş
- **Migration/Seed:** Alembic veya manuel scriptler
- **Toplu Veri Yükleme:** hadith_loader.py, embedding_utils.py
- [Detay: backend/models.py, PROJECT_STRUCTURE.md > Backend]

---

## 5. API ve Akışlar
- **Ana Endpointler:** /api/ask, /api/sources, /user/favorites, /admin/user/premium
- **Kimlik Doğrulama:** JWT
- **Referans:** [README.md > API Endpointleri], [API_DOCS.md] (varsa)

---

## 6. Ortak Kurallar, Standartlar, Yasaklar
- **Hassas veriler .env dosyasında tutulur, kodda sabit bağlantı yok.**
- **Frontend .env sadece ortam değişkeni, asla secret içermez.**
- **Tek .env: backend/ ve islami_app_new/ kökünde.**
- **Kodlama standartları:** Python için PEP8, Dart için Dart Style Guide
- **Kaynak gösterme zorunluluğu (AI asistanı):** Her bilgiye referans
- **Yasaklar:**
  - Aynı bilgi birden fazla yerde farklı şekilde anlatılamaz
  - Hassas veri kodda/logda tutulamaz
  - Placeholder/tekrarlı ekranlardan kaçınılır
- [Detay: CONTRIBUTING.md]

---

## 7. Yol Haritası ve Durum
- **Güncel ilerleme ve yapılacaklar:** [PROGRESS.md]
- **Sürüm notları:** [CHANGELOG.md]

---

## 8. Katkı ve Geliştirme Standartları
- **PR/Issue açma, kodlama, test ekleme:** [CONTRIBUTING.md]
- **Lisans:** MIT ([LICENSE])

---

## 9. Bağlamsal Linkler ve Referanslar
- Her dosya, modül ve veri modeli için detaylı açıklama ve bağlantılar [PROJECT_STRUCTURE.md] ve ilgili dosyalarda tutulur.
- API endpointleri ve veri modelleri için tekil kaynaklar kullanılmalı, tekrar eden açıklamalar kaldırılmalı.

---

> **Not:** Bu dosya, context engine, RAG veya LLM tabanlı asistanlar için _tekil ve güncel_ bağlam kaynağı olarak kullanılmalıdır. Diğer md dosyalarında tekrar veya bağlam kaybı tespit edilirse, bu dosyaya referans verilerek sadeleştirilmelidir. 

- **Kitaplıkta Sesli Okuma:** Kullanıcı profilinde belirlediği sesli okuma ayarları (dil, hız, ton, ses) kitaplıkta otomatik uygulanır. Ayarlar SharedPreferences ile saklanır ve kitaplık ekranında flutter_tts ile doğrudan kullanılır.
- **Google Cloud TTS:** Tüm kod ve bağımlılıklar kaldırıldı. Sadece cihazdaki flutter_tts kullanılmaktadır.
- **Profilde Sesli Okuma Ayarları:** Kullanıcı, profil ekranında sesli okuma ayarlarını (dil, hız, ton, ses) değiştirebilir ve 'Kaydet' butonuyla manuel olarak da kaydedebilir. Değişiklikler anında ve manuel olarak saklanır.
- Tüm değişiklikler context engine ve md dosyalarında güncel tutulur, tekrar veya eski bilgi tespit edilirse bu dosya referans alınarak revize edilir. 
- **Kıble Pusulası:** Ana sayfada modern ve profesyonel bir kıble pusulası (QiblaCompassScreen) eklendi. Kullanıcı konumunu ve cihaz pusulasını kullanarak Kâbe yönünü otomatik ve canlı olarak gösterir. Gradient arka plan, merkezde Kâbe simgesi, yön harfleri ve responsive oklar ile profesyonel bir UI sunar. Dosya: islami_app_new/lib/screens/qibla_compass_screen.dart
- **Performans İyileştirmeleri:**
  - Ana thread’i yoran işlemler (profil, .env, TTS, konum) optimize edilmeli, splash sonrası veya arka planda başlatılmalı.
  - initState içinde ağır işlemler paralel/asenkron başlatılmalı (Future.microtask, Future.delayed, Future.wait).
  - SplashScreen ile profil doğrulaması ve yönlendirme yapılmalı.
  - TTS ve konum servisleri build sırasında değil, kullanıcı etkileşimiyle veya arka planda yüklenmeli.
  - build.gradle dosyasında Java 17+ kullanılmalı.
- **Dosya Yapısı Güncellemesi:**
  - islami_app_new/lib/screens/qibla_compass_screen.dart: Kıble pusulası ekranı
  - Ana sayfa (home_screen.dart): Kıble pusulası butonu ve yönlendirme 
- **SplashScreen ve Açılış Optimizasyonu:** Uygulama açılışında profesyonel bir SplashScreen (logo + yükleniyor animasyonu) gösterilir. Ağır işlemler (env, bildirim, profil, TTS, konum) splash sonrası arka planda başlatılır. Kullanıcıya hızlı ve akıcı bir ilk izlenim sunulur. Dosya: islami_app_new/lib/main.dart 

---

## 10. Son Gelişmeler ve Özellikler (2024)

- **Kur'an-ı Kerim Ekranı:**
  - Her ayetin yanında iki buton: 'Sesli Oku' (🔊) ve 'Sırayla Oku' (🎵).
  - 'Sesli Oku' sadece ilgili ayetin ses dosyasını çalar ve highlight yapar.
  - 'Sırayla Oku' tıklanan ayetten başlayarak ilgili surenin tüm ayetlerini sırayla, highlight ve otomatik scroll ile okur. Okuma sırasında kullanıcı isterse durdurabilir.
  - Okuyucu (reciter) listesi güncellendi, eksik/bozuk ses dosyası olanlar temizleniyor.
- **Backend:**
  - /api/quran endpoint'inde audio_url alanı, her ayet için dinamik olarak seçilen reciter ve ayet numarasına göre üretiliyor. Veritabanında statik audio_url tutulmuyor.
- **Genel:**
  - Tüm bu işlevler modern, profesyonel ve sürdürülebilir şekilde Flutter + FastAPI mimarisinde uygulanmıştır. 

---

## 11. Tags Alanı ve Arama İyileştirmeleri (2024 Temmuz)

### Kısa Vadeli Hızlı Çözüm
- Hadis arama fonksiyonunda tags alanı JSON string olarak tutuluyorsa, arama sırasında JSON parse edilerek her bir tag tek tek kontrol edilir.
- Kategori, topic ve metin alanlarında da case-insensitive arama yapılır.
- Bu sayede, örneğin "iman" etiketiyle arama yapıldığında ilgili tüm hadisler döner ve "daha açık yaz" gibi gereksiz cevaplar ortadan kalkar.

### Uzun Vadeli Yapılacaklar
- **tags** alanı PostgreSQL `text[]` array tipine veya ayrı bir ilişki tablosuna taşınacak.
- Tüm veri yükleme ve arama kodu buna göre güncellenecek.
- Eski veriler yeni yapıya migrate edilecek.
- Kodda arama ve filtreleme native array veya join ile yapılacak.
- Geçiş sonrası test ve performans ölçümü yapılacak.
- Bu değişiklik, büyük veri ve çoklu tag aramalarında ciddi performans ve esneklik avantajı sağlar. 