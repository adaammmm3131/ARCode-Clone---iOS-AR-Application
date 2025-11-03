# Phase 18.3 - Supabase Auth Integration

Guide d'intégration Supabase Auth avec OAuth 2.0, JWT, social logins.

## Prérequis

1. Compte Supabase (Free tier: 50K MAU)
2. Projet Supabase créé

## Étape 1: Créer Projet Supabase

1. Aller sur [Supabase Dashboard](https://app.supabase.com/)
2. New Project
3. Configuration:
   - Name: `ar-code`
   - Database Password: (générer strong password)
   - Region: Choisir plus proche (ex: Europe West)

## Étape 2: Configuration Authentication

### 2.1. Enable Providers

Dans Supabase Dashboard → Authentication → Providers:

**Email:**
- Enable email provider: ✅
- Confirm email: ✅ (recommandé)

**Apple:**
- Enable Apple provider: ✅
- Service ID: (créer sur Apple Developer)
- Team ID: (Apple Developer Team ID)
- Key ID: (Apple Key ID)
- Private Key: (Apple Private Key .p8)

**Google:**
- Enable Google provider: ✅
- Client ID: (Google OAuth Client ID)
- Client Secret: (Google OAuth Secret)

### 2.2. URL Configuration

**Site URL:** `https://ar-code.com`

**Redirect URLs:**
```
https://ar-code.com/auth/callback
ar-code://oauth/callback
https://api.ar-code.com/auth/callback
```

## Étape 3: Récupérer Credentials

### 3.1. API Keys

Dans Settings → API:

- **Project URL:** `https://xxxxx.supabase.co`
- **anon/public key:** (pour client-side)
- **service_role key:** (pour backend, garder secret!)

### 3.2. JWT Secret

Dans Settings → API → JWT Settings:

- **JWT Secret:** (utiliser pour validation tokens backend)

## Étape 4: Configuration Backend Flask

### 4.1. Installer dépendances

```bash
pip install supabase pyjwt python-dotenv
```

### 4.2. Variables d'environnement

Créer `.env`:

```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_KEY=eyJhbGc...  # Service role key (backend only)
SUPABASE_JWT_SECRET=your-jwt-secret
```

### 4.3. Code d'intégration

Voir `backend/api/auth_supabase.py`

## Étape 5: iOS Integration

### 5.1. Installer Supabase Swift

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### 5.2. Configuration client

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://xxxxx.supabase.co")!,
    supabaseKey: "eyJhbGc..."
)
```

### 5.3. Authentication

```swift
// Sign in with Apple
try await supabase.auth.signInWithOAuth(
    provider: .apple,
    redirectTo: URL(string: "ar-code://oauth/callback")!
)

// Sign in with Google
try await supabase.auth.signInWithOAuth(
    provider: .google,
    redirectTo: URL(string: "ar-code://oauth/callback")!
)

// Get session
let session = try await supabase.auth.session
let accessToken = session.accessToken
```

## Étape 6: Backend Token Validation

### 6.1. Middleware Flask

Voir `backend/api/middleware_auth.py`

### 6.2. Utilisation

```python
from middleware_auth import require_auth

@app.route('/api/v1/protected')
@require_auth
def protected_route(user):
    # user contient les infos du JWT
    return jsonify({"user_id": user["sub"]})
```

## Étape 7: Session Management

### 7.1. Refresh Tokens

Supabase gère automatiquement refresh tokens:
- Access token: 1 heure
- Refresh token: 30 jours

### 7.2. Token Storage (iOS Keychain)

```swift
// Utiliser Keychain pour stocker tokens sécurisés
import Security

// Sauvegarder
KeychainService.save(token: accessToken, key: "supabase_access_token")

// Charger
let token = KeychainService.load(key: "supabase_access_token")
```

## Étape 8: Password Reset

### 8.1. Email Templates

Dans Supabase Dashboard → Authentication → Email Templates:

- Reset Password Email
- Customiser template HTML

### 8.2. API Backend

```python
# Envoyer email reset
supabase.auth.api.reset_password_for_email(email)

# Reset avec token
supabase.auth.api.update_user({
    "password": new_password
}, token)
```

## Configuration Sécurité

### Rate Limiting Supabase

Supabase a rate limiting intégré:
- Free tier: 500 requests/second
- Burst: 1000 requests/second

### CORS

Dans Supabase Dashboard → Settings → API:
- Allowed origins: `https://ar-code.com`

## Checklist

- [ ] Projet Supabase créé
- [ ] Email provider activé
- [ ] Apple OAuth configuré
- [ ] Google OAuth configuré
- [ ] Redirect URLs configurées
- [ ] API keys récupérées
- [ ] JWT secret noté
- [ ] Backend configuré
- [ ] iOS client configuré
- [ ] Token validation middleware créé
- [ ] Password reset configuré
- [ ] Email templates personnalisés

## Prochaines étapes

Voir `PHASE_18_DATABASE.md` pour configuration PostgreSQL.









