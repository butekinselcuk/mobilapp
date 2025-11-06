# Backend Scripts

Bu servis başlangıcında `migrate_and_seed` otomatik çalışır. Artık `FORCE_JSON_IMPORT=true` ortam değişkeniyle 3 dilli JSON hadis importu üretim ortamında yeniden tetiklenebilir.

- JSON dosyaları: `hadiths_tr.json`, `hadiths_ar.json`, `hadiths_en.json`
- Import sonrası embedding güncellemesi otomatik çalışır.

Kullanım (Render ortam değişkeni):

```
FORCE_JSON_IMPORT=true
```

Not: Import scripti mevcut kayıtları `hadis_id + language` eşleşmesiyle atlar, tekrarlı kayıt oluşturmaz.
