# Proje Dosya ve Klasör Yapısı (Örnek ve Açıklamalı)

Kök dizin:
├── README.MD                # Proje genel tanımı, kurulum, yol haritası
├── prompt/                  # Tüm context engine md dosyaları
│   ├── CONTEXT_OVERVIEW.md
│   ├── PROJECT_STRUCTURE.md
│   ├── DATABASE.md
│   ├── API_DOCS.md
│   ├── PROGRESS.md
│   ├── CHANGELOG.md
│   └── CONTRIBUTING.md
├── backend/                 # FastAPI backend kodları, modeller, migration, testler
│   ├── main.py
│   ├── models.py
│   ├── auth.py
│   ├── database.py
│   ├── vector_search.py
│   ├── embedding_utils.py
│   ├── hadith_loader.py
│   ├── add_sample_data.py
│   ├── requirements.txt
│   ├── .env
│   ├── ai_models/           # Fine-tuned AI modelleri
│   │   ├── __init__.py
│   │   └── hadis_model.py   # Hadis AI modeli (HadisAI sınıfı)
│   ├── tests/
│   │   ├── test_main.py
│   │   ├── test_auth.py
│   │   └── test_api.py
│   ├── venv/
│   ├── hadith_big_example.csv
│   ├── hadith_example.csv
│   └── journey_module_example.csv
├── islami_app_new/          # Flutter frontend kodları (ANA frontend)
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── assets/
│   │   ├── .env
│   │   └── turkey_cities.json
│   ├── lib/
│   │   ├── main.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── profile_screen.dart
│   │       ├── library_screen.dart
│   │       ├── journey_screen.dart
│   │       ├── assistant_screen.dart
│   │       ├── user_data_screen.dart
│   │       ├── admin_screen.dart
│   │       ├── premium_screen.dart
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── notification_permission.dart
│   │       ├── notification_permission_web.dart
│   │       ├── notification_permission_stub.dart
│   │       ├── admin_file_upload.dart
│   │       ├── admin_file_upload_web.dart
│   │       └── admin_file_upload_stub.dart
│   ├── test/
│   │   └── widget_test.dart
│   ├── web/
│   │   ├── index.html
│   │   ├── manifest.json
│   │   ├── favicon.png
│   │   └── icons/
│   │       ├── Icon-192.png
│   │       ├── Icon-512.png
│   │       ├── Icon-maskable-192.png
│   │       └── Icon-maskable-512.png
│   ├── android/
│   │   ├── app/
│   │   │   ├── build.gradle.kts
│   │   │   └── src/
│   │   ├── gradle/
│   │   ├── gradle.properties
│   │   ├── settings.gradle.kts
│   │   └── local.properties
│   ├── ios/
│   ├── macos/
│   ├── linux/
│   ├── windows/
│   ├── .idea/
│   ├── .dart_tool/
│   ├── analysis_options.yaml
│   ├── .gitignore
│   └── .metadata
├── islami_app/              # ❗UYARI: Bu klasör eski, silinecek! (Kullanmayın, islami_app_new/ kullanılmalı)
├── alembic/                 # Migration dosyaları (versions/ içinde migration scriptleri)
│   ├── env.py
│   ├── script.py.mako
│   ├── README
│   └── versions/
├── alembic.ini              # Alembic ayar dosyası
├── drop_all.sql             # Veritabanı sıfırlama scripti
├── .github/                 # CI/CD ve issue/pr şablonları (workflows/ içinde pipeline tanımları)
│   └── workflows/
├── .venv/                   # Sanal ortam (otomatik oluşur)
├── .vscode/                 # VSCode ayarları
├── android/                 # (Kökteki, Flutter dışı Android ayarları)
│   └── app/
│       ├── build.gradle.kts
│       └── src/
├── index.html               # (Kökte, web için veya dokümantasyon)
└── İslami App-2.1.pptx      # Proje sunum dosyası


Kök dizin:
├── README.MD                # Proje genel tanımı, kurulum, yol haritası
├── prompt/                  # Tüm context engine md dosyaları
│   ├── CONTEXT_OVERVIEW.md
│   ├── PROJECT_STRUCTURE.md
│   ├── DATABASE.md
│   ├── API_DOCS.md
│   ├── PROGRESS.md
│   ├── CHANGELOG.md
│   └── CONTRIBUTING.md
├── backend/                 # FastAPI backend kodları, modeller, migration, testler
│   ├── main.py
│   ├── models.py
│   ├── auth.py
│   ├── database.py
│   ├── vector_search.py
│   ├── embedding_utils.py
│   ├── hadith_loader.py
│   ├── add_sample_data.py
│   ├── requirements.txt
│   ├── .env
│   ├── tests/
│   │   ├── test_main.py
│   │   ├── test_auth.py
│   │   └── test_api.py
│   ├── venv/
│   ├── hadith_big_example.csv
│   ├── hadith_example.csv
│   └── journey_module_example.csv
├── islami_app_new/          # Flutter frontend kodları (ANA frontend)
│   ├── pubspec.yaml
│   ├── pubspec.lock
│   ├── assets/
│   │   ├── .env
│   │   └── turkey_cities.json
│   ├── lib/
│   │   ├── main.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── profile_screen.dart
│   │       ├── library_screen.dart
│   │       ├── journey_screen.dart
│   │       ├── assistant_screen.dart
│   │       ├── user_data_screen.dart
│   │       ├── admin_screen.dart
│   │       ├── premium_screen.dart
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── notification_permission.dart
│   │       ├── notification_permission_web.dart
│   │       ├── notification_permission_stub.dart
│   │       ├── admin_file_upload.dart
│   │       ├── admin_file_upload_web.dart
│   │       └── admin_file_upload_stub.dart
│   ├── test/
│   │   └── widget_test.dart
│   ├── web/
│   │   ├── index.html
│   │   ├── manifest.json
│   │   ├── favicon.png
│   │   └── icons/
│   │       ├── Icon-192.png
│   │       ├── Icon-512.png
│   │       ├── Icon-maskable-192.png
│   │       └── Icon-maskable-512.png
│   ├── android/
│   │   ├── app/
│   │   │   ├── build.gradle.kts
│   │   │   └── src/
│   │   ├── gradle/
│   │   ├── gradle.properties
│   │   ├── settings.gradle.kts
│   │   └── local.properties
│   ├── ios/
│   ├── macos/
│   ├── linux/
│   ├── windows/
│   ├── .idea/
│   ├── .dart_tool/
│   ├── analysis_options.yaml
│   ├── .gitignore
│   └── .metadata
├── islami_app/              # ❗UYARI: Bu klasör eski, silinecek! (Kullanmayın, islami_app_new/ kullanılmalı)
├── alembic/                 # Migration dosyaları (versions/ içinde migration scriptleri)
│   ├── env.py
│   ├── script.py.mako
│   ├── README
│   └── versions/
├── alembic.ini              # Alembic ayar dosyası
├── drop_all.sql             # Veritabanı sıfırlama scripti
├── .github/                 # CI/CD ve issue/pr şablonları (workflows/ içinde pipeline tanımları)
│   └── workflows/
├── .venv/                   # Sanal ortam (otomatik oluşur)
├── .vscode/                 # VSCode ayarları
├── android/                 # (Kökteki, Flutter dışı Android ayarları)
│   └── app/
│       ├── build.gradle.kts
│       └── src/
├── index.html               # (Kökte, web için veya dokümantasyon)
└── İslami App-2.1.pptx      # Proje sunum dosyası
