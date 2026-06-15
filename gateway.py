import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response, status
from fastapi.responses import JSONResponse
import httpx
import time
import json
from datetime import datetime, timezone

app = FastAPI()

# Configuration
BACKEND_SERVICE_URL = os.getenv("BACKEND_SERVICE_URL", "http://127.0.0.1:8001")
VALID_TOKEN = "clear-secure-identity-token-2026"

# Rate Limiting Rules: Max 5 requests per 10 seconds per token
RATE_LIMIT_MAX_REQUESTS = 5
RATE_LIMIT_WINDOW_SECONDS = 10

# In-memory database to store rate-limiting windows
rate_limit_records = {}

# --- Lifespan Resource Management ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize the shared HTTP client connection pool
    app.state.http_client = httpx.AsyncClient()
    yield
    # Shutdown: Close the client to prevent socket/connection leaks
    await app.state.http_client.aclose()

# Pass the lifespan context into the FastAPI application
app = FastAPI(lifespan=lifespan)

@app.middleware("http")
async def security_and_telemetry_layer(request: Request, call_next):
    start_time = time.time()
    token = None
    
    # Extract identity token
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header.split(" ")[1]

    # --- PHASE 1: Zero-Trust Authentication Validation ---
    if not token or token != VALID_TOKEN:
        # Construct failure telemetry before returning
        emit_telemetry_log(request, status.HTTP_401_UNAUTHORIZED, start_time, "AUTH_FAILURE")
        return JSONResponse(
            status_code=status.HTTP_401_UNAUTHORIZED,
            content={"detail": "Invalid or missing identity token. Access denied."}
        )

    # --- PHASE 2: Token-Based Rate Limiting ---
    now = time.time()
    # Initialize list of request timestamps for this token if it doesn't exist
    if token not in rate_limit_records:
        rate_limit_records[token] = []
        
    # Evict timestamps older than our sliding/fixed window
    rate_limit_records[token] = [t for t in rate_limit_records[token] if now - t < RATE_LIMIT_WINDOW_SECONDS]
    
    # Check if the rate limit has been violated
    if len(rate_limit_records[token]) >= RATE_LIMIT_MAX_REQUESTS:
        emit_telemetry_log(request, status.HTTP_429_TOO_MANY_REQUESTS, start_time, "RATE_LIMITED")
        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Rate limit exceeded. Too many requests inside this window."}
        )
        
    # Record the valid request timestamp
    rate_limit_records[token].append(now)

    # --- PHASE 3: Route Forwarding (Reverse Proxy) ---
    response = await call_next(request)
    
    # --- PHASE 4: Telemetry Pipeline Generation ---
    emit_telemetry_log(request, response.status_code, start_time, "SUCCESS")
    return response


def emit_telemetry_log(request: Request, status_code: int, start_time: float, code_path: str):
    """
    Computes system latency and prints a highly structured machine-readable JSON log.
    This structure is optimized for instant consumption by Datadog/Splunk pipelines.
    """
    latency_ms = round((time.time() - start_time) * 1000, 2)

    current_time_utc = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    
    telemetry_payload = {
        "timestamp": current_time_utc,
        "service": "identity-gateway",
        "environment": "local-dev",
        "network": {
            "method": request.method,
            "url": str(request.url),
            "client_host": request.client.host if request.client else "unknown"
        },
        "http": {
            "status_code": status_code,
            "latency_ms": latency_ms
        },
        "security": {
            "code_path": code_path,
            "rate_limit_window_utilization": len(rate_limit_records.get("clear-secure-identity-token-2026", []))
        }
    }
    # Print statement outputs directly to stdout, where container logging agents harvest it
    print(json.dumps(telemetry_payload))


@app.get("/{path:path}")
async def reverse_proxy_route(path: str, request: Request):
    target_url = f"{BACKEND_SERVICE_URL}/{path}"
    try:
        # Access the HTTP client dynamically from the application state
        backend_response = await request.app.state.http_client.request(
            method=request.method,
            url=target_url,
            headers=dict(request.headers),
            content=await request.body()
        )
        return Response(
            content=backend_response.content,
            status_code=backend_response.status_code,
            headers=dict(backend_response.headers)
        )
    except httpx.RequestError as exc:
        return JSONResponse(
            status_code=status.HTTP_502_BAD_GATEWAY,
            content={"detail": f"Failed to connect to internal microservice upstream: {exc}"}
        )