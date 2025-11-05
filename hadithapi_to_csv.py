import requests
import csv
import time

API_KEY = "$2y$10$HcM609eGV70WRDBTJKlsWuffz5fIYMWzspQ6XNKl15LvMPB6JeZ62"
BASE_URL = "https://hadithapi.com/api"
HEADERS = {"User-Agent": "Mozilla/5.0"}
CSV_FIELDS = [
    "id", "book_slug", "book_name", "hadith_number", "status",
    "narrator", "text_ar", "text_en", "text_tr", "reference"
]

def get_books():
    url = f"{BASE_URL}/books?apiKey={API_KEY}"
    r = requests.get(url, headers=HEADERS)
    print(f"[DEBUG] Kitaplar endpoint status: {r.status_code}")
    try:
        books = r.json().get("books", [])
    except Exception as e:
        print(f"[ERROR] Kitaplar JSON parse hatası: {e}")
        books = []
    print(f"[DEBUG] Kitap listesi: {[b['bookSlug'] for b in books]}")
    if not books:
        print("[WARNING] Hiç kitap gelmedi! API anahtarı veya endpointte sorun olabilir.")
    return books

def fetch_hadiths(book_slug, page=1):
    url = f"{BASE_URL}/hadiths?apiKey={API_KEY}&book={book_slug}&paginate=100&page={page}"
    resp = requests.get(url, headers=HEADERS)
    print(f"[DEBUG] {book_slug} page {page} - status: {resp.status_code}")
    if resp.status_code == 404:
        print(f"[INFO] {book_slug} kitabında hiç hadis yok (404).")
        return None
    if resp.status_code != 200:
        print(f"[ERROR] Error fetching {book_slug} page {page}: {resp.status_code}")
        return None
    return resp.json()

def main():
    total = 0
    with open("hadiths.csv", "w", encoding="utf-8", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=CSV_FIELDS)
        writer.writeheader()
        books = get_books()
        for book in books:
            book_slug = book["bookSlug"]
            book_name = book["bookName"]
            page = 1
            book_total = 0
            while True:
                data = fetch_hadiths(book_slug, page)
                if data is None:
                    break
                hadiths_data = data.get("hadiths", {}).get("data", [])
                print(f"[DEBUG] {book_slug} page {page} - çekilen hadis sayısı: {len(hadiths_data)}")
                if not hadiths_data:
                    print(f"[INFO] {book_slug} kitabında {page}. sayfada veri yok.")
                    break
                for h in hadiths_data:
                    writer.writerow({
                        "id": h.get("id"),
                        "book_slug": book_slug,
                        "book_name": book_name,
                        "hadith_number": h.get("hadithNumber", ""),
                        "status": h.get("status", ""),
                        "narrator": h.get("englishNarrator", ""),
                        "text_ar": h.get("hadithArabic", ""),
                        "text_en": h.get("hadithEnglish", ""),
                        "text_tr": h.get("hadithTurkish", ""),
                        "reference": h.get("reference", ""),
                    })
                    total += 1
                    book_total += 1
                page += 1
                time.sleep(0.5)
            print(f"[SUMMARY] {book_name} kitabından toplam {book_total} hadis çekildi.")
    print(f"[SUMMARY] Toplam {total} hadis CSV'ye aktarıldı: hadiths.csv")

if __name__ == "__main__":
    main() 