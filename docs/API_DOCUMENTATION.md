# Documentation API - ARCode Clone

Documentation complète de l'API REST ARCode Clone.

## 📚 Table des Matières

1. [Base URL](#base-url)
2. [Authentification](#authentification)
3. [Endpoints](#endpoints)
4. [Modèles de Données](#modèles-de-données)
5. [Codes d'Erreur](#codes-derreur)
6. [Rate Limiting](#rate-limiting)
7. [Webhooks](#webhooks)
8. [OpenAPI Specification](#openapi-specification)

## 🌐 Base URL

Production: `https://api.ar-code.com`
Staging: `https://staging-api.ar-code.com`
Local: `http://localhost:8080`

## 🔐 Authentification

### OAuth 2.0

L'API utilise OAuth 2.0 avec Supabase Auth.

#### Authorization Code Flow

1. **Authorization Request**
```
GET /oauth/authorize?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope=read write
```

2. **Token Exchange**
```
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "authorization_code",
  "code": "{authorization_code}",
  "client_id": "{client_id}",
  "client_secret": "{client_secret}",
  "redirect_uri": "{redirect_uri}"
}
```

3. **Token Response**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh_token_string",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "read write"
}
```

#### Using Access Token

Inclure le token dans le header Authorization:
```
Authorization: Bearer {access_token}
```

#### Refresh Token

```
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "refresh_token",
  "refresh_token": "{refresh_token}",
  "client_id": "{client_id}",
  "client_secret": "{client_secret}"
}
```

## 📡 Endpoints

### Health Check

#### GET /health
Vérifier le statut de l'API.

**Response:**
```json
{
  "status": "ok"
}
```

#### GET /health/live
Liveness probe.

#### GET /health/ready
Readiness probe (vérifie DB, Redis, etc.).

### AR Codes

#### GET /api/v1/ar-codes/{id}
Récupérer un AR Code.

**Headers:**
- `Authorization: Bearer {token}` (optionnel)

**Response:**
```json
{
  "id": "uuid",
  "title": "Mon AR Code",
  "description": "Description",
  "type": "object_capture",
  "qr_code_url": "https://ar-code.com/a/abc123",
  "asset_url": "https://cdn.ar-code.com/assets/model.usdz",
  "thumbnail_url": "https://cdn.ar-code.com/thumbnails/thumb.png",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z",
  "user_id": "user-uuid",
  "is_public": true,
  "metadata": {
    "format": "USDZ",
    "size": 1024000,
    "dimensions": {
      "width": 1.0,
      "height": 1.0,
      "depth": 1.0
    },
    "processing_status": "completed",
    "processing_progress": 1.0
  }
}
```

#### POST /api/v1/ar-codes/create
Créer un AR Code.

**Headers:**
- `Authorization: Bearer {token}` (requis)

**Body:**
```json
{
  "title": "Mon AR Code",
  "description": "Description",
  "type": "object_capture",
  "is_public": true
}
```

**Response:** 201 Created (AR Code object)

#### PUT /api/v1/ar-codes/{id}
Mettre à jour un AR Code.

**Headers:**
- `Authorization: Bearer {token}` (requis)

**Body:**
```json
{
  "title": "Nouveau titre",
  "description": "Nouvelle description"
}
```

#### DELETE /api/v1/ar-codes/{id}
Supprimer un AR Code.

**Headers:**
- `Authorization: Bearer {token}` (requis)

**Response:** 204 No Content

### Upload 3D

#### POST /api/v1/3d/upload
Upload un modèle 3D.

**Headers:**
- `Authorization: Bearer {token}` (requis)
- `Content-Type: multipart/form-data`

**Body:**
- `file`: Fichier 3D (USDZ, GLB, etc.)
- `ar_code_id`: ID de l'AR Code (optionnel)

**Response:**
```json
{
  "id": "upload-uuid",
  "url": "https://cdn.ar-code.com/assets/model.usdz",
  "status": "completed"
}
```

#### POST /api/v1/3d/photogrammetry
Démarrer photogrammétrie.

**Headers:**
- `Authorization: Bearer {token}` (requis)

**Body:**
```json
{
  "video_url": "https://cdn.ar-code.com/videos/video.mp4",
  "ar_code_id": "ar-code-uuid"
}
```

**Response:**
```json
{
  "job_id": "job-uuid",
  "status": "processing",
  "estimated_time": 900
}
```

### CTA Links

#### GET /api/v1/cta-links/{ar_code_id}
Récupérer les CTA links d'un AR Code.

**Response:**
```json
[
  {
    "id": "link-uuid",
    "ar_code_id": "ar-code-uuid",
    "button_text": "Acheter maintenant",
    "button_style": "primary",
    "destination_url": "https://example.com/product",
    "destination_type": "product_page",
    "position": "bottom_center",
    "is_enabled": true,
    "variant": "A"
  }
]
```

#### POST /api/v1/cta-links
Créer un CTA link.

**Headers:**
- `Authorization: Bearer {token}` (requis)

**Body:**
```json
{
  "ar_code_id": "ar-code-uuid",
  "button_text": "Acheter maintenant",
  "button_style": "primary",
  "destination_url": "https://example.com/product",
  "destination_type": "product_page",
  "position": "bottom_center"
}
```

#### PUT /api/v1/cta-links/{id}
Mettre à jour un CTA link.

#### DELETE /api/v1/cta-links/{id}
Supprimer un CTA link.

#### POST /api/v1/analytics/cta-click
Tracker un clic sur CTA.

**Body:**
```json
{
  "cta_link_id": "link-uuid",
  "ar_code_id": "ar-code-uuid",
  "session_id": "session-uuid"
}
```

### A/B Testing

#### GET /api/v1/ab-tests/{ar_code_id}
Récupérer le test A/B d'un AR Code.

#### POST /api/v1/ab-tests
Créer un test A/B.

**Body:**
```json
{
  "ar_code_id": "ar-code-uuid",
  "name": "Test CTA Button",
  "variants": [
    {
      "id": "variant-a",
      "weight": 50,
      "cta_link_id": "link-a-uuid"
    },
    {
      "id": "variant-b",
      "weight": 50,
      "cta_link_id": "link-b-uuid"
    }
  ],
  "start_date": "2024-01-01T00:00:00Z"
}
```

#### GET /api/v1/ab-tests/{test_id}/results
Récupérer les résultats d'un test A/B.

#### POST /api/v1/ab-tests/{test_id}/conclude
Conclure un test A/B.

**Body:**
```json
{
  "winner_variant_id": "variant-b"
}
```

### Workspaces

#### GET /api/v1/workspaces
Liste des workspaces de l'utilisateur.

#### POST /api/v1/workspaces
Créer un workspace.

**Body:**
```json
{
  "name": "Mon Workspace",
  "description": "Description"
}
```

#### GET /api/v1/workspaces/{id}
Récupérer un workspace.

#### PUT /api/v1/workspaces/{id}
Mettre à jour un workspace.

#### DELETE /api/v1/workspaces/{id}
Supprimer un workspace.

#### GET /api/v1/workspaces/{workspace_id}/members
Liste des membres d'un workspace.

#### POST /api/v1/workspaces/{workspace_id}/members/invite
Inviter un membre.

**Body:**
```json
{
  "email": "user@example.com",
  "role": "editor"
}
```

### Analytics

#### POST /api/v1/analytics/track
Tracker un événement.

**Body:**
```json
{
  "event_type": "qr_scan",
  "ar_code_id": "ar-code-uuid",
  "metadata": {
    "device_type": "ios",
    "location_country": "FR"
  }
}
```

#### GET /api/v1/analytics/stats
Statistiques agrégées.

**Query Parameters:**
- `ar_code_id`: Filtrer par AR Code
- `start_date`: Date de début
- `end_date`: Date de fin

**Response:**
```json
{
  "total_scans": 1250,
  "unique_users": 850,
  "geographic_distribution": {
    "FR": 450,
    "US": 300,
    "DE": 200
  },
  "device_breakdown": {
    "ios": 800,
    "android": 300,
    "web": 150
  }
}
```

### AI Generation

#### POST /api/v1/ai/generation/txt2img
Générer image depuis texte.

**Body:**
```json
{
  "prompt": "a beautiful landscape, mountains, sunset",
  "negative_prompt": "blurry, low quality",
  "steps": 20,
  "cfg_scale": 7.5,
  "width": 512,
  "height": 512,
  "model": "sd-v1-5"
}
```

**Response:**
```json
{
  "image_id": "uuid",
  "image_url": "https://cdn.ar-code.com/ai/generated/image.png",
  "seed": 12345,
  "processing_time": 3.45
}
```

#### POST /api/v1/ai/generation/img2img
Transformer image.

#### POST /api/v1/ai/generation/inpainting
Inpainting.

### White Label

#### GET /api/v1/white-label/config
Récupérer la configuration white label.

#### PUT /api/v1/white-label/config/{id}
Mettre à jour la configuration.

**Body:**
```json
{
  "custom_domain": "ar.votresite.com",
  "logo_url": "https://cdn.ar-code.com/logos/logo.png",
  "primary_color": "#6C5CE7",
  "secondary_color": "#00B894",
  "company_name": "Ma Société"
}
```

## 📊 Modèles de Données

### ARCode
```json
{
  "id": "string (UUID)",
  "title": "string",
  "description": "string | null",
  "type": "object_capture | face_filter | ai_code | video | portal | text | photo | logo | splat | data",
  "qr_code_url": "string (URL)",
  "asset_url": "string (URL) | null",
  "thumbnail_url": "string (URL) | null",
  "created_at": "string (ISO 8601)",
  "updated_at": "string (ISO 8601)",
  "user_id": "string (UUID)",
  "is_public": "boolean",
  "metadata": {
    "format": "string",
    "size": "number",
    "dimensions": {
      "width": "number",
      "height": "number",
      "depth": "number"
    } | null,
    "processing_status": "string",
    "processing_progress": "number (0-1)"
  }
}
```

## ❌ Codes d'Erreur

- `400 Bad Request` - Requête invalide
- `401 Unauthorized` - Token manquant ou invalide
- `403 Forbidden` - Accès refusé
- `404 Not Found` - Ressource introuvable
- `429 Too Many Requests` - Rate limit dépassé
- `500 Internal Server Error` - Erreur serveur
- `503 Service Unavailable` - Service indisponible

## ⚡ Rate Limiting

- **Authentifié**: 100 requêtes/minute
- **Non authentifié**: 20 requêtes/minute
- **Upload**: 10 requêtes/minute

Headers de réponse:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1609459200
```

## 🔔 Webhooks

### Enregistrer un Webhook

```
POST /api/v1/webhooks/register
Authorization: Bearer {token}

{
  "url": "https://votreserveur.com/webhook",
  "events": ["ar_code.created", "ar_code.scanned"],
  "secret": "webhook_secret"
}
```

### Événements Disponibles

- `ar_code.created`
- `ar_code.updated`
- `ar_code.scanned`
- `processing.completed`
- `processing.failed`
- `analytics.updated`

### Payload Webhook

```json
{
  "event_type": "ar_code.scanned",
  "timestamp": "2024-01-01T12:00:00Z",
  "data": {
    "ar_code_id": "uuid",
    "user_id": "uuid",
    "device_type": "ios"
  },
  "signature": "hmac_sha256_signature"
}
```

## 📄 OpenAPI Specification

Spécification OpenAPI complète disponible dans `docs/openapi.yaml`.

### Utilisation

```bash
# Générer la documentation
npm install -g redoc-cli
redoc-cli bundle docs/openapi.yaml -o docs/api.html

# Ou utiliser Swagger UI
docker run -p 8080:8080 -e SWAGGER_JSON=/docs/openapi.yaml -v $(pwd)/docs:/docs swaggerapi/swagger-ui
```

## 🔗 Liens Utils

- [Documentation Interactive](https://api.ar-code.com/docs)
- [Postman Collection](https://api.ar-code.com/postman)
- [SDKs](https://github.com/arcode-clone/sdks)






