# Phase 26 - CI/CD Setup Guide

## Configuration GitHub Secrets

### iOS Secrets

Dans GitHub → Settings → Secrets and variables → Actions:

1. **IOS_CERTIFICATE_P12**
   - Export certificate from Keychain
   - Convert to base64: `base64 -i Certificate.p12`
   
2. **IOS_CERTIFICATE_PASSWORD**
   - Password for P12 certificate
   
3. **IOS_BUNDLE_ID**
   - App bundle ID (ex: `com.ar-code.app`)
   
4. **IOS_ISSUER_ID**
   - App Store Connect Issuer ID
   - Found in: App Store Connect → Users and Access → Keys
   
5. **IOS_API_KEY_ID**
   - API Key ID (ex: `ABC123DEF4`)
   
6. **IOS_API_KEY**
   - API Private Key (base64 encoded)
   - Download from App Store Connect → Keys
   - Convert: `base64 -i AuthKey_ABC123DEF4.p8`
   
7. **IOS_TEAM_ID**
   - Apple Developer Team ID

### Backend Secrets

1. **SSH_PRIVATE_KEY**
   - SSH private key for Oracle VM
   - Generate: `ssh-keygen -t ed25519 -C "github-actions"`
   - Add public key to server: `~/.ssh/authorized_keys`
   
2. **SERVER_HOST**
   - Oracle VM IP or hostname
   
3. **SERVER_USER**
   - SSH username (ex: `ubuntu`)
   
4. **SLACK_WEBHOOK_URL** (optional)
   - Slack webhook for notifications

5. **SAFETY_API_KEY** (optional)
   - Safety API key for dependency scanning

## Setup Server

### 1. Create deployment user

```bash
sudo useradd -m -s /bin/bash arcode
sudo mkdir -p /opt/arcode
sudo chown arcode:arcode /opt/arcode
```

### 2. Setup virtual environment

```bash
cd /opt/arcode
python3 -m venv backend/venv
source backend/venv/bin/activate
pip install --upgrade pip
```

### 3. Install systemd services

```bash
sudo cp backend/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable arcode-api
sudo systemctl enable rq-worker
```

### 4. Setup backups directory

```bash
sudo mkdir -p /opt/arcode/backups
sudo chown arcode:arcode /opt/arcode/backups
```

### 5. Create .env file

```bash
cd /opt/arcode/backend
# Create .env with all required environment variables
nano .env
```

## First Deployment

```bash
# Manual first deployment
git clone <repository> /opt/arcode
cd /opt/arcode/backend
source venv/bin/activate
pip install -r requirements.txt
python -m database.migrate --env staging
sudo systemctl start arcode-api
sudo systemctl start rq-worker
```

## Verification

```bash
# Check health
curl http://localhost:8080/health

# Check services
sudo systemctl status arcode-api
sudo systemctl status rq-worker

# Check logs
sudo journalctl -u arcode-api -f
sudo journalctl -u rq-worker -f
```

## Troubleshooting

**SSH connection fails:**
- Verify SSH key is added to server
- Check firewall rules
- Test: `ssh -i ~/.ssh/id_ed25519 user@server`

**Migration fails:**
- Check database credentials in .env
- Verify PostgreSQL is running
- Check migration files syntax

**Health check fails:**
- Check service logs
- Verify dependencies (PostgreSQL, Redis)
- Check environment variables







