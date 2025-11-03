# Stable Diffusion API Backend

API backend pour génération d'images avec Stable Diffusion (txt2img, img2img, inpainting).

## Installation

### Prérequis
- Python 3.9+
- Stable Diffusion WebUI installé et accessible
- GPU recommandé (CPU fallback supporté)

### Setup Stable Diffusion WebUI

1. **Installer Stable Diffusion WebUI** (Automatic1111):
```bash
# Cloner repository
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
cd stable-diffusion-webui

# Installation automatique
./webui.sh

# Ou avec arguments spécifiques
./webui.sh --api --listen 0.0.0.0 --port 7860
```

2. **Télécharger modèles**:
- SD 1.5: `stable-diffusion-v1-5.safetensors`
- SDXL: `sd_xl_base_1.0.safetensors`
- Placer dans `models/Stable-diffusion/`

### Installation dépendances Python

```bash
cd backend/ai
pip install -r requirements.txt
```

## Configuration

Variables d'environnement:
- `SD_WEBUI_URL`: URL Stable Diffusion WebUI (default: `http://localhost:7860`)
- `SD_MODEL`: Modèle à utiliser (default: `sd-v1-5`)
- `USE_GPU`: Activer GPU (default: `true`)
- `CPU_FALLBACK`: Fallback CPU si GPU indisponible (default: `true`)

## Démarrage

```bash
python stable_diffusion_api.py
# API disponible sur http://localhost:5002
```

## Endpoints

### `POST /api/v1/ai/generation/txt2img`
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
    "seed": -1,
    "model": "sd-v1-5"
}
```

**Response:**
```json
{
    "image_id": "uuid",
    "image_url": "/api/v1/ai/generation/image/uuid",
    "image_base64": "data:image/png;base64,...",
    "seed": 12345,
    "processing_time": 3.45,
    "model": "sd-v1-5"
}
```

### `POST /api/v1/ai/generation/img2img`
Transformer image existante.

**Body:**
```json
{
    "image": "data:image/jpeg;base64,...",
    "prompt": "transform this image",
    "strength": 0.75,
    "steps": 20
}
```

### `POST /api/v1/ai/generation/inpainting`
Inpainting (pour virtual try-on).

**Body:**
```json
{
    "image": "data:image/jpeg;base64,...",
    "mask": "data:image/png;base64,...",
    "prompt": "wear this clothing",
    "strength": 0.9,
    "steps": 30
}
```

### `GET /api/v1/ai/generation/models`
Lister modèles disponibles.

### `GET /api/v1/ai/generation/image/<image_id>`
Récupérer image générée.

### `GET /api/v1/ai/generation/health`
Health check.

## Rate Limiting

- **Global**: 50 requêtes/minute, 500 requêtes/heure
- **Generation endpoints**: 10 requêtes/minute

## Modèles Recommandés

- **SD 1.5** (sd-v1-5): Rapide, bon équilibre qualité/performance
- **SDXL**: Plus précis, plus lent, meilleure qualité
- **Custom models**: Support pour modèles personnalisés

## Production

1. **Utiliser Gunicorn**:
```bash
gunicorn -w 2 -b 0.0.0.0:5002 stable_diffusion_api:app
```

2. **Configurer Nginx** reverse proxy

3. **Redis** pour rate limiting distribué

4. **Monitoring** avec Prometheus/Grafana

5. **GPU Management**: Utiliser GPU pool pour gérer charges










