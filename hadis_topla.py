import pandas as pd
import requests
import re
import json

def clean_text(text):
    if not text:
        return ""
    text = text.replace('â', 'a').replace('î', 'i')
    text = re.sub(r'\([^)]*\)', '', text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

def parse_tags(text, topic):
    if not text:
        return []
    keywords = [w for w in re.findall(r'\b\w+\b', text.lower()) if len(w) > 3]
    manual = [topic] if topic else []
    return list(set(keywords + manual))

def fetch_huggingface_hadiths():
    url = "https://huggingface.co/datasets/mesut/Hadith/resolve/main/hadiths-tr.json"
    r = requests.get(url)
    data = r.json()
    return data

def fetch_kaggle_hadiths():
    try:
        df = pd.read_csv("hadiths-tr.csv")
        return df.to_dict(orient="records")
    except Exception:
        return []

def main():
    all_hadiths = []
    try:
        all_hadiths += fetch_huggingface_hadiths()
    except Exception as e:
        print("Huggingface veri çekilemedi:", e)
    all_hadiths += fetch_kaggle_hadiths()

    rows = []
    for h in all_hadiths:
        try:
            row = {
                "hadis_id": h.get("hadis_id") or "",
                "kitap": h.get("kitap") or "",
                "bab": h.get("bab") or "",
                "hadis_no": h.get("hadis_no") or "",
                "arabic_text": h.get("arabic_text") or "",
                "turkish_text": clean_text(h.get("turkish_text") or h.get("text", "")),
                "tags": json.dumps(parse_tags(h.get("turkish_text", "") or h.get("text", ""), h.get("topic"))),
                "topic": h.get("topic") or "",
                "authenticity": h.get("authenticity") or "",
                "narrator_chain": h.get("narrator_chain") or "",
                "related_ayah": json.dumps(h.get("related_ayah", [])),
                "context": h.get("context") or "",
                "source": h.get("source") or "",
                "reference": h.get("reference") or "",
                "category": h.get("category") or "",
                "language": h.get("language", "tr"),
                "embedding": ""
            }
            if not row["turkish_text"] or not row["source"]:
                continue
            rows.append(row)
        except Exception as e:
            print("Satır atlandı:", e)

    df = pd.DataFrame(rows)
    df.to_csv("hadisler_yeni.csv", index=False, encoding="utf-8-sig")
    print(f"Toplam {len(rows)} hadis kaydedildi. Dosya: hadisler_yeni.csv")

if __name__ == "__main__":
    main() 