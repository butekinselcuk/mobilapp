from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from models import User
from database import AsyncSessionLocal
import os
from dotenv import load_dotenv
from pydantic import BaseModel

load_dotenv()

SECRET_KEY = os.getenv('SECRET_KEY', 'devsecret')
ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str


class LoginRequest(BaseModel):
    username: str
    password: str


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    result = await db.execute(select(User).where(User.username == username))
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception

    return user


async def get_current_user_optional(token: str = Depends(oauth2_scheme_optional), db: AsyncSession = Depends(get_db)):
    if token is None:
        return None
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            return None
    except JWTError:
        return None

    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()


@router.post('/register')
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where((User.username == req.username) | (User.email == req.email)))
    user = result.scalar_one_or_none()

    if user:
        raise HTTPException(status_code=400, detail="Kullanıcı adı veya e-posta zaten kayıtlı.")

    hashed_password = get_password_hash(req.password)
    new_user = User(username=req.username, email=req.email, hashed_password=hashed_password)

    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return {"msg": "Kayıt başarılı."}


# auth.py - Satır 106 civarı

# auth.py - Satır 106 civarı

@router.post('/login')
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    
    print("--- LOGIN FONKSİYONU BAŞLADI ---")
    print(f"Kullanıcı aranıyor: {req.username}")
    
    result = await db.execute(select(User).where(User.username == req.username))
    user = result.scalar_one_or_none()

    if not user:
        print("Kullanıcı bulunamadı, 401 döndürülüyor.")
        return JSONResponse(
            status_code=401,
            content={"detail": "Kullanıcı adı veya şifre hatalı."}
        )
    
    print(f"Kullanıcı bulundu: {user.username}")
    print("Şifre doğrulaması başlıyor...")

    try:
        is_valid = verify_password(req.password, user.hashed_password)
        print("Şifre doğrulama bitti.")
    except Exception as e:
        print(f"!!! HATA: Şifre doğrulama (verify_password) çöktü: {e}")
        is_valid = False

    if not is_valid:
        print("Şifre geçersiz, 401 döndürülüyor.")
        return JSONResponse(
            status_code=401,
            content={"detail": "Kullanıcı adı veya şifre hatalı."}
        )

    print("Giriş başarılı, token oluşturuluyor.")
    access_token = create_access_token(data={"sub": user.username})

    print("--- LOGIN BAŞARIYLA TAMAMLANDI ---")
    return JSONResponse(
        status_code=200,
        content={
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id
        }
    )


@router.get('/me')
async def read_users_me(current_user: User = Depends(get_current_user)):
    return {
        "username": current_user.username,
        "email": current_user.email,
        "is_admin": current_user.is_admin,
        "is_premium": current_user.is_premium,
        "premium_expiry": current_user.premium_expiry.isoformat() if current_user.premium_expiry else None
    }
