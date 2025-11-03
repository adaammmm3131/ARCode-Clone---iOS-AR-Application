# Phase 18.6 - Cloudflare R2 Storage

Guide pour configurer Cloudflare R2 (S3-compatible) pour stockage assets.

## Étape 1: Créer Compte Cloudflare

1. Aller sur [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Créer compte (free tier disponible)
3. Ajouter domaine `ar-code.com` (si pas déjà fait)

## Étape 2: Créer R2 Bucket

### 2.1. Activer R2

1. Dashboard → R2 → Get Started
2. Ajouter méthode de paiement (requis même pour free tier, pas de frais)
3. Créer R2 bucket:
   - **Bucket name:** `ar-code-assets`
   - **Location:** Auto (choisit automatiquement)

### 2.2. Configuration bucket

**Settings:**
- Public Access: Enabled (pour CDN)
- CORS: Configuré (voir étape 3)

## Étape 3: Configuration CORS

### 3.1. CORS Policy

Dans bucket settings → CORS:

```json
[
  {
    "AllowedOrigins": [
      "https://ar-code.com",
      "https://api.ar-code.com",
      "ar-code://*"
    ],
    "AllowedMethods": [
      "GET",
      "PUT",
      "POST",
      "DELETE",
      "HEAD"
    ],
    "AllowedHeaders": [
      "*"
    ],
    "ExposeHeaders": [
      "ETag",
      "Content-Length"
    ],
    "MaxAgeSeconds": 3600
  }
]
```

## Étape 4: Créer API Token

### 4.1. R2 API Token

1. Dashboard → R2 → Manage R2 API Tokens
2. Create API Token:
   - **Token name:** `ar-code-backend`
   - **Permissions:** Object Read & Write
   - **TTL:** No expiration (ou définir expiration)

### 4.2. Récupérer credentials

**Important:** Sauvegarder:
- **Account ID:** (visible dans dashboard)
- **Access Key ID:** (généré avec token)
- **Secret Access Key:** (affiché une seule fois!)

## Étape 5: Configuration Backend

### 5.1. Installer boto3

```bash
pip install boto3
```

### 5.2. Variables d'environnement

Créer `.env`:

```bash
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=ar-code-assets
R2_ENDPOINT_URL=https://<account_id>.r2.cloudflarestorage.com
R2_PUBLIC_URL=https://pub-<account_id>.r2.dev  # Pour accès public
```

### 5.3. Client R2

Créer `backend/api/r2_client.py`:

```python
import boto3
import os
from botocore.config import Config

# Configuration S3-compatible pour R2
r2_config = Config(
    signature_version='s3v4',
    region_name='auto'
)

r2_client = boto3.client(
    's3',
    endpoint_url=os.getenv('R2_ENDPOINT_URL'),
    aws_access_key_id=os.getenv('R2_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('R2_SECRET_ACCESS_KEY'),
    config=r2_config
)

BUCKET_NAME = os.getenv('R2_BUCKET_NAME')
PUBLIC_URL = os.getenv('R2_PUBLIC_URL')
```

## Étape 6: Upload/Download Endpoints

### 6.1. Upload file

```python
def upload_file(file_data, key, content_type):
    """Upload file to R2"""
    r2_client.put_object(
        Bucket=BUCKET_NAME,
        Key=key,
        Body=file_data,
        ContentType=content_type,
        ACL='public-read'  # Pour accès public via CDN
    )
    
    # Retourner URL publique
    return f"{PUBLIC_URL}/{key}"
```

### 6.2. Download file

```python
def download_file(key):
    """Download file from R2"""
    response = r2_client.get_object(
        Bucket=BUCKET_NAME,
        Key=key
    )
    return response['Body'].read()
```

### 6.3. Delete file

```python
def delete_file(key):
    """Delete file from R2"""
    r2_client.delete_object(
        Bucket=BUCKET_NAME,
        Key=key
    )
```

## Étape 7: Presigned URLs

### 7.1. Générer presigned URL

```python
from datetime import datetime, timedelta

def generate_presigned_url(key, expiration=3600):
    """Générer presigned URL pour upload temporaire"""
    url = r2_client.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': BUCKET_NAME,
            'Key': key
        },
        ExpiresIn=expiration
    )
    return url
```

### 7.2. Endpoint Flask

```python
@app.route('/api/v1/storage/upload-url', methods=['POST'])
@require_auth
def get_upload_url(user):
    data = request.json
    key = f"uploads/{user['id']}/{data['filename']}"
    
    url = generate_presigned_url(key, expiration=3600)
    
    return jsonify({
        "upload_url": url,
        "key": key,
        "expires_in": 3600
    })
```

## Étape 8: CDN Integration

### 8.1. Custom Domain (Optionnel)

1. Dans R2 bucket settings → Custom Domain
2. Ajouter domain: `assets.ar-code.com`
3. Configurer DNS CNAME:
   ```
   assets.ar-code.com CNAME <r2-domain>
   ```

### 8.2. Cloudflare CDN

Les fichiers R2 sont automatiquement servis via Cloudflare CDN:
- Edge locations worldwide
- Compression automatique
- Cache headers

## Étape 9: Structure Bucket

Organisation recommandée:

```
ar-code-assets/
├── models/
│   ├── <uuid>/model.glb
│   ├── <uuid>/model_low.glb
│   └── <uuid>/model_medium.glb
├── videos/
│   └── <uuid>/video.mp4
├── images/
│   ├── <uuid>/thumbnail.jpg
│   └── <uuid>/preview.jpg
├── splats/
│   └── <uuid>/splat.ply
└── uploads/
    └── <user_id>/<temp_files>
```

## Checklist

- [ ] Compte Cloudflare créé
- [ ] R2 bucket créé
- [ ] CORS configuré
- [ ] API token créé
- [ ] Credentials sauvegardés
- [ ] Backend configuré (boto3)
- [ ] Upload endpoint créé
- [ ] Download endpoint créé
- [ ] Presigned URLs implémentés
- [ ] Custom domain configuré (optionnel)
- [ ] Structure bucket organisée

## Prochaines étapes

Voir `PHASE_18_API_GATEWAY.md` pour configuration Nginx.









