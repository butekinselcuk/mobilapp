import pandas as pd
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from models import Hadith
from database import AsyncSessionLocal
import sys
import math

# CSV dosya yolu argüman olarak alınır
if len(sys.argv) < 2:
    print('Kullanım: python hadith_loader.py <csv_dosyasi>')
    sys.exit(1)

csv_path = sys.argv[1]

# CSV'yi oku
df = pd.read_csv(csv_path)

# Gerekli alanlar kontrolü
gerekli_alanlar = [
    'source', 'turkish_text', 'arabic_text', 'reference', 'category', 'language',
    'hadis_id', 'kitap', 'bab', 'hadis_no', 'tags', 'topic', 'authenticity',
    'narrator_chain', 'related_ayah', 'context', 'embedding'
]
for alan in gerekli_alanlar:
    if alan not in df.columns:
        print(f'CSV dosyasında "{alan}" alanı eksik!')
        sys.exit(1)

def parse_array(val):
    if pd.isna(val) or val is None or str(val).strip() == '':
        return None
    try:
        # JSON string ise
        import json
        arr = json.loads(val)
        if isinstance(arr, list):
            return ','.join(map(str, arr))
        return str(arr)
    except Exception:
        return str(val)

async def main():
    async with AsyncSessionLocal() as session:
        try:
            eklenen = 0
            atlanan = 0
            for i, row in df.iterrows():
                # Zorunlu alan kontrolü
                if not row.get('turkish_text') or not row.get('source'):
                    print(f"ATLANIYOR (satır {i+2}): Eksik zorunlu alan! hadis_id={row.get('hadis_id')}, turkish_text={row.get('turkish_text')}, source={row.get('source')}")
                    atlanan += 1
                    continue
                try:
                    hadith = Hadith(
                        hadis_id=row.get('hadis_id'),
                        kitap=row.get('kitap'),
                        bab=row.get('bab'),
                        hadis_no=row.get('hadis_no'),
                        arabic_text=row.get('arabic_text'),
                        turkish_text=row.get('turkish_text'),
                        tags=parse_array(row.get('tags')),
                        topic=row.get('topic'),
                        authenticity=row.get('authenticity'),
                        narrator_chain=row.get('narrator_chain'),
                        related_ayah=parse_array(row.get('related_ayah')),
                        context=row.get('context'),
                        source=row.get('source'),
                        reference=row.get('reference'),
                        category=row.get('category'),
                        language=row.get('language', 'tr'),
                        embedding=row.get('embedding')
                    )
                    session.add(hadith)
                    print(f"EKLENİYOR (satır {i+2}): hadis_id={row.get('hadis_id')}, turkish_text={str(row.get('turkish_text'))[:30]}")
                    eklenen += 1
                except Exception as row_e:
                    print(f"ATLANIYOR (satır {i+2}): HATA: {row_e}")
                    atlanan += 1
            await session.commit()
            print(f'Hadisler başarıyla yüklendi. Eklenen: {eklenen}, Atlanan: {atlanan}')
        except Exception as e:
            await session.rollback()
            print('Yükleme sırasında genel hata oluştu:', e)

if __name__ == "__main__":
    asyncio.run(main()) 