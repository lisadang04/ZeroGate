# Stage 1: Build & Dependency Isolation
FROM python:3.12-slim AS builder
WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir fastapi uvicorn

# Stage 2: Minimal Secure Runtime
FROM python:3.12-slim AS runtime
WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY microservice.py .

ENV PATH="/opt/venv/bin:$PATH"

RUN useradd -u 10002 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8001

CMD ["uvicorn", "microservice:app", "--host", "0.0.0.0", "--port", "8001"]