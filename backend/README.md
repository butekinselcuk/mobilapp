# İslami App Backend

FastAPI ile geliştirilmiş İslami içerik sunan backend servisi.

## Özellikler

- Hadis arama ve AI destekli cevaplar
- Kur'an ayetleri ve tefsirler
- Dua ve zikir koleksiyonu
- Kullanıcı kimlik doğrulama sistemi
- Chat oturumları
- Kişisel seyahat modülleri

## Kurulum

### Gereksinimler

- Python 3.12+
- PostgreSQL veritabanı
- Google Gemini API anahtarı

### Yerel Geliştirme

1. Depoyu klonlayın:
```bash
git clone <repo-url>
cd islami-app-backend
```

2. Sanal ortam oluşturun:
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

3. Bağımlılıkları yükleyin:
```bash
pip install -r requirements.txt
```

4. Ortam değişkenlerini ayarlayın:
```bash
cp .env.example .env
# .env dosyasını düzenleyin
```

5. Veritabanını oluşturun:
```bash
alembic upgrade head
```

6. Uygulamayı başlatın:
```bash
uvicorn main:app --reload
```

## Deploy

### Render'a Deploy

1. GitHub hesabınızda yeni bir repo oluşturun
2. Bu kodu push edin:
```bash
git init
git add .
git commit -m "İlk commit"
git remote add origin <your-repo-url>
git push -u origin main
```

3. Render dashboard'a gidin
4. "New Web Service" seçin
5. GitHub repo'nuzu bağlayın
6. Aşağıdaki ayarları kullanın:
   - **Name**: islami-app-backend
   - **Environment**: Python
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: Starter (ücretsiz)

7. Ortam değişkenlerini ekleyin:
   - `DATABASE_URL`: PostgreSQL bağlantı dizesi
   - `SECRET_KEY`: Güvenli bir anahtar
   - `GEMINI_API_KEY`: Google Gemini API anahtarı
   - `GEMINI_URL`: https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent

## API Endpoint'leri

- `POST /api/ask` - AI'ye soru sor
- `POST /auth/register` - Kullanıcı kaydı
- `POST /auth/login` - Kullanıcı girişi
- `GET /api/hadiths` - Hadis arama
- `GET /api/quran-verses` - Kur'an ayetleri
- `GET /api/duas` - Dualar
- `GET /api/zikrs` - Zikirler

## Lisans

MIT