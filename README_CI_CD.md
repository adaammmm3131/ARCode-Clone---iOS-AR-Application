# CI/CD Setup Guide

## Vue d'ensemble

Ce projet utilise GitHub Actions pour l'intégration et le déploiement continu (CI/CD).

## Workflows iOS

### Build & Test
- **Fichier:** `.github/workflows/ios-build.yml`
- **Trigger:** Push/PR sur main/develop
- **Actions:** Build, SwiftLint

### Tests
- **Fichier:** `.github/workflows/ios-test.yml`
- **Trigger:** Push/PR sur main/develop
- **Actions:** Tests multi-devices, coverage

### TestFlight
- **Fichier:** `.github/workflows/ios-testflight.yml`
- **Trigger:** Push tag v*, workflow_dispatch
- **Actions:** Build, sign, upload to TestFlight

## Workflows Backend

### Deployment
- **Fichier:** `.github/workflows/backend-deploy.yml`
- **Trigger:** Push sur main, workflow_dispatch
- **Actions:** Deploy, migrations, health check, rollback

### Lint
- **Fichier:** `.github/workflows/backend-lint.yml`
- **Trigger:** Push/PR sur main/develop
- **Actions:** flake8, black, isort

### Security Scan
- **Fichier:** `.github/workflows/security-scan.yml`
- **Trigger:** Push/PR, weekly schedule
- **Actions:** Trivy, Safety, Bandit

## Secrets Configuration

Voir `backend/docs/PHASE_26_SETUP.md` pour la configuration complète des secrets GitHub.

## Usage

### iOS TestFlight Deployment

1. Créer un tag:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

2. Workflow automatique ou manuel:
- GitHub Actions → iOS TestFlight Deployment → Run workflow
- Entrer version et build number

### Backend Deployment

1. Push sur main → Déploiement automatique staging
2. Workflow manuel pour production:
- GitHub Actions → Backend Deployment → Run workflow
- Sélectionner environment: production

## Monitoring

- **Workflows:** Voir onglet Actions sur GitHub
- **Health:** `https://ar-code.com/health`
- **Logs:** `sudo journalctl -u arcode-api -f`

## Support

Pour problèmes CI/CD, voir:
- `backend/docs/PHASE_26_CI_CD.md`
- `backend/docs/PHASE_26_SETUP.md`







