# Secure Container Build Pipeline

This project demonstrates a secure container build pipeline that implements modern security best practices for building, scanning, signing, and publishing container images.

## Features

- 🔨 Builds a Python Flask application container image with OCI standard labels
- 🔍 Performs vulnerability scanning using Trivy
- 📝 Generates Software Bill of Materials (SBOM) using Syft
- ✍️ Signs the container image using Cosign with keyless signing
- 📦 Publishes the image to Docker Hub
- 📄 Attests and signs SBOM as cryptographic attestation
- ✅ Generates and attests provenance

## Workflow Steps

1. **Build Container Image**
   - Uses Docker Buildx for efficient builds
   - Base image: python:3.11-slim
   - Includes OCI standard labels for metadata
   - Installs required Python dependencies
   - Builds Flask application

2. **Security Scanning**
   - Scans container image using Trivy
   - Checks for HIGH and CRITICAL vulnerabilities
   - Identifies known CVEs in dependencies

3. **SBOM Generation**
   - Creates Software Bill of Materials using Syft
   - Generates SPDX JSON format
   - Uploads SBOM as artifact for later signing

4. **Image Signing & Attestation**
   - Uses Cosign for keyless signing via Sigstore
   - Attaches SBOM to image as OCI artifact
   - Generates SLSA-style provenance attestation
   - Signs provenance and attaches to image
   - All signing uses GitHub Actions OIDC tokens

## Usage

### Prerequisites
- Docker Hub account
- GitHub Actions enabled
- Required secrets configured in GitHub repository:
  - `DOCKERHUB_USERNAME`: Your Docker Hub username
  - `DOCKERHUB_TOKEN`: Your Docker Hub access token (create at https://hub.docker.com/settings/security)

The workflow automatically uses:
- `IMAGE_NAME`: andyblooman/secure-container-build
- `IMAGE_TAG`: latest

### Running Locally

1. Build the container:
```bash
docker build -t secure-container-build .
```

2. Run the container:
```bash
docker run -p 8080:8080 secure-container-build
```

3. Access the application at `http://localhost:8080`

## Verification

### Install Cosign

First, install Cosign on your system:

```bash
# Download the latest version
curl -LO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64

# Make it executable
chmod +x cosign-linux-amd64

# Move it to your PATH
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# Verify installation
cosign version
```

### Verify Image Signature

Verify that the image was signed by the GitHub Actions workflow:

```bash
cosign verify \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest
```

### View Attached SBOM

Download and view the attached SBOM:

```bash
# Download the SBOM
cosign download sbom docker.io/andyblooman/secure-container-build:latest > sbom.spdx.json

# View the SBOM (requires jq)
cat sbom.spdx.json | jq .

# Or view it directly
cosign download sbom docker.io/andyblooman/secure-container-build:latest | jq .
```

### Verify Provenance Attestation

View the build provenance:

```bash
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest | jq .
```

### View Container Image Labels

Inspect the OCI standard labels embedded in the image:

```bash
# Pull the image first
docker pull andyblooman/secure-container-build:latest

# View all labels
docker inspect andyblooman/secure-container-build:latest | jq '.[0].Config.Labels'

# View specific OCI labels
docker inspect andyblooman/secure-container-build:latest \
  --format '{{ range $k, $v := .Config.Labels }}{{ $k }}={{ $v }}{{ println }}{{ end }}' | grep opencontainers
```

Expected labels:
- `org.opencontainers.image.title`
- `org.opencontainers.image.description`
- `org.opencontainers.image.authors`
- `org.opencontainers.image.vendor`
- `org.opencontainers.image.licenses`
- `org.opencontainers.image.version`
- `org.opencontainers.image.source`
- `org.opencontainers.image.documentation`
- `org.opencontainers.image.base.name`

## GitHub Actions Workflow

The pipeline is automated using GitHub Actions and triggers on:
- Push to main branch
- Manual workflow dispatch (requires repository write access)

### Security Controls

The workflow implements several security controls:
- Minimal permissions per job (least privilege principle)
- OIDC token-based keyless signing (no long-lived secrets)
- Repository owner validation can be added to prevent unauthorized runs
- Secrets are only accessible to authorized workflows

## Security Features

This pipeline implements several container security best practices:

- **Vulnerability Scanning**: Identifies known vulnerabilities before deployment
- **Software Bill of Materials**: Provides transparency of all dependencies
- **Image Signing**: Cryptographic proof of image authenticity and integrity
- **Build Provenance**: Complete traceability of build process and materials
- **Minimal Base Image**: Reduces attack surface using slim Python base
- **OCI Standard Labels**: Provides standardized metadata for compliance and auditing
- **Keyless Signing**: Uses ephemeral certificates via Sigstore, eliminating key management overhead

## Application

The application is a simple Flask web server that demonstrates the secure container build pipeline. It serves a basic webpage indicating that the image is SBOM-signed and attested.

## Supply Chain Security

This project demonstrates SLSA (Supply-chain Levels for Software Artifacts) Level 2 compliance through:
- Automated build process in GitHub Actions
- Provenance generation recording build parameters and environment
- Signed attestations providing cryptographic verification
- Transparent logging via Sigstore's Rekor transparency log

## License

This project is licensed under the terms of the included LICENSE file.