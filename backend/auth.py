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
import re
import secrets
from typing import Optional, Dict
import smtplib
import ssl
from email.message import EmailMessage
import requests
from datetime import timedelta

load_dotenv()

SECRET_KEY = os.getenv('SECRET_KEY', 'devsecret')
ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


class RegisterRequest(BaseModel):
    # Telefonla kayıt: phone zorunlu; email artık opsiyonel; username opsiyonel (geri uyumluluk)
    phone: Optional[str] = None
    email: Optional[str] = None
    password: str
    username: Optional[str] = None


class LoginRequest(BaseModel):
    username: str
    password: str


# Forgot Password akışı için istek modelleri
class ForgotStartRequest(BaseModel):
    email: Optional[str] = None
    phone: Optional[str] = None  # Şimdilik phone -> username eşleme yapılır


class ForgotVerifyRequest(BaseModel):
    transactionId: str
    otp: str


class ForgotResetRequest(BaseModel):
    transactionId: str
    newPassword: str


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


# Telefon normalizasyonu ve doğrulama yardımcıları
def normalize_phone_tr(raw: str | None) -> Optional[str]:
    """Türkiye numaralarını E.164 biçimine (örn. +905XXXXXXXXX) normalize eder."""
    if raw is None:
        return None
    s = raw.strip().replace(" ", "").replace("-", "")
    if s.startswith("00"):
        s = "+" + s[2:]
    if s.startswith("0"):
        s = "+90" + s[1:]
    if s.startswith("90") and not s.startswith("+90"):
        s = "+" + s
    s = re.sub(r"[^\d\+]", "", s)
    return s


def is_e164(s: Optional[str]) -> bool:
    return bool(re.fullmatch(r"\+\d{8,15}", (s or "")))


# Basit, geçici Forgot store (in‑memory). Prod için veritabanına taşınmalı.
FORGOT_STORE: Dict[str, Dict] = {}


def _generate_otp(length: int = 6) -> str:
    return ''.join(secrets.choice('0123456789') for _ in range(length))


def _send_otp_email(recipient: str, otp: str):
    """Basit SMTP ile OTP e‑posta gönderimi.

    Ortam değişkenleri:
      - SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD
      - EMAIL_FROM (opsiyonel)
      - SMTP_USE_SSL (0/1), SMTP_USE_TLS (0/1)
      - EMAIL_DRY_RUN (1 ise gerçek gönderim yapılmaz, sadece log)
    """
    try:
        if os.getenv('EMAIL_DRY_RUN', '0') == '1':
            print(f"[EMAIL_DRY_RUN] OTP {otp} -> {recipient}")
            return

        host = os.getenv('SMTP_HOST')
        port = int(os.getenv('SMTP_PORT', '587'))
        user = os.getenv('SMTP_USERNAME')
        password = os.getenv('SMTP_PASSWORD')
        from_addr = os.getenv('EMAIL_FROM', user or 'noreply@example.com')
        use_ssl = os.getenv('SMTP_USE_SSL', '0') == '1'
        use_tls = os.getenv('SMTP_USE_TLS', '1') == '1'

        if not host or not user or not password:
            print('[EMAIL] SMTP yapılandırılmamış; gönderim atlandı.')
            return

        msg = EmailMessage()
        msg['Subject'] = 'Şifre Sıfırlama Kodunuz'
        msg['From'] = from_addr
        msg['To'] = recipient
        msg.set_content(f"Şifre sıfırlama kodunuz: {otp}\nBu kodu 10 dakika içinde kullanın.")

        if use_ssl:
            with smtplib.SMTP_SSL(host, port) as server:
                server.login(user, password)
                server.send_message(msg)
        else:
            with smtplib.SMTP(host, port) as server:
                server.ehlo()
                if use_tls:
                    server.starttls(context=ssl.create_default_context())
                    server.ehlo()
                server.login(user, password)
                server.send_message(msg)
        print(f"[EMAIL] OTP e‑posta gönderildi -> {recipient}")
    except Exception as e:
        print(f"[EMAIL] OTP e‑posta gönderilemedi -> {recipient} | hata: {e}")


