import os
import requests

base_url = "http://127.0.0.1:8000/auth"
username = "testuser1"
email = "testuser1@example.com"
password = "testpassword123"

# Test kolaylığı için backend'de DEBUG_OTP beklenir.
os.environ["DEBUG_OTP"] = "1"

# Kayıt (idempotent)
register_resp = requests.post(f"{base_url}/register", json={
    "username": username,
    "email": email,
    "password": password
})
print("Register status:", register_resp.status_code)
print("Register response:", register_resp.text)

# Giriş
login_resp = requests.post(f"{base_url}/login", json={
    "username": username,
    "password": password
})
print("Login status:", login_resp.status_code)
print("Login response:", login_resp.text)

# Forgot start
start_resp = requests.post(f"{base_url}/forgot/start", json={"email": email})
print("Forgot start status:", start_resp.status_code)
print("Forgot start response:", start_resp.text)
start_json = start_resp.json()
tid = start_json.get("transactionId")
otp = start_json.get("otp")

# Forgot verify
verify_resp = requests.post(f"{base_url}/forgot/verify", json={"transactionId": tid, "otp": otp})
print("Forgot verify status:", verify_resp.status_code)
print("Forgot verify response:", verify_resp.text)

# Forgot reset
new_password = "YeniSifre123"
reset_resp = requests.post(f"{base_url}/forgot/reset", json={"transactionId": tid, "newPassword": new_password})
print("Forgot reset status:", reset_resp.status_code)
print("Forgot reset response:", reset_resp.text)

# Yeni şifre ile giriş
login2_resp = requests.post(f"{base_url}/login", json={
    "username": username,
    "password": new_password
})
print("Login (new) status:", login2_resp.status_code)
print("Login (new) response:", login2_resp.text)
