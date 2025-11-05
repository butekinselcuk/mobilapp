import requests

base_url = "http://127.0.0.1:8000/auth"
username = "testuser1"
email = "testuser1@example.com"
password = "testpassword123"

# Kayıt
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