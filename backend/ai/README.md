# AI Code Backend - Ollama Vision API

API backend pour l'analyse d'images avec modèles vision Ollama (LLaVA).

## Installation

### Prérequis
- Python 3.9+
- Ollama installé localement ou accessible

### Setup Ollama

1. **Installer Ollama**:
```bash
# macOS
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh

# Windows
# Télécharger depuis https://ollama.com/download
```

2. **Télécharger modèle vision LLaVA**:
```bash
ollama pull llava:latest
# Ou version spécifique
ollama pull llava:7b
ollama pull llava:13b
```

3. **Démarrer Ollama**:
```bash
ollama serve
# Par défaut sur http://localhost:11434
```

### Installation dépendances Python

```bash
cd backend/ai
pip install -r requirements.txt
```

## Configuration

Variables d'environnement (optionnelles):
- `OLLAMA_BASE_URL`: URL base Ollama (default: `http://localhost:11434`)
- `OLLAMA_VISION_MODEL`: Modèle vision à utiliser (default: `llava:latest`)

## Démarrage

```bash
python ollama_api.py
# API disponible sur http://localhost:5001
```

## Endpoints

### `POST /api/v1/ai/vision/analyze`
Analyser une image avec modèle vision.

**Body:**
```json
{
    "image": "data:image/png;base64,iVBORw0KGgo...",
    "prompt": "Describe this image in detail",
    "context": "Optional context about the scene",
    "cache": true
}
```

**Response:**
```json
{
    "response_text": "Description de l'image...",
    "detected_objects": [],
    "scene_context": {},
    "processing_time": 2.45,
    "model": "llava:latest",
    "timestamp": "2024-01-15T10:30:00"
}
```

**Rate Limit:** 10 requêtes/minute

### `GET /api/v1/ai/vision/models`
Lister modèles vision disponibles.

**Response:**
```json
{
    "available_models": [
        {"name": "llava:latest", "size": "4.7GB"},
        {"name": "llava:7b", "size": "4.7GB"}
    ],
    "current_model": "llava:latest"
}
```

### `POST /api/v1/ai/vision/models/<model_name>`
Changer modèle vision utilisé.

**Rate Limit:** 1 requête/heure

### `GET /api/v1/ai/health`
Health check endpoint.

## Rate Limiting

- **Global**: 100 requêtes/minute, 1000 requêtes/heure
- **Analyze endpoint**: 10 requêtes/minute
- **Model switch**: 1 requête/heure

En production, configurer Redis pour rate limiting distribué:
```python
storage_uri = "redis://localhost:6379/0"
```

## Cache

Cache mémoire local pour éviter requêtes répétées (TTL: 1 heure).
En production, utiliser Redis pour cache distribué.

## Modèles Vision Recommandés

- **llava:latest** (recommandé) - 4.7GB, bon équilibre performance/qualité
- **llava:7b** - Version spécifique 7B
- **llava:13b** - Version 13B (plus précis, plus lent)
- **bakllava:latest** - Alternative open-source

## Production

1. **Utiliser Gunicorn**:
```bash
gunicorn -w 4 -b 0.0.0.0:5001 ollama_api:app
```

2. **Configurer Nginx** reverse proxy

3. **Redis** pour rate limiting et cache

4. **Monitoring** avec Prometheus/Grafana










