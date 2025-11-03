# Phase 26 - CI/CD - Guide Complet

## Vue d'ensemble

Phase 26 met en place un pipeline CI/CD complet avec GitHub Actions pour automatiser les builds, tests et déploiements.

## Phase 26.1 - GitHub Actions iOS

### Workflows créés

#### 1. iOS Build & Test (`ios-build.yml`)
- **Trigger:** Push/PR sur main/develop
- **Actions:**
  - Checkout code
  - Setup Xcode 15.2
  - Setup Swift 5.9
  - Cache Swift packages
  - Build project
  - Run SwiftLint

#### 2. iOS Tests (`ios-test.yml`)
- **Trigger:** Push/PR sur main/develop
- **Matrix:** Tests sur iPhone 15 Pro, iPhone 14, iPad Pro
- **Actions:**
  - Run tests avec coverage
  - Upload coverage to Codecov
  - Multiple device testing

#### 3. iOS TestFlight (`ios-testflight.yml`)
- **Trigger:** Push tag v*, workflow_dispatch
- **Actions:**
  - Import code signing certificate
  - Install provisioning profile
  - Build archive
  - Export IPA
  - Upload to TestFlight
  - Create GitHub release

### Secrets requis

**GitHub Secrets:**
- `IOS_CERTIFICATE_P12` - Certificate P12 (base64)
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_APP_ID` - App Store Connect App ID
- `IOS_ISSUER_ID` - App Store Connect Issuer ID
- `IOS_API_KEY_ID` - API Key ID
- `IOS_API_KEY` - API Private Key (base64)
- `IOS_TEAM_ID` - Development Team ID

## Phase 26.2 - GitHub Actions Backend

### Workflows créés

#### 1. Backend Deployment (`backend-deploy.yml`)
- **Trigger:** Push sur main, workflow_dispatch
- **Environments:** staging/production
- **Actions:**
  - Setup Python 3.11
  - Install dependencies
  - Setup SSH
  - Run database migrations
  - Deploy code via rsync
  - Restart services
  - Health check
  - Rollback on failure
  - Deployment notification

#### 2. Backend Lint (`backend-lint.yml`)
- **Trigger:** Push/PR sur main/develop
- **Actions:**
  - Run flake8
  - Check black formatting
  - Check isort imports

#### 3. Security Scan (`security-scan.yml`)
- **Trigger:** Push/PR, weekly schedule
- **Actions:**
  - Trivy vulnerability scan
  - Safety dependency check
  - Bandit security linter

### Secrets requis

**GitHub Secrets:**
- `SSH_PRIVATE_KEY` - SSH private key for server
- `SERVER_HOST` - Server IP/hostname
- `SERVER_USER` - SSH user
- `SAFETY_API_KEY` - Safety API key (optional)
- `SLACK_WEBHOOK_URL` - Slack webhook (optional)

## Scripts de déploiement

### `backend/scripts/deploy.sh`
- Créer backup
- Run migrations
- Install dependencies
- Restart services
- Health check
- Rollback on failure

### `backend/scripts/rollback.sh`
- Restore backup
- Restart services
- Health check

### `backend/database/migrate.py`
- Automated migrations
- Migration tracking
- Environment-aware

## Health Checks

### Endpoints

**`/health`** - Complete health check
- Database connection
- Redis connection
- Storage (R2) check
- Returns 200 if healthy, 503 if unhealthy

**`/health/live`** - Liveness probe (Kubernetes)
- Returns 200 if service is alive

**`/health/ready`** - Readiness probe (Kubernetes)
- Returns 200 if service is ready

## Systemd Services

### `backend/systemd/arcode-api.service`
- Flask API service
- Auto-restart
- Environment variables from .env

### `backend/systemd/rq-worker.service`
- RQ worker service
- Auto-restart
- Multiple queues (default, high, low)

## Configuration

### Database Migrations

**Structure:**
```
backend/database/migrations/
  ├── YYYYMMDD_HHMMSS_description.sql
  └── ...
```

**Usage:**
```bash
python -m database.migrate --env staging
python -m database.migrate --env production
```

### Deployment Process

1. **Push to main branch**
2. **GitHub Actions triggered**
3. **Run tests** (iOS) or lint (backend)
4. **Deploy to staging** (automatic)
5. **Health check** (validates deployment)
6. **Rollback** if health check fails
7. **Notification** (Slack/email)

## Checklist Phase 26

- [x] iOS build workflow
- [x] iOS test workflow
- [x] iOS TestFlight workflow
- [x] Backend deploy workflow
- [x] Backend lint workflow
- [x] Security scan workflow
- [x] Database migrations script
- [x] Deployment scripts
- [x] Rollback script
- [x] Health check endpoints
- [x] Systemd services

## Prochaines étapes

Voir Phase 27 - Testing pour:
- Unit tests Swift
- Integration tests
- Device testing
- Load testing