def _send_otp_sms(recipient: str, otp: str):
    """Twilio ile OTP SMS gönderimi.

    Gerekli ortam değişkenleri:
      - `TWILIO_ACCOUNT_SID`
      - `TWILIO_AUTH_TOKEN` (veya `TWILIO_API_KEY_SID` + `TWILIO_API_KEY_SECRET`)
      - `TWILIO_MESSAGING_SERVICE_SID` (tercih edilir) veya `TWILIO_FROM_NUMBER`
      - `TWILIO_STATUS_CALLBACK_URL` (opsiyonel, teslimat olayları için)
      - `SMS_DRY_RUN=1` ise gerçek gönderim yapılmaz.

    Döndürür: Başarılıysa Twilio Message SID, değilse None.
    """
    try:
        if os.getenv('SMS_DRY_RUN', '0') == '1':
            print(f"[SMS_DRY_RUN] OTP {otp} -> {recipient}")
            return None

        account_sid = os.getenv('TWILIO_ACCOUNT_SID')
        auth_token = os.getenv('TWILIO_AUTH_TOKEN')
        api_key_sid = os.getenv('TWILIO_API_KEY_SID')
        api_key_secret = os.getenv('TWILIO_API_KEY_SECRET')
        # Ortam değişkenleri: farklı adlara karşı geriye dönük uyumluluk
        messaging_service_sid = (
            os.getenv('TWILIO_MESSAGING_SERVICE_SID')
            or os.getenv('MESSAGING_SERVICE_SID')
        )
        from_number = (
            os.getenv('TWILIO_FROM_NUMBER')
            or os.getenv('FROM_NUMBER')
        )
        status_cb = os.getenv('TWILIO_STATUS_CALLBACK_URL')

        # Yapılandırma özeti (gizli değerler hariç)
        print(
            "[SMS] Config -> "
            f"acct_sid={'SET' if account_sid else 'MISSING'}, "
            f"auth={'API_KEY' if api_key_sid and api_key_secret else ('TOKEN' if auth_token else 'MISSING')}, "
            f"svc_sid={'SET' if messaging_service_sid else 'MISSING'}, "
            f"from={'SET' if from_number else 'MISSING'}"
        )

        if not account_sid:
            print('[SMS] Twilio ACCOUNT SID eksik; gönderim atlandı.')
            return None
        # Kimlik: API key varsa onu kullan, yoksa klasik Auth Token.
        username = (api_key_sid or account_sid)
        password = (api_key_secret or auth_token)
        if not password:
            print('[SMS] Twilio kimlik bilgileri eksik; gönderim atlandı.')
            return None
        if not (messaging_service_sid or from_number):
            print('[SMS] TWILIO_MESSAGING_SERVICE_SID veya TWILIO_FROM_NUMBER gerekli; gönderim atlandı.')
            return None

        url = f"https://api.twilio.com/2010-04-01/Accounts/{account_sid}/Messages.json"
        data = {
            'To': recipient,
            # Türkçe karakterlerde taşıyıcı kodlaması sorun çıkarabilir; güvenli ASCII kullanıyoruz.
            'Body': f'Sifre sifirlama kodunuz: {otp}. 10 dakika icinde kullanin.'
        }
        if messaging_service_sid:
            data['MessagingServiceSid'] = messaging_service_sid
            print(f"[SMS] MessagingService üzerinden gönderiliyor (SID set).")
        else:
            data['From'] = from_number
            print(f"[SMS] Doğrudan From numarasıyla gönderiliyor: {from_number}")

        if status_cb:
            data['StatusCallback'] = status_cb
            print(f"[SMS] StatusCallback etkin: {status_cb}")

        resp = requests.post(url, data=data, auth=(username, password), timeout=10)
        ct = resp.headers.get('Content-Type', '')
        if resp.status_code >= 400:
            err_body = resp.text
            try:
                # Twilio genelde hata gövdesine JSON döner {code, message}
                j = resp.json()
                code = j.get('code')
                msg = j.get('message')
                print(f"[SMS] Gönderim hatası -> status={resp.status_code} code={code} msg={msg}")
            except Exception:
                print(f"[SMS] Gönderim hatası -> status={resp.status_code} body={err_body[:200]}")
            return None
        else:
            sid = None
            try:
                sid = resp.json().get('sid')
            except Exception:
                pass
            print(f"[SMS] OTP SMS gönderildi -> {recipient} | sid={sid}")
            return sid
    except Exception as e:
        print(f"[SMS] OTP SMS gönderilemedi -> {recipient} | hata: {e}")
        return None


