# test_gateway.py
import pytest
from fastapi.testclient import TestClient
from apps.gateway.gateway import app, rate_limit_records

# --- Test Environment Lifecycle Management ---
@pytest.fixture
def client():
    # Using the TestClient inside a 'with' block forces the FastAPI lifespan 
    # (startup/shutdown) to execute, creating our app.state.http_client!
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture(autouse=True)
def clear_rate_limits():
    # Clear memory between tests to prevent state leakage
    rate_limit_records.clear()

# Pass 'client' as an argument to our tests so they use the fixture
def test_missing_token_returns_401(client):
    response = client.get("/api/v1/secure-data")
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid or missing identity token. Access denied."

def test_invalid_token_returns_401(client):
    response = client.get("/api/v1/secure-data", headers={"Authorization": "Bearer bad-token"})
    assert response.status_code == 401

def test_rate_limiting_enforcement(client):
    headers = {"Authorization": "Bearer clear-secure-identity-token-2026"}
    
    # First 5 requests should pass validation
    for _ in range(5):
        res = client.get("/api/v1/secure-data", headers=headers)
        assert res.status_code != 429
        
    # 6th request must trigger a 429 Too Many Requests
    fourth_response = client.get("/api/v1/secure-data", headers=headers)
    assert fourth_response.status_code == 429
    assert "Rate limit exceeded" in fourth_response.json()["detail"]