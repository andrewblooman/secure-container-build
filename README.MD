# Secure Container Build Pipeline

This project demonstrates a secure container build pipeline that implements modern security best practices for building, scanning, signing, and publishing container images.

## Features

- 🔨 Builds a Python Flask application container image
- 🔍 Performs vulnerability scanning using Trivy
- 📝 Generates Software Bill of Materials (SBOM) using Syft
- ✍️ Signs the container image using Cosign with keyless signing
- 📦 Publishes the image to Docker Hub
- 📄 Attaches SBOM as OCI artifact
- ✅ Generates and signs provenance attestation

## Workflow Steps

1. **Build Container Image**
   - Uses Docker Buildx for efficient builds
   - Base image: python:3.11-slim
   - Installs required Python dependencies
   - Builds Flask application

2. **Security Scanning**
   - Scans container image using Trivy
   - Checks for HIGH and CRITICAL vulnerabilities
   - Identifies known CVEs in dependencies

3. **SBOM Generation**
   - Creates Software Bill of Materials using Syft
   - Generates SPDX JSON format
   - Attaches SBOM to image as OCI artifact
   - Signs the SBOM attestation

4. **Image Signing**
   - Uses Cosign for keyless signing
   - Implements Sigstore's keyless signing flow
   - Provides cryptographic verification of image authenticity

5. **Provenance**
   - Generates SLSA-style provenance attestation
   - Records build context and environment
   - Signs and attaches provenance to image

## Usage

### Prerequisites
- Docker Hub account
- GitHub Actions enabled
- Required secrets configured in GitHub repository:
  - `DOCKERHUB_USERNAME`: Your Docker Hub username
  - `DOCKERHUB_TOKEN`: Your Docker Hub access token (create at https://hub.docker.com/settings/security)

No additional environment variables need to be configured as the workflow automatically sets:
- `IMAGE_NAME`: Based on your GitHub repository name
- `IMAGE_TAG`: Set to "latest"
- `REGISTRY`: Set to "docker.io"

### Running Locally

1. Build the container:
```bash
docker build -t myapp .
```

2. Run the container:
```bash
docker run -p 8080:8080 myapp
```

3. Access the application at `http://localhost:8080`

## GitHub Actions Workflow

The pipeline is automated using GitHub Actions and triggers on:
- Push to main branch
- Manual workflow dispatch

## Security Features

This pipeline implements several container security best practices:
- Vulnerability scanning before deployment
- Software supply chain security through SBOMs
- Image signing for authenticity verification
- Build provenance for traceability
- Minimal base image to reduce attack surface

## Application

The application is a simple Flask web server that demonstrates the secure container build pipeline. It serves a basic webpage indicating that the image is SBOM-signed and attested.

## License

This project is licensed under the terms of the included LICENSE file.
