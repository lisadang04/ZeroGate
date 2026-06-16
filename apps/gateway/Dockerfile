# Stage 1: Build & Dependency Isolation
FROM python:3.12-slim AS builder
WORKDIR /app

# Create a virtual environment in a universally accessible directory
RUN python -m venv /opt/venv

# Activate the virtual environment so pip installs packages into it
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir fastapi uvicorn httpx pytest

# Stage 2: Minimal Secure Runtime
FROM python:3.12-slim AS runtime
WORKDIR /app

# Copy the completely built virtual environment from the builder
COPY --from=builder /opt/venv /opt/venv
COPY gateway.py .

# Activate the virtual environment in the runtime stage
ENV PATH="/opt/venv/bin:$PATH"

# Create a non-root system user for CLEAR compliance
RUN useradd -u 10001 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "gateway:app", "--host", "0.0.0.0", "--port", "8000"]