@router.post('/forgot/start')
async def forgot_start(req: ForgotStartRequest, db: AsyncSession = Depends(get_db)):
    # Kullanıcıyı email veya (geçici) phone->username ile bul
    user = None
    if req.email:
        result = await db.execute(select(User).where(User.email == req.email))
        user = result.scalar_one_or_none()
    elif req.phone:  # phone artık User.phone alanıyla eşleşir
        phone = normalize_phone_tr(req.phone)
        result = await db.execute(select(User).where(User.phone == phone))
        user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail='Kullanıcı bulunamadı')

    otp = _generate_otp()
    tid = secrets.token_urlsafe(16)
    FORGOT_STORE[tid] = {
        'user_id': user.id,
        'otp': otp,
        'expires': datetime.utcnow() + timedelta(minutes=10),
        'verified': False,
    }
    # OTP gönderimi
    if req.email:
        _send_otp_email(req.email, otp)
    sms_sid = None
    if req.phone:
        sms_sid = _send_otp_sms(normalize_phone_tr(req.phone), otp)
    # Geliştirme amaçlı log
    print(f"[FORGOT] user_id={user.id} tid={tid} otp={otp}")
    resp = { 'transactionId': tid }
    if sms_sid:
        resp['smsMessageSid'] = sms_sid
    if os.getenv('DEBUG_OTP') == '1':
        resp['otp'] = otp
    return resp


@router.post('/forgot/verify')
async def forgot_verify(req: ForgotVerifyRequest):
    tx = FORGOT_STORE.get(req.transactionId)
    if not tx:
        raise HTTPException(status_code=404, detail='İşlem bulunamadı')
    if datetime.utcnow() > tx['expires']:
        # Süresi geçtiyse temizle
        FORGOT_STORE.pop(req.transactionId, None)
        raise HTTPException(status_code=400, detail='Kodun süresi doldu')
    if str(req.otp).strip() != tx['otp']:
        raise HTTPException(status_code=400, detail='Kod geçersiz')
    tx['verified'] = True
    return { 'verified': True }


@router.post('/forgot/reset')
async def forgot_reset(req: ForgotResetRequest, db: AsyncSession = Depends(get_db)):
    tx = FORGOT_STORE.get(req.transactionId)
    if not tx:
        raise HTTPException(status_code=404, detail='İşlem bulunamadı')
    if not tx.get('verified'):
        raise HTTPException(status_code=400, detail='OTP doğrulaması yapılmadı')

    npw = req.newPassword or ''
    # Basit kural: en az 8 karakter, harf + rakam içermeli
    if not (len(npw) >= 8 and re.search(r"[A-Za-z]", npw) and re.search(r"\d", npw)):
        raise HTTPException(status_code=400, detail='Şifre kuralları sağlanmıyor')

    # Kullanıcının şifresini güncelle
    async with AsyncSessionLocal() as session:
        user = await session.get(User, tx['user_id'])
        if not user:
            FORGOT_STORE.pop(req.transactionId, None)
            raise HTTPException(status_code=404, detail='Kullanıcı bulunamadı')
        user.hashed_password = get_password_hash(npw)
        await session.commit()

    # İşlem temizliği
    FORGOT_STORE.pop(req.transactionId, None)
    return { 'success': True }


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
    # Telefon zorunlu: username verilmişse telefon olarak kabul edelim (geri uyumluluk)
    phone_raw = req.phone or req.username
    phone = normalize_phone_tr(phone_raw)
    if not phone:
        raise HTTPException(status_code=400, detail="Telefon numarası zorunludur.")
    if not is_e164(phone):
        raise HTTPException(status_code=400, detail="Telefon numarası geçersiz. Lütfen +90 ile başlayarak girin.")

    # Uniqueness: önce telefon; email sağlandıysa ayrıca kontrol et
    result_phone = await db.execute(select(User).where(User.phone == phone))
    user_phone = result_phone.scalar_one_or_none()
    if user_phone:
        raise HTTPException(status_code=400, detail="Bu telefon ile kullanıcı zaten var.")

    if req.email:
        result_email = await db.execute(select(User).where(User.email == req.email))
        user_email = result_email.scalar_one_or_none()
        if user_email:
            raise HTTPException(status_code=400, detail="Bu e‑posta ile kullanıcı zaten var.")

    hashed_password = get_password_hash(req.password)
    # username alanını da telefon ile hizalı tutuyoruz (tokenlar ve mevcut akış için)
    new_user = User(username=phone, phone=phone, email=req.email, hashed_password=hashed_password)

    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return {"msg": "Kayıt başarılı."}


# auth.py - Satır 106 civarı

# auth.py - Satır 106 civarı

@router.post('/login')
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    print("--- LOGIN FONKSİYONU BAŞLADI ---")
    phone = normalize_phone_tr(req.username)
    print(f"Kullanıcı aranıyor (telefon): {phone}")
    if not is_e164(phone):
        return JSONResponse(status_code=400, content={"detail": "Lütfen telefonunuzu +90 ile başlayarak girin"})

    result = await db.execute(select(User).where(User.phone == phone))
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
