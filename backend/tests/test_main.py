import os
import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_env_gemini_api_key():
    key = os.getenv('GEMINI_API_KEY')
    assert key is not None and len(key) > 0

def test_ask_endpoint():
    response = client.post('/api/ask', json={
        'question': 'Oruçluyken misvak kullanılır mı?',
        'source_filter': 'all'
    })
    assert response.status_code == 200
    data = response.json()
    assert 'answer' in data
    assert 'sources' in data 