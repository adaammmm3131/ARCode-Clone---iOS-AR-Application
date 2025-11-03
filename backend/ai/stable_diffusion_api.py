#!/usr/bin/env python3
"""
API Serveur pour Stable Diffusion
Endpoints REST pour txt2img, img2img, inpainting, model management
Support GPU/CPU fallback, SDXL, SD 1.5
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os
import base64
import io
import uuid
from pathlib import Path
from datetime import datetime
import json
from typing import Dict, Optional
from PIL import Image
import torch
import requests
import time

app = Flask(__name__)
CORS(app)

# Rate Limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["50 per minute", "500 per hour"],
    storage_uri="memory://"
)

# Configuration
UPLOAD_FOLDER = Path('/tmp/sd/uploads')
RESULTS_FOLDER = Path('/tmp/sd/results')
MODELS_FOLDER = Path('/tmp/sd/models')

UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)
RESULTS_FOLDER.mkdir(parents=True, exist_ok=True)
MODELS_FOLDER.mkdir(parents=True, exist_ok=True)

# Configuration Stable Diffusion
SD_WEBUI_URL = os.getenv('SD_WEBUI_URL', 'http://localhost:7860')
SD_MODEL = os.getenv('SD_MODEL', 'sd-v1-5')  # ou 'sdxl' pour SDXL
USE_GPU = os.getenv('USE_GPU', 'true').lower() == 'true'
CPU_FALLBACK = os.getenv('CPU_FALLBACK', 'true').lower() == 'true'

# Cache pour résultats
result_cache: Dict[str, Dict] = {}
CACHE_TTL = 7200  # 2 heures

def check_sd_webui_available() -> bool:
    """Vérifier si Stable Diffusion WebUI est accessible"""
    try:
        response = requests.get(f"{SD_WEBUI_URL}/sdapi/v1/ping", timeout=5)
        return response.status_code == 200
    except Exception:
        return False

def load_image_from_base64(base64_string: str) -> Optional[Image.Image]:
    """Charger image depuis base64"""
    try:
        if ',' in base64_string:
            base64_string = base64_string.split(',')[1]
        image_data = base64.b64decode(base64_string)
        return Image.open(io.BytesIO(image_data))
    except Exception as e:
        print(f"Erreur décodage image: {e}")
        return None

@app.route('/api/v1/ai/generation/txt2img', methods=['POST'])
@limiter.limit("10 per minute")  # Limite pour génération
def txt2img():
    """
    Text-to-Image avec Stable Diffusion
    
    Body:
        {
            "prompt": "a beautiful landscape",
            "negative_prompt": "blurry, low quality",
            "steps": 20,
            "cfg_scale": 7.5,
            "width": 512,
            "height": 512,
            "seed": -1,
            "model": "sd-v1-5" ou "sdxl"
        }
    """
    if not check_sd_webui_available():
        return jsonify({'error': 'Stable Diffusion WebUI unavailable'}), 503
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        prompt = data.get('prompt', '')
        negative_prompt = data.get('negative_prompt', 'blurry, low quality, distorted')
        steps = data.get('steps', 20)
        cfg_scale = data.get('cfg_scale', 7.5)
        width = data.get('width', 512)
        height = data.get('height', 512)
        seed = data.get('seed', -1)
        model_name = data.get('model', SD_MODEL)
        
        if not prompt:
            return jsonify({'error': 'Prompt required'}), 400
        
        # Préparer payload pour SD WebUI API
        payload = {
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "steps": steps,
            "cfg_scale": cfg_scale,
            "width": width,
            "height": height,
            "seed": seed,
            "sampler_index": "DPM++ 2M Karras",  # Sampler rapide et de qualité
            "batch_size": 1,
            "n_iter": 1
        }
        
        # Appel SD WebUI API
        start_time = time.time()
        response = requests.post(
            f"{SD_WEBUI_URL}/sdapi/v1/txt2img",
            json=payload,
            timeout=300  # 5 minutes max
        )
        elapsed_time = time.time() - start_time
        
        if response.status_code != 200:
            return jsonify({'error': f'SD WebUI error: {response.text}'}), 500
        
        result = response.json()
        
        # Extraire image générée (base64)
        if 'images' in result and len(result['images']) > 0:
            image_base64 = result['images'][0]
            
            # Sauvegarder image
            image_id = str(uuid.uuid4())
            image_data = base64.b64decode(image_base64)
            image_path = RESULTS_FOLDER / f"{image_id}.png"
            Image.open(io.BytesIO(image_data)).save(image_path)
            
            return jsonify({
                'image_id': image_id,
                'image_url': f'/api/v1/ai/generation/image/{image_id}',
                'image_base64': f'data:image/png;base64,{image_base64}',
                'seed': result.get('seed', seed),
                'info': result.get('info', ''),
                'processing_time': round(elapsed_time, 2),
                'model': model_name
            }), 200
        else:
            return jsonify({'error': 'No image generated'}), 500
            
    except Exception as e:
        print(f"Erreur txt2img: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/ai/generation/img2img', methods=['POST'])
@limiter.limit("10 per minute")
def img2img():
    """
    Image-to-Image avec Stable Diffusion
    
    Body:
        {
            "image": "base64_encoded_image",
            "prompt": "transform this image",
            "strength": 0.75,
            "steps": 20,
            ...
        }
    """
    if not check_sd_webui_available():
        return jsonify({'error': 'Stable Diffusion WebUI unavailable'}), 503
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        image_base64 = data.get('image')
        prompt = data.get('prompt', '')
        negative_prompt = data.get('negative_prompt', '')
        strength = data.get('strength', 0.75)  # 0.0-1.0, force transformation
        steps = data.get('steps', 20)
        cfg_scale = data.get('cfg_scale', 7.5)
        
        if not image_base64 or not prompt:
            return jsonify({'error': 'Image and prompt required'}), 400
        
        # Charger image
        image = load_image_from_base64(image_base64)
        if image is None:
            return jsonify({'error': 'Invalid image data'}), 400
        
        # Convertir en base64 pour SD WebUI
        buffer = io.BytesIO()
        image.save(buffer, format='PNG')
        image_base64_for_sd = base64.b64encode(buffer.getvalue()).decode()
        
        payload = {
            "init_images": [image_base64_for_sd],
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "denoising_strength": strength,
            "steps": steps,
            "cfg_scale": cfg_scale,
            "sampler_index": "DPM++ 2M Karras",
            "batch_size": 1
        }
        
        start_time = time.time()
        response = requests.post(
            f"{SD_WEBUI_URL}/sdapi/v1/img2img",
            json=payload,
            timeout=300
        )
        elapsed_time = time.time() - start_time
        
        if response.status_code != 200:
            return jsonify({'error': f'SD WebUI error: {response.text}'}), 500
        
        result = response.json()
        
        if 'images' in result and len(result['images']) > 0:
            output_image_base64 = result['images'][0]
            
            image_id = str(uuid.uuid4())
            image_data = base64.b64decode(output_image_base64)
            image_path = RESULTS_FOLDER / f"{image_id}.png"
            Image.open(io.BytesIO(image_data)).save(image_path)
            
            return jsonify({
                'image_id': image_id,
                'image_url': f'/api/v1/ai/generation/image/{image_id}',
                'image_base64': f'data:image/png;base64,{output_image_base64}',
                'processing_time': round(elapsed_time, 2)
            }), 200
        else:
            return jsonify({'error': 'No image generated'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/ai/generation/inpainting', methods=['POST'])
@limiter.limit("10 per minute")
def inpainting():
    """
    Inpainting avec Stable Diffusion (pour virtual try-on)
    
    Body:
        {
            "image": "base64_encoded_image",
            "mask": "base64_encoded_mask",
            "prompt": "wear this clothing",
            "strength": 0.9,
            ...
        }
    """
    if not check_sd_webui_available():
        return jsonify({'error': 'Stable Diffusion WebUI unavailable'}), 503
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        image_base64 = data.get('image')
        mask_base64 = data.get('mask')
        prompt = data.get('prompt', '')
        negative_prompt = data.get('negative_prompt', 'blurry, artifacts, distorted')
        strength = data.get('strength', 0.9)
        steps = data.get('steps', 30)
        
        if not image_base64 or not mask_base64 or not prompt:
            return jsonify({'error': 'Image, mask, and prompt required'}), 400
        
        # Charger image et mask
        image = load_image_from_base64(image_base64)
        mask = load_image_from_base64(mask_base64)
        
        if image is None or mask is None:
            return jsonify({'error': 'Invalid image or mask data'}), 400
        
        # Convertir en base64
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG')
        img_b64 = base64.b64encode(img_buffer.getvalue()).decode()
        
        mask_buffer = io.BytesIO()
        mask.save(mask_buffer, format='PNG')
        mask_b64 = base64.b64encode(mask_buffer.getvalue()).decode()
        
        payload = {
            "init_images": [img_b64],
            "mask": mask_b64,
            "prompt": prompt,
            "negative_prompt": negative_prompt,
            "denoising_strength": strength,
            "steps": steps,
            "cfg_scale": 7.5,
            "sampler_index": "DPM++ 2M Karras",
            "inpainting_fill": 1,  # Original
            "inpaint_full_res": True,
            "inpaint_full_res_padding": 32
        }
        
        start_time = time.time()
        response = requests.post(
            f"{SD_WEBUI_URL}/sdapi/v1/img2img",
            json=payload,
            timeout=300
        )
        elapsed_time = time.time() - start_time
        
        if response.status_code != 200:
            return jsonify({'error': f'SD WebUI error: {response.text}'}), 500
        
        result = response.json()
        
        if 'images' in result and len(result['images']) > 0:
            output_image_base64 = result['images'][0]
            
            image_id = str(uuid.uuid4())
            image_data = base64.b64decode(output_image_base64)
            image_path = RESULTS_FOLDER / f"{image_id}.png"
            Image.open(io.BytesIO(image_data)).save(image_path)
            
            return jsonify({
                'image_id': image_id,
                'image_url': f'/api/v1/ai/generation/image/{image_id}',
                'image_base64': f'data:image/png;base64,{output_image_base64}',
                'processing_time': round(elapsed_time, 2)
            }), 200
        else:
            return jsonify({'error': 'No image generated'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/ai/generation/models', methods=['GET'])
@limiter.limit("30 per minute")
def list_models():
    """Lister modèles disponibles"""
    try:
        response = requests.get(f"{SD_WEBUI_URL}/sdapi/v1/sd-models", timeout=10)
        if response.status_code == 200:
            models = response.json()
            return jsonify({
                'available_models': models,
                'current_model': SD_MODEL
            }), 200
        else:
            return jsonify({'error': 'Failed to fetch models'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/ai/generation/image/<image_id>', methods=['GET'])
def get_image(image_id: str):
    """Récupérer image générée"""
    image_path = RESULTS_FOLDER / f"{image_id}.png"
    if image_path.exists():
        return send_file(str(image_path), mimetype='image/png')
    else:
        return jsonify({'error': 'Image not found'}), 404

@app.route('/api/v1/ai/generation/health', methods=['GET'])
def health_check():
    """Health check"""
    is_available = check_sd_webui_available()
    return jsonify({
        'status': 'healthy' if is_available else 'degraded',
        'sd_webui_available': is_available,
        'webui_url': SD_WEBUI_URL,
        'current_model': SD_MODEL,
        'gpu_enabled': USE_GPU,
        'cpu_fallback': CPU_FALLBACK
    }), 200 if is_available else 503

if __name__ == '__main__':
    print("🚀 Démarrage API Stable Diffusion...")
    print(f"   WebUI URL: {SD_WEBUI_URL}")
    print(f"   Modèle: {SD_MODEL}")
    print(f"   GPU: {USE_GPU}, CPU Fallback: {CPU_FALLBACK}")
    print(f"   Rate Limit: 50 req/min, 500 req/hour")
    app.run(host='0.0.0.0', port=5002, debug=False)










