# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository demonstrates a secure container build pipeline — the Python Flask app (`app/main.py`) is intentionally minimal. The substance of the project is the GitHub Actions pipeline that builds, scans, signs, and attests the container image.

There is no test suite or linter configured for the Python app.

## Local Development

```bash
# Build the container image
docker build -t secure-container-build .

# Run the container
docker run -p 8080:8080 secure-container-build
# App available at http://localhost:8080
```

## Pipeline Architecture

Two workflows drive this project:

**`actions.yml`** — triggers on push to `main` and `workflow_dispatch`:
```
build ──► sbom ──► sign-and-attest
```
Builds, generates SPDX JSON SBOM via Syft, then signs image + attests SBOM and provenance via Cosign (keyless, OIDC-based).

**`security-agent.yml`** — triggers on pull requests to `main`:
```
build ──┬──► snyk-code-scan ──────────┐
        └──► snyk-container-scan ─────┴──► security-agent-review
```
Runs Snyk SAST and container scans, then calls the reusable `security-review.yml` workflow which sends findings + PR diff to Claude and posts a structured review comment (PASS / ADVISORY / FAIL verdict) on the PR.

**`security-review.yml`** — reusable `workflow_call` workflow. Can be consumed by any pipeline that has already uploaded Snyk scan artifacts (`snyk-*-results`) in the **same workflow run** (artifact sharing only works within a single run).

## Key Conventions

- **Base image**: `python:3.11-slim` — keep it slim to minimise attack surface.
- **OCI labels**: All `org.opencontainers.image.*` labels are in `Dockerfile` and must stay in sync with any documentation.
- **SBOM format**: SPDX JSON via Syft (`-o spdx-json`). Predicate type: `https://spdx.dev/Document`.
- **Provenance type**: `slsaprovenance` (SLSA Level 2).
- **Snyk container scan**: uses `--exclude-base-image-vulns` — only app-layer vulns are reported. `|| true` makes it non-blocking.
- **Grype scan (actions.yml)**: `fail-build: false` — informational only. Set to `true` to make it a hard gate.
- **Keyless signing**: `COSIGN_EXPERIMENTAL=true` — uses GitHub Actions OIDC; no long-lived signing keys exist.
- **Job permissions**: each job requests only what it needs (`id-token: write` only where Cosign runs).

## Security Review Workflow Context

The `security-review.yml` workflow optionally reads two files at review time:

- **`CLAUDE.md`** (this file) — passed to Claude as project security policy context.
- **`security/threats/threat-model.json`** — JSON threat model enriching the AI review. Create this file to add asset/threat/mitigation context to automated reviews.

## Required Secrets

| Secret | Purpose |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub login |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SNYK_TOKEN` | Snyk API token for all scan jobs |
| `ANTHROPIC_API_KEY` | Claude API key for the Security Engineer Agent |
| `APP_ID` | GitHub App ID for posting PR review comments |
| `APP_PRIVATE_KEY` | GitHub App private key (PEM) for posting PR review comments |

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

# Verify provenance attestation
cosign verify-attestation \
  --type slsaprovenance \
  --certificate-identity-regexp "https://github.com/andrewblooman/secure-container-build/.*" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  docker.io/andyblooman/secure-container-build:latest | jq .
```
