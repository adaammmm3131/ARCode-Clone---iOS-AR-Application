# Phase 22 - Security - Guide Complet

## Vue d'ensemble

Phase 22 implémente un système de sécurité complet avec:
- OAuth 2.0 complet (JWT, refresh tokens, expiration)
- API security (rate limiting, CORS, API keys, IP whitelisting)
- Content security (virus scanning, file validation, size limits)
- GDPR compliance (data export, deletion, consent management)

## Phase 22.1 - OAuth 2.0 Security

### JWT Token Management

**Fichier:** `backend/security/jwt_manager.py`

Fonctionnalités:
- Génération tokens (access + refresh)
- Validation tokens avec expiration
- Refresh token rotation
- Claims personnalisés

**Configuration:**
```python
ACCESS_TOKEN_EXPIRY = 3600  # 1 hour
REFRESH_TOKEN_EXPIRY = 2592000  # 30 days
```

### iOS Keychain Storage

**Fichier:** `Sources/Services/KeychainService.swift`

Stockage sécurisé:
- Access tokens
- Refresh tokens
- Expiration timestamps
- Protection `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`

## Phase 22.2 - API Security

### Rate Limiting

**Fichier:** `backend/security/api_security.py`

- 100 requests/minute par user
- Redis-based rate limiting
- Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

### CORS Policies

Strict CORS:
- Allowed origins configurés
- Credentials support
- Preflight handling

### API Keys

Gestion API keys:
- Validation API keys
- Expiration support
- Scope management

### Request Signing (Optionnel)

HMAC signature verification:
- SHA256 HMAC
- Shared secret
- Timestamp validation

### IP Whitelisting (Optionnel)

Whitelist IPs:
- Configurable via env var
- Cloudflare IP detection

## Phase 22.3 - Content Security

### Virus Scanning (ClamAV)

**Fichier:** `backend/security/content_security.py`

- ClamAV integration
- Automatic scanning uploads
- Quarantine infected files

**Installation ClamAV:**
```bash
sudo apt-get install clamav clamav-daemon
sudo freshclam  # Update virus definitions
```

### File Validation

Validation complète:
- MIME type checking
- File size limits (250MB max)
- Image dimensions (4096x4096 max)
- SHA256 hash calculation

**Allowed Types:**
- Images: JPEG, PNG, WebP, GIF
- Videos: MP4, MOV, AVI
- 3D Models: GLB, USDZ, PLY

### Size Limits

- Max file size: 250MB
- Configurable via env var

## Phase 22.4 - GDPR Compliance

### Data Export

**Endpoint:** `GET /api/v1/gdpr/export`

Exporte toutes données utilisateur:
- Profile
- AR Codes
- Analytics events
- Assets

Format JSON complet.

### Data Deletion

**Endpoint:** `POST /api/v1/gdpr/delete`

Supprime toutes données utilisateur (right to be forgotten):
- Cascade deletion
- Confirmation requise

### Data Anonymization

**Endpoint:** `POST /api/v1/gdpr/anonymize`

Anonymise données au lieu de suppression:
- Email → anonymous
- Name → Anonymous User

### Consent Management

**Endpoints:**
- `GET /api/v1/gdpr/consent` - Get consent status
- `POST /api/v1/gdpr/consent` - Update consent

**Consent Types:**
- Analytics
- Marketing
- Cookies

### Cookie Banner

**Fichier:** `web/cookie-banner.html`

Banner cookie consent:
- Accept/Reject/Settings
- LocalStorage persistence
- Backend sync

## Configuration

### Environment Variables

```bash
# JWT
JWT_SECRET=your-secret-key
ACCESS_TOKEN_EXPIRY=3600
REFRESH_TOKEN_EXPIRY=2592000

# Rate Limiting
RATE_LIMIT_PER_USER=100
REDIS_HOST=localhost
REDIS_PORT=6379

# Content Security
MAX_FILE_SIZE=262144000  # 250MB
CLAMAV_ENABLED=true
CLAMAV_SOCKET=/var/run/clamav/clamd.ctl

# IP Whitelist (optional)
IP_WHITELIST=192.168.1.1,10.0.0.1
```

### Database Schema Update

Ajouter champs GDPR à `users` table:
```sql
ALTER TABLE users ADD COLUMN consent_analytics BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN consent_marketing BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN consent_cookies BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN consent_updated_at TIMESTAMP WITH TIME ZONE;
```

## Checklist Phase 22

- [x] JWT token generation/validation
- [x] Refresh token rotation
- [x] iOS Keychain storage
- [x] Rate limiting (100 req/min)
- [x] CORS strict policies
- [x] API key management
- [x] Request signing (optionnel)
- [x] IP whitelisting (optionnel)
- [x] ClamAV virus scanning
- [x] File validation
- [x] Size limits
- [x] GDPR data export
- [x] GDPR data deletion
- [x] Consent management
- [x] Cookie banner

## Prochaines étapes

Voir Phase 23 - Performance pour compression et optimization.







