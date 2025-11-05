import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Render'dan gelen connectionString genellikle 'postgres://...' veya 'postgresql://...'
# Async sürücü için 'postgresql+asyncpg://' formatına dönüştürülür.
raw_url = os.getenv('DATABASE_URL', 'postgresql+asyncpg://postgres:postgres@localhost:5432/imanapp')
if raw_url.startswith('postgres://'):
    DATABASE_URL = 'postgresql+asyncpg://' + raw_url[len('postgres://'):]
elif raw_url.startswith('postgresql://') and '+asyncpg' not in raw_url:
    DATABASE_URL = 'postgresql+asyncpg://' + raw_url[len('postgresql://'):]
else:
    DATABASE_URL = raw_url

engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)
Base = declarative_base()