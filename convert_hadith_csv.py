import pandas as pd

# Kaynak CSV'yi oku
df = pd.read_csv("hadiths.csv")

def get_turkish(row):
    # Öncelik: text_tr → turkish_text → text_en → text_ar
    for key in ["text_tr", "turkish_text", "text_en", "text_ar"]:
        val = str(row.get(key, "")).strip()
        if val and val.lower() != "nan":
            if key != "text_tr" and key != "turkish_text":
                print(f"UYARI: id={row.get('id')} için turkish_text eksik! ({key}='{val[:40]}...')")
            return val
    print(f"UYARI: id={row.get('id')} için hiç Türkçe/İngilizce/Arapça metin yok!")
    return ""

df2 = pd.DataFrame({
    "id": df.get("id", ""),
    "hadis_id": df.get("id", ""),
    "kitap": df.get("book_name", ""),
    "bab": "",
    "hadis_no": df.get("hadith_number", ""),
    "arabic_text": df.get("text_ar", ""),
    "turkish_text": df.apply(get_turkish, axis=1),
    "tags": "",
    "topic": "",
    "authenticity": df.get("status", ""),
    "narrator_chain": df.get("narrator", ""),
    "related_ayah": "",
    "context": "",
    "source": df.get("book_slug", ""),
    "reference": df.get("reference", ""),
    "category": "",
    "language": "tr",
    "embedding": "",
    "created_at": ""
})

df2.to_csv("hadiths_for_upload.csv", index=False, encoding="utf-8")
print("Dönüştürülmüş CSV oluşturuldu: hadiths_for_upload.csv")