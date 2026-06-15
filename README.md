# Zero-Trust API Gateway | A high-concurrency, production-ready reverse proxy

A production-ready, zero-trust API Gateway built with FastAPI. Features async high-concurrency, fixed-window rate limiting for DDoS protection, and custom JSON logging middleware for Datadog and Splunk observability. Fully containerized via multi-stage, non-root Docker builds and backed by a comprehensive Pytest test suite for 100% path coverage.

## Technical Stack

![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Pytest](https://img.shields.io/badge/Pytest-0A9EDC?style=for-the-badge&logo=pytest&logoColor=white)

* **Backend Framework:** FastAPI, Python 3
* **Async HTTP Client:** HTTPX
* **Server:** Uvicorn
* **Testing:** Pytest, TestClient
* **DevOps / Deployment:** Docker, Docker Compose

## Core Features

* **Zero-Trust Architecture:** Intercepts all traffic and assumes nothing is safe. Validates identity tokens explicitly before routing traffic to internal services.
* **In-Memory Rate Limiting:** Implements a sliding/fixed-window rate limiter (max 5 requests / 10 seconds per token) to mitigate brute-force and DDoS attacks against downstream services.
* **Asynchronous Concurrency:** Utilizes modern `async/await` patterns and shared connection pools via FastAPI lifecycle events (`@asynccontextmanager`) to ensure non-blocking, high-throughput routing.
* **Production-Grade Observability:** Custom middleware calculates exact network latency and intercepts requests to generate highly structured, machine-readable JSON logs ready for Datadog or Splunk ingestion.
* **Robust Test Suite:** Automated testing suite utilizing Pytest fixtures to simulate application lifecycles, guaranteeing state isolation between tests and 100% path coverage.

## How To Run It

You can spin up the entire isolated environment (the Gateway and the protected Microservice) using Docker. 

**1. Build and start the containers:**
```bash
docker compose up --build
```

**2. Test the Zero-Trust routing:**
Once the containers are running, execute the following curl command in a new terminal window to pass the required identity token and access the secure backend:

```bash
curl -i -H "Authorization: Bearer clear-secure-identity-token-2026" [http://127.0.0.1:8000/api/v1/secure-data](http://127.0.0.1:8000/api/v1/secure-data)
```
Try running the command 6 times in rapid succession to trigger the HTTP 429 Rate Limit response!

## Why I Made This
The motivation behind this project was to understand the critical infrastructure that sits between public clients and private microservices. Instead of simply building a standard REST API, I wanted to engineer the "front door" itself.

By building this gateway, I tackled the challenges of reverse proxying, state management in an asynchronous environment, and the necessity of strict security layers. I specifically focused on observability; rather than relying on standard text logs, I engineered a telemetry pipeline that outputs structured JSON to simulate how enterprise systems feed data into centralized monitoring tools like Datadog. 
