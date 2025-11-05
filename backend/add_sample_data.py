import asyncio
from main import QuranVerse, Dua, Zikr, Tafsir, AsyncSessionLocal
from sqlalchemy import delete

import requests

async def add_full_quran():
    async with AsyncSessionLocal() as session:
        # Önce eski Kur'an verilerini sil
        await session.execute(delete(QuranVerse))
        await session.commit()
        for surah_num in range(1, 115):
            url = f"https://api.alquran.cloud/v1/surah/{surah_num}/ar.alafasy"
            resp = requests.get(url)
            surah = resp.json()['data']
            surah_name = surah['englishName']
            for ayah in surah['ayahs']:
                ayah_number = ayah['numberInSurah']
                text_ar = ayah['text']
                audio_url = ayah['audio']
                # Türkçe meal (opsiyonel, hızlı ekleme için kapalı)
                text_tr = None
                # meal_url = f"https://api.alquran.cloud/v1/ayah/{ayah['number']}/tr.yildirim"
                # meal_resp = requests.get(meal_url)
                # text_tr = meal_resp.json()['data']['text'] if meal_resp.status_code == 200 else None
                session.add(QuranVerse(
                    surah=surah_name,
                    ayah=ayah_number,
                    text=text_ar,
                    translation=None,
                    language='ar',
                    surah_id=surah_num,
                    surah_name=surah_name,
                    ayah_number=ayah_number,
                    text_ar=text_ar,
                    text_tr=text_tr,
                    audio_url=audio_url
                ))
            await session.commit()  # Her surenin sonunda commit
            print(f"Surah {surah_num} eklendi.")
        print('Tüm Kur\'an verisi ve ses dosyaları eklendi.')

if __name__ == '__main__':
    # asyncio.run(add_sample_data())
    asyncio.run(add_full_quran()) 