#!/usr/bin/env python3
"""
API Serveur pour Ollama Vision Models
Endpoints REST pour analyse d'images avec LLaVA, rate limiting, gestion modèles
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import ollama
import base64
import os
import io
import uuid
from pathlib import Path
from datetime import datetime, timedelta
import json
from typing import Dict, Optional
from PIL import Image
import time

app = Flask(__name__)
CORS(app)  # Permettre requêtes cross-origin

# Configuration Rate Limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per minute", "1000 per hour"],
    storage_uri="memory://"  # Utiliser Redis en production
)

# Configuration
UPLOAD_FOLDER = Path('/tmp/ai/uploads')
RESULTS_FOLDER = Path('/tmp/ai/results')
CACHE_FOLDER = Path('/tmp/ai/cache')

UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)
RESULTS_FOLDER.mkdir(parents=True, exist_ok=True)
CACHE_FOLDER.mkdir(parents=True, exist_ok=True)

# Configuration Ollama
OLLAMA_BASE_URL = os.getenv('OLLAMA_BASE_URL', 'http://localhost:11434')
OLLAMA_VISION_MODEL = os.getenv('OLLAMA_VISION_MODEL', 'llava:latest')  # LLaVA ou équivalent
OLLAMA_TIMEOUT = 120  # 2 minutes timeout

# Cache pour éviter requêtes répétées (simple dict, utiliser Redis en production)
request_cache: Dict[str, Dict] = {}
CACHE_TTL = 3600  # 1 heure

# Initialiser client Ollama
try:
    ollama_client = ollama.Client(host=OLLAMA_BASE_URL)
    # Vérifier que le modèle est disponible
    try:
        ollama_client.show(OLLAMA_VISION_MODEL)
        print(f"✅ Modèle {OLLAMA_VISION_MODEL} disponible")
    except Exception as e:
        print(f"⚠️ Modèle {OLLAMA_VISION_MODEL} non trouvé. Installation requise.")
        print(f"   Commande: ollama pull {OLLAMA_VISION_MODEL}")
except Exception as e:
    print(f"⚠️ Erreur connexion Ollama: {e}")
    ollama_client = None

def validate_image(image_data: bytes) -> bool:
    """Valider que les données sont une image valide"""
    try:
        Image.open(io.BytesIO(image_data))
        return True
    except Exception:
        return False

def load_image_from_base64(base64_string: str) -> Optional[Image.Image]:
    """Charger image depuis base64 string"""
    try:
        # Retirer préfixe data:image/...;base64, si présent
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        
        image_data = base64.b64decode(base64_string)
        return Image.open(io.BytesIO(image_data))
    except Exception as e:
        print(f"Erreur décodage base64: {e}")
        return None

def generate_cache_key(image_data: bytes, prompt: str) -> str:
    """Générer clé de cache basée sur hash de l'image + prompt"""
    import hashlib
    hash_object = hashlib.md5(image_data + prompt.encode())
    return hash_object.hexdigest()

