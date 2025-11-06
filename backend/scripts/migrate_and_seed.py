import os
import asyncio
import csv
from typing import Optional

from dotenv import load_dotenv
load_dotenv()

from alembic.config import Config
from alembic import command

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from database import AsyncSessionLocal
from models import Hadith, Setting
from embedding_utils import update_hadith_embeddings
# Not: import_hadiths modülü her ortamda bulunmayabilir. Üst düzeyde
# import etmek yerine, JSON dosyaları mevcutsa fonksiyon içinde deniyoruz.


def _build_sync_db_url_from_env() -> Optional[str]:
    url = os.getenv("DATABASE_URL")
    if not url:
        return None
    # postgres:// → postgresql://
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://") :]
    # postgresql+asyncpg:// → postgresql://
    if "+asyncpg" in url:
        url = url.replace("postgresql+asyncpg://", "postgresql://")
    return url


def run_alembic_upgrade_head():
    """Alembic'i ortam DATABASE_URL ile head'e yükseltir."""
    cfg_path = os.path.join(os.path.dirname(__file__), "..", "..", "alembic.ini")
    cfg_path = os.path.abspath(cfg_path)
    alembic_cfg = Config(cfg_path)
    env_url = _build_sync_db_url_from_env()
    if env_url:
        alembic_cfg.set_main_option("sqlalchemy.url", env_url)
    command.upgrade(alembic_cfg, "head")


async def _seed_hadiths_if_empty(force: bool = False):
    """Hadisleri seed eder. force=True ise mevcut sayıya bakmadan JSON importu dener."""
    async with AsyncSessionLocal() as session:
        total = (await session.execute(select(func.count(Hadith.id)))).scalar_one()
        if not force and total and total >= 100:
            print(f"Seed atlandı: mevcut hadis sayısı = {total}")
            return False

        backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        tr_path = os.path.join(backend_dir, "hadiths_tr.json")
        ar_path = os.path.join(backend_dir, "hadiths_ar.json")
        en_path = os.path.join(backend_dir, "hadiths_en.json")

        # Önce JSON importu dene (tercih edilen)
        if os.path.exists(tr_path) and os.path.exists(ar_path) and os.path.exists(en_path):
            print("JSON hadis importu başlıyor..." + (" (force)" if force else ""))
            try:
                # Dinamik import: modül yoksa CSV’ye düşeceğiz
                from import_hadiths import import_hadiths as import_hadiths_json
                await import_hadiths_json(tr_path, ar_path, en_path)
                # Import sonrası toplamı tekrar kontrol et
                total_after = (await session.execute(select(func.count(Hadith.id)))).scalar_one()
                print(f"JSON import tamamlandı, yeni toplam = {total_after}")
                return total_after > total or force
            except Exception as e:
                print("JSON import hatası, CSV’ye düşülüyor:", e)

        # JSON yoksa CSV örneğini yükle
        csv_path = os.path.join(backend_dir, "hadith_big_example.csv")
        if not os.path.exists(csv_path):
            print("Seed CSV bulunamadı, atlanıyor:", csv_path)
            return False
        inserted = 0
        with open(csv_path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            async with session.begin():
                for row in reader:
                    h = Hadith(
                        turkish_text=row.get('text') or '',
                        source=row.get('source') or 'unknown',
                        reference=row.get('reference') or None,
                        category=row.get('category') or None,
                        language=row.get('language') or 'tr',
                    )
                    session.add(h)
                    inserted += 1
        print(f"CSV seed tamamlandı: {inserted} hadis eklendi")
        return inserted > 0


async def _mark_init_done(session: AsyncSession):
    setting = Setting(key='init_migrated_seeded', value='true')
    session.add(setting)
    await session.commit()


async def _is_init_already_done(session: AsyncSession) -> bool:
    result = await session.execute(select(Setting).where(Setting.key == 'init_migrated_seeded'))
    return result.scalars().first() is not None


async def run():
    """Migrate + seed + embedding güncelleme akışı."""
    # Migration (senkron Alembic çağrısı)
    run_alembic_upgrade_head()

    # FORCE davranışı: ortamdan oku
    force_flag = os.getenv("FORCE_JSON_IMPORT", "false").strip().lower() in {"1", "true", "yes"}

    # Seed ve embedding
    async with AsyncSessionLocal() as session:
        if not force_flag and await _is_init_already_done(session):
            print("Init zaten tamamlanmış. Atlanıyor.")
            return

        seeded = await _seed_hadiths_if_empty(force=force_flag)

        # Embedding güncellemesi: Önce OpenAI, yoksa Gemini (embedding_utils içinde)
        try:
            await update_hadith_embeddings()
        except Exception as e:
            print("Embedding güncelleme sırasında hata:", e)

        # Force olsa da init işaretini güncelle
        await _mark_init_done(session)


if __name__ == "__main__":
    asyncio.run(run())
