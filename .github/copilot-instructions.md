# Copilot Instructions

## Project Overview

This repository is a **secure container build pipeline** demonstrating supply chain security best practices. The core application is a minimal Python Flask server; the substance of the project lives in the GitHub Actions workflow that builds, scans, signs, and attests the container image.

## Local Development

```bash
# Build the container image
docker build -t secure-container-build .

# Run the container
docker run -p 8080:8080 secure-container-build
# App available at http://localhost:8080
```

There is no test suite or linter configured for the Python app.

## Architecture

The pipeline is defined in `.github/workflows/actions.yml` and consists of four jobs with explicit dependency ordering:

```
build ──┬──► scan
        └──► sbom ──► sign-and-attest
```

| Job | Tool | Output |
|---|---|---|
| `build` | Docker Buildx | Image pushed to `andyblooman/secure-container-build:latest` |
| `scan` | Grype | Vulnerability report (HIGH/CRITICAL, non-blocking) |
| `sbom` | Syft | `sbom.spdx.json` + `sbom-predicate.json` uploaded as artifact |
| `sign-and-attest` | Cosign | Keyless image signature + SBOM attestation + provenance attestation |

All signing uses **keyless Cosign via GitHub Actions OIDC** (`COSIGN_EXPERIMENTAL=true`) — no long-lived signing keys exist.

## Key Conventions

- **Base image**: `python:3.11-slim` — keep it slim to minimise the Trivy attack surface.
- **OCI labels**: All standard `org.opencontainers.image.*` labels must be kept in sync between the `Dockerfile` and any documentation updates.
- **SBOM format**: SPDX JSON (`syft … -o spdx-json`). The predicate wrapper uses type `https://spdx.dev/Document`.
- **Provenance type**: `slsaprovenance` (SLSA Level 2).
- **Grype non-blocking**: `fail-build: false` — the scan job is informational and never blocks the pipeline. Change to `true` to make it a hard gate.
- **Job permissions follow least privilege**: each job only requests the permissions it needs (`id-token: write` only where Cosign runs, `contents: read` only for the build job).

## Required Secrets

| Secret | Purpose |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub login |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

## Verification Commands

```bash
# Verify image signature
cosign verify \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest

# Verify SBOM attestation
cosign verify-attestation \
  --type https://spdx.dev/Document \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest

# Verify provenance
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest | jq .
```
