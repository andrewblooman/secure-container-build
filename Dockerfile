FROM python:3.11-slim AS base

# OCI standard labels
LABEL org.opencontainers.image.title="Secure Container Build"
LABEL org.opencontainers.image.description="A secure Python Flask application with vulnerability scanning and SBOM"
LABEL org.opencontainers.image.authors="andyblooman"
LABEL org.opencontainers.image.vendor="andyblooman"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/andyblooman/secure-container-build"
LABEL org.opencontainers.image.documentation="https://github.com/andyblooman/secure-container-build/README.md"
LABEL org.opencontainers.image.base.name="python:3.11-slim"

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app

EXPOSE 8080

# Run Flask app
CMD ["python", "app/main.py"]