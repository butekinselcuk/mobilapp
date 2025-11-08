# Proje Adı: İslami App

## Kurulum ve Çalıştırma Talimatları

### Gereksinimler
- Flutter (https://docs.flutter.dev/get-started/install)
- Python 3.10+ (https://www.python.org/downloads/)
- pip (Python paket yöneticisi)
- (Opsiyonel) PostgreSQL (veritabanı için)

### Hızlı Başlangıç

#### Backend Çalıştırma
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
cp .env.example .env  # .env dosyasını düzenleyin
python main.py
```

#### Frontend Çalıştırma
```bash
cd islami_app_new
flutter pub get
flutter run
```

## Veritabanı Backup ve Restore

### Veritabanı Backup Alma

#### Otomatik Backup (Önerilen)
```bash
# Tam backup (tüm dosyalar dahil)
python backup_database.py

# Belirli klasöre backup
python backup_database.py --output-dir ./my_backups

# Sadece tablo yapıları
python backup_database.py --tables-only

# Sadece veriler
python backup_database.py --data-only
```

#### Manuel PostgreSQL Backup
```bash
# Tam veritabanı backup
pg_dump -h localhost -U postgres -d imanapp -f database_backup_full.sql

# Sadece şema
pg_dump -h localhost -U postgres -d imanapp --schema-only -f schema_backup.sql

# Sadece veri
pg_dump -h localhost -U postgres -d imanapp --data-only -f data_backup.sql

# Belirli tabloları backup alma
pg_dump -h localhost -U postgres -d imanapp -t users -t hadiths -f specific_tables.sql
```

### Veritabanı Restore Etme

#### Otomatik Restore (Önerilen)
```bash
# Backup klasöründen restore
python restore_database.py --backup-dir ./database_backups/backup_20250127_143000

# Tek SQL dosyasından restore
python restore_database.py --sql-file ./database_backup.sql

# Yeni veritabanı oluşturarak restore
python restore_database.py --backup-dir ./backups --create-db
```

#### Manuel PostgreSQL Restore
```bash
# Yeni veritabanı oluştur
createdb -h localhost -U postgres imanapp

# SQL dosyasını restore et
psql -h localhost -U postgres -d imanapp -f database_backup_full.sql

# Alembic migrations çalıştır
cd backend
alembic upgrade head

# CSV verilerini yükle
python hadith_loader.py hadith_big_example.csv
```

### Backup Dosyaları

Proje içinde aşağıdaki backup dosyaları bulunmaktadır:

- `database_backup.sql` - Tam veritabanı şeması ve örnek veriler
- `backup_database.py` - Otomatik backup scripti
- `restore_database.py` - Otomatik restore scripti
- `backend/hadith_big_example.csv` - Hadis verileri
- `backend/hadith_example.csv` - Örnek hadis verileri
- `backend/journey_module_example.csv` - Yolculuk modülü verileri
- `reciters_inserts.sql` - Kur'an okuyucuları verileri
- `duzgun.csv` - Düzenlenmiş hadis verileri
- `alembic/versions/` - Veritabanı migration dosyaları

### 1. Depoyu Klonlayın
```bash
git clone <repo-link>
cd islami_app
```

### 2. Backend (FastAPI) Kurulumu ve Çalıştırma

#### a) Backend Dizinine Geçin
```bash
cd backend
```

#### b) Sanal Ortam Oluşturun ve Aktif Edin
```bash
# Sanal ortam oluştur
python -m venv venv

# Windows için aktif et:
venv\Scripts\activate

# Mac/Linux için aktif et:
source venv/bin/activate
```

#### c) Bağımlılıkları Yükleyin
```bash
pip install -r requirements.txt
```

#### d) Ortam Değişkenleri
Bir `.env` dosyası oluşturun ve gerekli anahtarları ekleyin:
```env
OPENAI_API_KEY=your_openai_api_key_here
DATABASE_URL=postgresql://kullanici:sifre@localhost:5432/islami_app
SECRET_KEY=your_secret_key_here
```

#### e) Backend Sunucusunu Başlatın
```bash
# Geliştirme modu (otomatik yeniden başlatma)
uvicorn main:app --reload

# Veya belirli port ile
uvicorn main:app --reload --port 8000
```

Backend başarıyla başlatıldığında `http://localhost:8000` adresinde çalışacaktır.

### 3. Frontend (Flutter) Kurulumu ve Çalıştırma

#### a) Flutter Dizinine Geçin
```bash
cd islami_app_new  # Flutter proje dizini
```

#### b) Bağımlılıkları Yükleyin
```bash
flutter pub get
```

#### c) Uygulamayı Çalıştırın
```bash
# Android/iOS emülatör veya fiziksel cihaz için
flutter run

# Web tarayıcısı için
flutter run -d chrome

# Belirli cihaz için
flutter devices  # Mevcut cihazları listele
flutter run -d [device_id]
```

#### Notlar
- Android/iOS için ek kurulumlar ve izinler gerekebilir (bkz: Flutter dokümantasyonu)
- Geliştirme sırasında hot reload özelliği aktiftir
- Backend sunucusunun çalışır durumda olduğundan emin olun

---

## 1. Proje Özeti ve Temel Amaç

**Ana Hedef:** Dijital çağda Müslümanların karşılaştığı bilgi kirliliği ve kaynak güvensizliği sorunlarına çözüm olarak, Kur'an ve Sünnet'i temel alan, güvenilir, tarafsız ve bütüncül bir İslami mobil uygulama geliştirmek.

**Temel Çözüm:** Kullanıcıların dini sorularına, yalnızca güvenilir kaynaklara (Kur'an, Kütüb-i Sitte vb.) dayanarak, yorum katmadan ve **mutlaka kaynak belirterek** cevap veren bir yapay zeka (AI) asistanı oluşturmak. Bu asistanın yanı sıra, kullanıcıların günlük ibadet ve manevi gelişim ihtiyaçlarını karşılayacak kapsamlı bir deneyim sunmak.

## 2. Kullanılacak Teknolojiler ve Mimari

* **Mobil Uygulama (Frontend):**
    * **Framework:** **Flutter**. Tek kod tabanı ile hem iOS hem de Android için yüksek performanslı ve estetik arayüzler sunması sebebiyle tercih edilmelidir.
    * **Dil:** Dart.
    * **State Management:** Provider veya Riverpod.
* **Sunucu (Backend):**
    * **Dil & Framework:** **Python** ile **Django** veya **FastAPI**. Yapay zeka entegrasyonu ve veri işleme kabiliyetleri için Python en uygun seçenektir.
    * **Veritabanı:** **PostgreSQL**. İlişkisel ve yapılandırılmış İslami veriler (ayetler, hadisler, raviler vb.) için güçlü ve ölçeklenebilir bir çözüm.
* **Yapay Zeka (AI) Asistanı:**
    * **Dil Modeli (LLM):** **OpenAI GPT-4** veya **Google Gemini Pro** API'ları kullanılacak.
    * **Veri Altyapısı (RAG - Retrieval-Augmented Generation):** AI modelinin sadece bizim sağladığımız güvenilir kaynaklardan beslenmesi için bir **Vektör Veritabanı** (örn: Pinecone, ChromaDB) kurulacak. Kur'an mealleri, tefsirler ve Kütüb-i Sitte gibi temel hadis kaynakları bu veritabanına işlenecek.
* **Tasarım (UI/UX):**
    * **Tasarım Aracı:** **Figma**. Sunumdaki görseller temel alınarak geliştirilecek.
    * **Tasarım Dili:** Modern, minimalist, temiz ve sakinleştirici.
    * **Renk Paleti:** Beyaz ve açık gri tonları (arka planlar), sakin bir yeşil (vurgu rengi, butonlar), koyu gri/siyah (metinler).
    * **Tipografi:** Okunabilirliği yüksek, modern ve sans-serif bir font ailesi (örn: Inter, Poppins).

## 3. Detaylı Uygulama Özellikleri ve Ekran Tasarımları

### 3.1. Ana Sayfa (Home Screen)

* **Yapı:** Dikey olarak kaydırılabilen, kart tabanlı modüler bir yapı.
* **Üst Kısım: Namaz Vakitleri Kartı**
    * Kullanıcının konumuna göre (otomatik veya manuel) **İstanbul** gibi şehir adı gösterilir.
    * Miladi ve Hicri takvim bilgisi (Örn: 20 Mart 2025 / 20 Ramazan 1446).
    * **İMSAK, GÜNEŞ, ÖĞLE** gibi vakit isimleri ve saatleri (05:31, 06:19, 13:19).
    * En yakın vakte ne kadar kaldığını gösteren **canlı bir geri sayım sayacı** (Örn: ÖĞLEN'e 00:23:44). Bu sayaç belirgin ve odak noktasında olmalı.
    * **Namaz vakti bildirimleri:** Kullanıcı profil ekranından her vakit için “kaç dakika önce” bildirim almak istediğini seçebilir. Bildirimler flutter_local_notifications 19.x ve timezone ile şehir bazlı, tam zamanında ve güvenilir şekilde gelir.
* **Orta Kısım: AI Asistan Kartı**
    * Dikkat çekici bir başlık: "Yapay zekaya sor...".
    * İçinde bir arama ikonu ve "Neye ihtiyacın var?" gibi bir placeholder metin bulunan bir arama çubuğu.
    * Arama çubuğunun altında, kullanıcıyı yönlendiren dönen slaytlar (carousel) şeklinde örnek sorular veya konular gösterilebilir. (Örn: [Ayasofya Camii resmi] "Namazın şartları nelerdir?").
* **Hızlı Erişim Butonları:**
    * "Kur'an Oku", "Hadis", "Dua" gibi ikonlu ve metinli, yan yana duran butonlar.
* **İlim Yolculukları Kartı:**
    * Başlık: "İlim Yolculukları".
    * İçerik: "Siyer-i Nebi" ve "Hac ve Umre" gibi rehberli modüllere yönlendiren, görselli butonlar.
* **Kaldığın Yerden Devam Et Kartı:**
    * Başlık: "Kaldığın yerden devam et".
    * İçerik: Kullanıcının en son okuduğu sureyi, zikri veya ilim yolculuğunu gösteren bir ilerleme çubuğu (Örn: "Zikir çekmeye devam et > %64").
* **Özel Günler Kartı:**
    * Başlık: "Hicri Takvim".
    * İçerik: Yaklaşan önemli dini gün ve geceyi gösteren bir kart (Örn: [Kabe resmi] "1 Şevval 2025 - Ramazan Bayramı - Yarın").

### 3.2. AI Asistanı Ekranı (Chat Arayüzü)

* **Tasarım:** Modern bir mesajlaşma uygulaması gibi.
* **Üst Bar:** "Asistan" başlığı.
* **Sohbet Akışı:**
    * Kullanıcının sorusu sağda, asistanın cevabı solda hizalı olarak gösterilir.
    * **Asistanın Cevap Formatı (ÇOK ÖNEMLİ):**
        1.  **Net Başlangıç:** Soruya mümkünse "Evet," veya "Hayır," gibi net bir ifadeyle başlanır.
        2.  **Açıklama:** Ardından detaylı açıklama yapılır.
        3.  **Satır İçi Referans:** Cevap içindeki her bilgi, anında parantez içinde kaynağıyla belirtilmelidir. **Örnek:** "...bu durumda oruç bozulmaz **(el-Fetâva'l-Hindiyye, 1/202)**. Peygamber Efendimiz'in de misvak kullanımı konusunda tavsiyeleri bulunmaktadır **(Tirmizî, "Savm", 29)**."
* **Alt Kısım (Metin Girişi):**
    * "Yapay zekaya sor..." placeholder metni olan bir metin giriş alanı.
    * Gönder butonu.
    * **Filtreleme İkonu:** Kullanıcının, cevabın sadece "Kur'an", "Hadis" veya "Tüm Kaynaklar" temel alınarak verilmesini seçebileceği bir filtreleme menüsü açan bir ikon.
* **Ek Özellikler:**
    * **Paylaş Butonu:** Cevap baloncuğunun yanında, cevabı şık bir görsel karta dönüştürerek paylaşma imkanı sunan bir paylaş ikonu.
    * **İlgili Konular:** Cevabın altında, kullanıcıyı konuyu derinlemesine inceleyebileceği "İlim Yolculukları" modüllerine veya ilgili ayet/hadis listelerine yönlendiren butonlar.

### 3.3. Alt Navigasyon Barı (Bottom Navigation Bar)

Uygulamanın her zaman altında sabit duracak, 5 ikonlu bir bar:

1.  **Ana Sayfa (Ev ikonu):** Aktif olduğunda vurgulu.
2.  **Kitaplık (Açık kitap ikonu):** Kur'an, Hadis vb. kaynakların listelendiği ekran.
3.  **Asistan (Yıldız veya robot ikonu):** AI Asistanı sohbet ekranını açar. Ortada ve daha belirgin olabilir.
4.  **İlim Yolculukları (Liste/pusula ikonu):** Tüm rehberli modüllerin listelendiği ekran.
5.  **Profil (Kişi ikonu):** Kullanıcı profili, ayarlar, kaydedilenler ve bildirim ayarları.

### 3.4. İlim Yolculukları (Journey) Ekranı
* Etiket ile filtreleme: Kullanıcı, etiket kutusuna yazarak modülleri filtreleyebilir. Arama sonrası input silinmez, boş aramada tüm modüller listelenir.

## 4. Yapay Zeka (AI) Asistanının Mantığı ve Sistem Prompt'u

Bu, projenin en kritik kısmıdır. Backend'de LLM API'sine gönderilecek olan **sistem prompt'u** şu kuralları içermelidir:


"Sen, 'İslami App' uygulamasının yardımsever ve güvenilir bir yapay zeka asistanısın. Görevin, sana sağlanan ve güvenilirliği onaylanmış İslami kaynaklar (Kur'an, Kütüb-i Sitte, temel fıkıh ve tefsir metinleri) dışında KESİNLİKLE bilgi vermemektir.

KURALLARIN:

YORUM YAPMA: Asla kişisel görüş, yorum veya çıkarım belirtme. Sadece kaynaklarda ne yazıyorsa onu aktar.

KAYNAK GÖSTER: Verdiğin her bilgi için, cümlenin hemen sonunda parantez içinde kaynak belirt. Örnek: (Bakara, 2:183), (Buhari, İman, 1), (el-Fetâva'l-Hindiyye, 1/202). Kaynağı belirsiz bilgi verme.

NET OL: Cevaplarına mümkünse 'Evet' veya 'Hayır' gibi net ifadelerle başla, ardından açıklamayı yap.

BİLGİ DIŞINA ÇIKMA: Eğer bir soru, sana sunulan bilgi kaynaklarının dışındaysa veya modern/tartışmalı bir konuysa, 'Bu konuda kaynaklarımda net bir bilgi bulunmamaktadır.' şeklinde cevap ver. Asla tahmin yürütme.

SAYGILI OL: Her zaman saygılı, alçakgönüllü ve yardımcı bir dil kullan."


## 5. Gelir Modeli ve Uygulama İçi Satın Alma

* **Freemium Yapı:**
    * **Ücretsiz Sürüm:** Tüm temel özellikler (namaz vakitleri, sınırlı sayıda AI sorgusu/gün, reklam gösterimi) ücretsiz olacak.
    * **Premium Sürüm (Abonelik):**
        * Reklamsız deneyim.
        * Sınırsız AI sorgu hakkı.
        * Cevapları ve notları bulutta saklama/kişisel çalışma alanı.
        * Gelişmiş arama ve filtreleme.
        * Premium üyelik, uygulama içinden aylık veya yıllık abonelikle satın alınabilecek.

## Katkı Sağlamak (Contributing)

Projeye katkı sağlamak isteyen herkese açığız! Katkı sağlamak için lütfen aşağıdaki adımları takip edin:

1. Fork'layın ve kendi dalınızı oluşturun (`feature/ozellik-adi` gibi).
2. Değişikliklerinizi yapın ve test edin.
3. Açık ve açıklayıcı commit mesajları kullanın.
4. Pull Request (PR) açın ve yapılan değişiklikleri özetleyin.
5. Kod incelemesi ve geri bildirimler için iletişime açık olun.

Kodlama Standartları:
- Temiz, okunabilir ve yorum satırı eklenmiş kod yazmaya özen gösterin.
- Python için PEP8, Dart için Dart Style Guide'a uyun.
- Test eklemeyi unutmayın.

Daha fazla detay için lütfen [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını inceleyin.

İletişim: PR veya issue üzerinden sorularınızı iletebilirsiniz.

---

## Testler ve Kalite Güvencesi

### Backend (Python)
- Testler için genellikle `pytest` veya `unittest` kullanılabilir.
- Testleri çalıştırmak için:

```bash
cd backend
# Sanal ortamı aktif edin
pytest
```

- Test dosyaları `tests/` klasöründe veya ilgili modüllerin yanında bulunmalıdır.

### Frontend (Flutter)
- Flutter projelerinde testler `test/` klasöründe yer alır.
- Widget ve birim testlerini çalıştırmak için:

```bash
cd islami_app
flutter test
```

- Daha fazla bilgi için: [Flutter Testing Docs](https://docs.flutter.dev/testing)

Test eklemeyi ve mevcut testleri güncel tutmayı unutmayın!

---

## Lisans

Bu proje MIT Lisansı ile lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasını inceleyebilirsiniz.

---

## AI Asistanı Veri Kaynakları ve API Endpointleri

### Veri Kaynakları
- Kur'an mealleri ve tefsirleri
- Kütüb-i Sitte (Buhari, Müslim, Tirmizi, Ebu Davud, Nesai, İbn Mace)
- Temel fıkıh ve tefsir metinleri
- Güvenilir İslami kaynaklar (kaynak listesi ve formatı için docs klasörüne bakınız)

Veriler vektör veritabanında (örn: Pinecone, ChromaDB) tutulur ve sadece bu kaynaklardan bilgi çekilir.

### API Endpoint Örnekleri

#### 1. Soru Sorma (AI Asistanı)
- **Endpoint:** `/api/ask`
- **Yöntem:** `POST`
- **İstek Gövdesi:**
```json
{
  "question": "Oruçluyken misvak kullanılır mı?",
  "source_filter": "all" // "quran", "hadis", "all"
}
```
- **Yanıt:**
```json
{
  "answer": "Evet, oruçluyken misvak kullanmak caizdir. (Tirmizî, Savm, 29)",
  "sources": [
    { "type": "hadis", "ref": "Tirmizî, Savm, 29" }
  ]
}
```

#### 2. Kaynak Listesi
- **Endpoint:** `/api/sources`
- **Yöntem:** `GET`
- **Yanıt:**
```json
[
  { "type": "quran", "name": "Kur'an-ı Kerim" },
  { "type": "hadis", "name": "Buhari" },
  ...
]
```

#### Kimlik Doğrulama
- API anahtarı veya JWT ile kimlik doğrulama gerektirebilir.

Daha fazla teknik detay ve örnekler için backend dokümantasyonuna bakınız.

---

## Ekran Görüntüleri ve Demo

Aşağıda uygulamanın temel ekranlarına ait örnek görselleri ve (varsa) kısa bir demo videosunu bulabilirsiniz:

### Ana Sayfa
![Ana Sayfa](docs/screenshots/home.png)

### AI Asistanı Ekranı
![AI Asistanı](docs/screenshots/assistant.png)

### İlim Yolculukları
![İlim Yolculukları](docs/screenshots/journey.png)

### Demo Video
[Demo Videosunu İzle](docs/demo/demo.mp4)

> Not: Görselleri ve demo videosunu `docs/screenshots/` ve `docs/demo/` klasörlerine ekleyebilirsiniz.

---

## Yol Haritası ve Sürüm Notları

### Yol Haritası (Roadmap)
- [x] Proje temel mimarisi ve dokümantasyon
- [x] Journey adımlarında Youtube video oynatıcı entegrasyonu (web ve mobil platform ayrımı, overflow hatası çözümü)
- [x] Journey modüllerine etiketle filtreleme ve arama akışı başarıyla tamamlandı. Kullanıcı arayüzünde arama sonrası input silinmiyor, boş aramada tüm modüller geliyor. (2024-07-11)
- [x] Ana sayfa kartlarında konumdan otomatik şehir tespiti ve canlı namaz vakitleri entegrasyonu başarıyla tamamlandı. Kullanıcıdan konum izni isteniyor, en yakın şehir bulunup API'den canlı vakitler çekiliyor. (2024-07-11)
- [x] Kitaplık ekranında Kur’an, Hadis, Dua, Zikir, Tefsir içeriklerinin listelenmesi ve detay ekranları modern UI ile tamamlandı. (2024-07-14)
- [x] Kitaplık ekranı temel iskelet ve veri modeli, API ile canlı veri, kategori kartları, detay modalı, paylaş/kopyala/TTS, erişilebilirlik ve örnek veri yükleme tamamlandı. (2024-07-14)
- [x] Ana sayfa kartları ve hızlı erişim butonları modernleştirildi, yönlendirme fonksiyonları ve canlı veri entegrasyonu tamamlandı. (2024-07-14)
- [x] Journey modüllerinde etiketle filtreleme, arama, modern UI, Youtube video oynatıcı, drag & drop, CSV ile toplu yükleme tamamlandı. (2024-07-13)
- [x] Favoriler, geçmiş, premium, profil, JWT, paylaş/kopyala, toplu silme, gelişmiş arama/filtreleme gibi tüm kullanıcı akışları eksiksiz ve modern UI/UX ile tamamlandı. (2024-07-11)
- [x] Dua metni okutma (TTS/text-to-speech) özelliği, gelişmiş kontroller ve erişilebilirlik ile kitaplık/dua detayında aktif. (2024-07-15)
- [x] Namaz vakti bildirim altyapısı ve profil ekranı entegrasyonu: flutter_local_notifications 19.x ile timezone uyumlu, şehir bazlı, kullanıcıya özel dakika seçimiyle tam entegre çalışıyor. (2024-07-16)
- [x] Premium üyelik akışı ve avantajlar: demo aktivasyon, avantajlar, premium bitiş tarihi, admin panelinden premium yapma/kaldırma, profil ve premium ekranında gösterim tamamlandı. (2024-07-15)
- [x] AI asistanı referanslı cevap ve kaynak filtreleme: source_filter parametresi ile API ve UI'da kaynak seçimi aktif. (2024-07-15)
- [x] Journey modüllerinde kullanıcı ilerlemesi ve zengin içerik: ilerleme barı, API'den ilerleme çekme/güncelleme, UI'da gösterim tamamlandı. (2024-07-15)

- [ ] Yayınlama ve dağıtım (App Store, Google Play, Web)
- [ ] Test altyapısı ve CI/CD entegrasyonu
- [ ] Vektör veritabanı ve kaynak yükleme
- [ ] Premium üyelik ve ödeme altyapısı (canlı ödeme entegrasyonu)
- [ ] Uygulama içi bildirimler ve kişiselleştirme (gelişmiş)
- [ ] Dışa aktarma (CSV/Excel, raporlar)

### Sürüm Notları (Changelog)
Tüm güncellemeler ve değişiklikler için [CHANGELOG.md](CHANGELOG.md) dosyasını inceleyebilirsiniz.

---

## Sıkça Sorulan Sorular (SSS)

### Uygulamayı kimler kullanabilir?
Herkes ücretsiz olarak temel özellikleri kullanabilir. Premium özellikler için abonelik gereklidir.

### AI asistanı hangi kaynaklardan bilgi verir?
Sadece güvenilir İslami kaynaklardan (Kur'an, Kütüb-i Sitte, temel fıkıh ve tefsir metinleri) bilgi verir. Kaynak dışı bilgi sunmaz.

### Katkı sağlamak için ne yapmalıyım?
README ve CONTRIBUTING.md dosyalarını inceleyip, PR veya issue açabilirsiniz.

### Uygulama verilerim güvende mi?
Kullanıcı verileri gizlilik ve güvenlik standartlarına uygun şekilde saklanır. Detaylar için ileride gizlilik politikası eklenecektir.

### Hangi platformlarda çalışır?
Android, iOS ve Web platformlarında çalışacak şekilde tasarlanmıştır.

Daha fazla soru için issue açabilir veya iletişime geçebilirsiniz.

---

## Önemli Dosyalar ve Modüller

- **backend/main.py**: FastAPI ana uygulama dosyası, API endpointleri, JWT, CORS, tablo oluşturma, AI entegrasyonu.
- **backend/vector_search.py**: Embedding tabanlı vektör arama, cosine similarity, sadece SQL’den hadis döndürür.
- **backend/embedding_utils.py**: Metinlerden embedding üretir, tüm hadislerin embedding alanını günceller.
- **islami_app/lib/screens/user_data_screen.dart**: Profil, geçmiş ve favoriler ekranı, JWT ile API iletişimi.
- **islami_app/lib/screens/login_screen.dart**: Kullanıcı login işlemi, JWT token kaydı.

## Tamamlanan Kritik Akışlar

- Asistan, sadece SQL’deki hadislerden vektör arama ile sonuç döndürüyor.
- Geçmiş kaydına hadith_id eksiksiz yazılıyor.
- Favori ekleme/çıkarma JWT ile güvenli şekilde çalışıyor.
- Favoriler sekmesi async SQLAlchemy ile hatasız, hızlı ve eksiksiz çalışıyor (selectinload ile).
- Tüm JWT ve oturum yönetimi Flutter’da güvenli şekilde sağlandı.
- Tüm akışlar uçtan uca test edildi ve doğrulandı.
- Geçmiş ve favoriler sekmesinde arama ve sıralama state'leri ayrıldı, UI güncellendi. (2024-07-10)
- Aynı hadisi tekrar favorilere ekleme engellendi, backend ve frontend kontrolü eklendi. (2024-07-10)
- Favori butonu geçmişte ve favorilerde doğru şekilde aktif/pasif gösteriliyor, favoriden çıkarma ve ekleme akışı düzeltildi. (2024-07-10)
- 422 hatası (Unprocessable Entity) düzeltildi, frontend query parametresi ile uyumlu hale getirildi. (2024-07-10)
- Geçmiş ve favori kartlarına modern tasarım, paylaş ve kopyala butonları eklendi. (2024-07-10)
- Paylaş butonu share_plus ile cihaz paylaşım menüsünü açıyor, kopyala panoya kopyalıyor. (2024-07-10)
- Premium/abonelik akışı canlı ödeme entegrasyonuna uygun şekilde kurgulandı. Kullanıcı modeline is_premium ve premium_expiry alanı eklendi. Profil ekranında Premium'a Geç butonu, avantajlar ve demo butonu var. Demo endpointi sadece testte aktif, canlıda gerçek ödeme sonrası premium aktif olacak. (2024-07-10)
- Profil/ayarlar ekranı ve kullanıcı yönetimi akışları (bilgi güncelleme, şifre değiştirme, hesap silme) eksiksiz ve sürdürülebilir şekilde tamamlandı. Tüm API linkleri .env üzerinden okunuyor, kodda sabit bağlantı yok. Çıkış yap butonu kaldırıldı, hesap silindikten sonra login ekranına sorunsuz yönlendirme sağlandı. Testler başarıyla geçti. (2024-07-11)
- Geçmiş ve favorilerde toplu silme (multi-select), gelişmiş arama, filtreleme ve sıralama özellikleri eksiksiz ve modern UI/UX ile tamamlandı. Tüm akışlar uçtan uca test edildi, kullanıcı deneyimi ve veri yönetimi üst düzeye çıkarıldı. (2024-07-11)
- Admin paneli kullanıcı yönetimi bölümünde premium yapma/kaldırma ve kullanıcı silme işlemlerine onay (emin misiniz?) dialogu eklendi. Premium kaldırma özelliği ve tüm işlemlerde yanlışlıkla işlem yapılmasını engelleyen dialoglar eklendi. Backend'de /admin/user/premium endpointi action parametresiyle premium kaldırma desteği aldı. UI/UX ve güvenlik iyileştirildi.
- Journey adımlarında Youtube video oynatıcı entegrasyonu (web ve mobil platform ayrımı, overflow hatası çözümü) başarıyla tamamlandı. Artık Youtube videoları web'de iframe ile, mobilde native player ile sorunsuz oynatılıyor. (2024-07-13)

## Önemli Kod Blokları

### Vektör Arama (backend/vector_search.py)
```python
def cosine_similarity(a, b):
    ...
async def search_hadiths(query: str, top_k: int = 3):
    ...
    scored.sort(key=lambda x: x[1], reverse=True)
    return [h for h, _ in scored[:top_k]]
```

### Favori Hadisleri Eager Loading ile Çekme (main.py)
```python
from sqlalchemy.orm import selectinload
@app.get("/user/favorites")
async def get_user_favorites(...):
    ...
    result = await session.execute(
        select(UserFavoriteHadith)
        .options(selectinload(UserFavoriteHadith.hadith))
        .where(UserFavoriteHadith.user_id == resolved_user_id)
    )
    favs = result.scalars().all()
    return [
        {
            "id": f.hadith.id,
            "text": f.hadith.text,
            ...
        } for f in favs if f.hadith
    ]
```

### Login Sonrası Token Kaydı (login_screen.dart)
```dart
final storage = FlutterSecureStorage();
await prefs.setString('jwt_token', token);
await prefs.setString('flutter_jwt_token', token);
await storage.write(key: 'jwt_token', value: token);
await storage.write(key: 'flutter_jwt_token', value: token);
```

## Toplu Hadis Yükleme ve Embedding Güncelleme Otomasyonu

### 1. CSV Şablonu
Aşağıdaki başlıklarla bir CSV dosyası oluşturun:

```
text,source,reference,category,language
"Ameller niyetlere göredir.","Buhari","Bed'ü'l-Vahy, 1","Niyet","tr"
"İnsanların en hayırlısı insanlara faydalı olandır.","Ebu Davud","Edeb, 120","İyilik","tr"
```

### 2. Toplu Yükleme Adımları
1. CSV dosyasını `backend` klasörüne kopyalayın (örn. `hadith_big_example.csv`).
2. Terminalde backend klasörüne geçin:
   ```bash
   cd backend
   ```
3. Yükleme scriptini çalıştırın:
   ```bash
   python hadith_loader.py hadith_big_example.csv
   ```
4. Embedding alanlarını güncelleyin:
   ```bash
   python embedding_utils.py
   ```

### 3. Notlar
- Embedding alanı boş bırakılmalı, script otomatik doldurur.
- Yükleme ve embedding işlemleri tamamlandığında, arama ve API endpointleriyle yeni veriler kullanılabilir.
- Büyük veri yüklemelerinde scriptler güvenli ve sürdürülebilir çalışır.

## Admin Paneli ve Journey Yönetimi (2024-07-12)

- Admin paneli sekmeli (TabBar) yapıya geçirildi. Her ana başlık ayrı sekmede yönetiliyor.
- İlim Yolculukları (Journey) modülleri ve adımları ekleme, silme, drag & drop ile sıralama ve toplu CSV yükleme özellikleri eklendi.
- Modül ve adım ekleme dialogları, silme onayı ve modern UI/UX ile sürdürülebilir yönetim sağlandı.
- CSV ile toplu journey yükleme: "CSV ile Journey Yükle" butonundan örnek formatla dosya yüklenebilir.
- Adım sırası drag & drop ile değiştirilebilir, backend'e anında yansır.

### Journey CSV Formatı
module_id,module_title,module_description,step_order,step_title,step_content,step_type,language
1,Siyer-i Nebi,Peygamberimizin hayatı ve örnekliği,1,Doğumu ve Çocukluğu,"Hz. Muhammed'in doğumu, ailesi ve çocukluk dönemi.",text,tr
1,Siyer-i Nebi,Peygamberimizin hayatı ve örnekliği,2,İlk Vahiy,"İlk vahyin gelişi ve Risaletin başlangıcı.",text,tr

### Kullanım
- Admin panelinde "İlim Yolculukları" sekmesinden modül/adım ekleyebilir, silebilir, sıralayabilir veya CSV ile toplu yükleyebilirsiniz.
- Adım sırası drag & drop ile değiştirilebilir.
- Tüm işlemler JWT ile güvenli ve anında backend'e yansır.

### Yol Haritası ve Sıradaki Adımlar

### Yapılacaklar
- Ana sayfa kartlarının (namaz vakti, AI asistanı, ilim yolculukları, devam et, özel günler) aktif hale getirilmesi
- Kitaplık ekranında Kur’an, Hadis, Dua, Zikir, Tefsir içeriklerinin listelenmesi ve detay ekranları
- Dua metni okutma (TTS/text-to-speech) özelliği
- Bildirimler ve kişiselleştirme
- Hızlı erişim butonları ve paylaşım özellikleri
- Premium üyelik akışı ve avantajlar
- AI asistanı referanslı cevap ve kaynak filtreleme
- Journey modüllerinde kullanıcı ilerlemesi ve zengin içerik

### Devam Edenler
- Kitaplık ekranı temel iskelet ve veri modeli
- Dua metni okutma için TTS entegrasyonu araştırması

### Tamamlananlar
- Asistan, sadece SQL’deki hadislerden vektör arama ile sonuç döndürüyor.
- Geçmiş kaydına hadith_id eksiksiz yazılıyor.
- Favori ekleme/çıkarma JWT ile güvenli şekilde çalışıyor.
- Favoriler sekmesi async SQLAlchemy ile hatasız, hızlı ve eksiksiz çalışıyor (selectinload ile).
- Tüm JWT ve oturum yönetimi Flutter’da güvenli şekilde sağlandı.
- Tüm akışlar uçtan uca test edildi ve doğrulandı.
- Geçmiş ve favoriler sekmesinde arama ve sıralama state'leri ayrıldı, UI güncellendi. (2024-07-10)
- Aynı hadisi tekrar favorilere ekleme engellendi, backend ve frontend kontrolü eklendi. (2024-07-10)
- Favori butonu geçmişte ve favorilerde doğru şekilde aktif/pasif gösteriliyor, favoriden çıkarma ve ekleme akışı düzeltildi. (2024-07-10)
- 422 hatası (Unprocessable Entity) düzeltildi, frontend query parametresi ile uyumlu hale getirildi. (2024-07-10)
- Geçmiş ve favori kartlarına modern tasarım, paylaş ve kopyala butonları eklendi. (2024-07-10)
- Paylaş butonu share_plus ile cihaz paylaşım menüsünü açıyor, kopyala panoya kopyalıyor. (2024-07-10)
- Premium/abonelik akışı canlı ödeme entegrasyonuna uygun şekilde kurgulandı. Kullanıcı modeline is_premium ve premium_expiry alanı eklendi. Profil ekranında Premium'a Geç butonu, avantajlar ve demo butonu var. Demo endpointi sadece testte aktif, canlıda gerçek ödeme sonrası premium aktif olacak. (2024-07-10)
- Profil/ayarlar ekranı ve kullanıcı yönetimi akışları (bilgi güncelleme, şifre değiştirme, hesap silme) eksiksiz ve sürdürülebilir şekilde tamamlandı. Tüm API linkleri .env üzerinden okunuyor, kodda sabit bağlantı yok. Çıkış yap butonu kaldırıldı, hesap silindikten sonra login ekranına sorunsuz yönlendirme sağlandı. Testler başarıyla geçti. (2024-07-11)
- Geçmiş ve favorilerde toplu silme (multi-select), gelişmiş arama, filtreleme ve sıralama özellikleri eksiksiz ve modern UI/UX ile tamamlandı. Tüm akışlar uçtan uca test edildi, kullanıcı deneyimi ve veri yönetimi üst düzeye çıkarıldı. (2024-07-11)
- Admin paneli kullanıcı yönetimi bölümünde premium yapma/kaldırma ve kullanıcı silme işlemlerine onay (emin misiniz?) dialogu eklendi. Premium kaldırma özelliği ve tüm işlemlerde yanlışlıkla işlem yapılmasını engelleyen dialoglar eklendi. Backend'de /admin/user/premium endpointi action parametresiyle premium kaldırma desteği aldı. UI/UX ve güvenlik iyileştirildi.
- Journey adımlarında Youtube video oynatıcı entegrasyonu (web ve mobil platform ayrımı, overflow hatası çözümü) başarıyla tamamlandı. Artık Youtube videoları web'de iframe ile, mobilde native player ile sorunsuz oynatılıyor. (2024-07-13)

## Güvenlik Açıkları ve Alınacak Önlemler

- Geliştirme/test ortamında debug print, konsol logları ve API/JWT gibi hassas veriler konsolda görünebilir. Bu normaldir ve sadece geliştiriciye açıktır.
- **Canlıya çıkmadan önce:**
  - Tüm debug print, print, console.log gibi satırlar koddan kaldırılmalı veya sadece debug modda çalışacak şekilde bırakılmalı.
  - API anahtarı, JWT, şifre, kullanıcı e-posta gibi hassas veriler asla konsola veya ekrana yazdırılmamalı.
  - Tarayıcıda localStorage/sessionStorage/cookie gibi alanlarda hassas veri tutuluyorsa, XSS saldırılarına karşı dikkatli olunmalı.
  - Web için mümkünse JWT gibi hassas veriler HTTP-only cookie'de tutulmalı, Flutter'da ise flutter_secure_storage gibi güvenli storage tercih edilmeli.
- **Ekstra:**
  - Canlıya çıkışta otomatik olarak debug loglarını kaldıran scriptler veya build ayarları kullanılabilir.
  - Kodda sadece hata ayıklama için, `if (kDebugMode) print(...)` gibi koşullu loglar bırakılabilir.