@app.route('/api/v1/ai/vision/analyze', methods=['POST'])
@limiter.limit("10 per minute")  # Limite spécifique pour analyse vision
def analyze_image():
    """
    Analyser une image avec modèle vision Ollama
    
    Body JSON:
        {
            "image": "base64_encoded_image" ou URL,
            "prompt": "Describe this image",
            "context": "optional context about the scene",
            "cache": true/false (default: true)
        }
    
    Returns:
        JSON avec description, detected_objects, scene_context, response_text
    """
    if ollama_client is None:
        return jsonify({'error': 'Ollama service unavailable'}), 503
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        image_data_base64 = data.get('image')
        prompt = data.get('prompt', 'Describe this image in detail.')
        context = data.get('context', '')
        use_cache = data.get('cache', True)
        
        if not image_data_base64:
            return jsonify({'error': 'No image provided'}), 400
        
        # Charger image
        image = load_image_from_base64(image_data_base64)
        if image is None:
            return jsonify({'error': 'Invalid image data'}), 400
        
        # Vérifier cache
        image_bytes = io.BytesIO()
        image.save(image_bytes, format='PNG')
        image_bytes = image_bytes.getvalue()
        
        cache_key = generate_cache_key(image_bytes, prompt)
        if use_cache and cache_key in request_cache:
            cached_result = request_cache[cache_key]
            if datetime.now() - cached_result['timestamp'] < timedelta(seconds=CACHE_TTL):
                return jsonify(cached_result['response']), 200
        
        # Construire prompt complet avec contexte
        full_prompt = prompt
        if context:
            full_prompt = f"Context: {context}\n\n{prompt}"
        
        # Appel Ollama
        start_time = time.time()
        response = ollama_client.generate(
            model=OLLAMA_VISION_MODEL,
            prompt=full_prompt,
            images=[image],  # Ollama accepte PIL Image directement
            options={
                'temperature': 0.7,
                'top_p': 0.9,
                'num_predict': 500  # Limiter longueur réponse
            }
        )
        elapsed_time = time.time() - start_time
        
        # Extraire réponse
        response_text = response.get('response', '')
        
        # Parser réponse pour extraire objets détectés (si format structuré)
        detected_objects = []
        scene_context = {}
        
        # Essayer d'extraire informations structurées de la réponse
        # (dépend du prompt et du format de réponse du modèle)
        if 'object' in response_text.lower() or 'detect' in response_text.lower():
            # Parsing basique (peut être amélioré avec prompts spécialisés)
            detected_objects = _parse_detected_objects(response_text)
        
        result = {
            'response_text': response_text,
            'detected_objects': detected_objects,
            'scene_context': scene_context,
            'processing_time': round(elapsed_time, 2),
            'model': OLLAMA_VISION_MODEL,
            'timestamp': datetime.now().isoformat()
        }
        
        # Mettre en cache
        if use_cache:
            request_cache[cache_key] = {
                'timestamp': datetime.now(),
                'response': result
            }
        
        return jsonify(result), 200
        
    except Exception as e:
        print(f"Erreur analyse image: {e}")
        return jsonify({'error': str(e)}), 500

def _parse_detected_objects(response_text: str) -> list:
    """Parser réponse textuelle pour extraire objets détectés"""
    # Parsing basique (peut être amélioré avec prompts spécialisés ou JSON mode)
    objects = []
    # Détection basique de mentions d'objets
    # En production, utiliser prompts structurés avec JSON mode si supporté
    return objects

@app.route('/api/v1/ai/vision/models', methods=['GET'])
@limiter.limit("30 per minute")
def list_models():
    """Lister modèles vision disponibles"""
    if ollama_client is None:
        return jsonify({'error': 'Ollama service unavailable'}), 503
    
    try:
        models = ollama_client.list()
        vision_models = [
            model for model in models.get('models', [])
            if 'vision' in model.get('name', '').lower() or 'llava' in model.get('name', '').lower()
        ]
        return jsonify({
            'available_models': vision_models,
            'current_model': OLLAMA_VISION_MODEL
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/ai/vision/models/<model_name>', methods=['POST'])
@limiter.limit("1 per hour")  # Limite stricte pour changement modèle
def switch_model(model_name: str):
    """Changer modèle vision utilisé"""
    global OLLAMA_VISION_MODEL
    if ollama_client is None:
        return jsonify({'error': 'Ollama service unavailable'}), 503
    
    try:
        # Vérifier que le modèle existe
        ollama_client.show(model_name)
        OLLAMA_VISION_MODEL = model_name
        return jsonify({
            'message': f'Model switched to {model_name}',
            'current_model': OLLAMA_VISION_MODEL
        }), 200
    except Exception as e:
        return jsonify({'error': f'Model {model_name} not found: {str(e)}'}), 404

@app.route('/api/v1/ai/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    is_healthy = ollama_client is not None
    if ollama_client:
        try:
            ollama_client.show(OLLAMA_VISION_MODEL)
            model_status = 'available'
        except Exception:
            model_status = 'unavailable'
    else:
        model_status = 'unavailable'
    
    return jsonify({
        'status': 'healthy' if is_healthy and model_status == 'available' else 'degraded',
        'ollama_connected': is_healthy,
        'model_status': model_status,
        'current_model': OLLAMA_VISION_MODEL
    }), 200 if is_healthy else 503

if __name__ == '__main__':
    print("🚀 Démarrage API Ollama Vision...")
    print(f"   Modèle: {OLLAMA_VISION_MODEL}")
    print(f"   Base URL: {OLLAMA_BASE_URL}")
    print(f"   Rate Limit: 100 req/min, 1000 req/hour")
    app.run(host='0.0.0.0', port=5001, debug=False)










