#!/usr/bin/env python3
"""
AI Workers
Workers pour Ollama vision et Stable Diffusion
"""

import os
import sys
from pathlib import Path
from typing import Dict, Any, Optional
import logging
import base64
import requests
from job_tracker import update_job_status
from job_models import JobStatus
from rq import get_current_job

logger = logging.getLogger(__name__)

# Ollama configuration
OLLAMA_BASE_URL = os.getenv('OLLAMA_BASE_URL', 'http://localhost:11434')
OLLAMA_VISION_MODEL = os.getenv('OLLAMA_VISION_MODEL', 'llava:latest')

# Stable Diffusion configuration
SD_WEBUI_URL = os.getenv('SD_WEBUI_URL', 'http://localhost:7860')

def process_ai_vision_job(
    job_id: str,
    image_path: str,
    prompt: str,
    user_id: str
) -> Dict[str, Any]:
    """
    Process AI vision analysis avec Ollama
    
    Args:
        job_id: Job ID
        image_path: Path to image file
        prompt: Analysis prompt
        user_id: User ID
        
    Returns:
        Result dict with analysis text
    """
    current_job = get_current_job()
    
    try:
        update_job_status(job_id, JobStatus.PROCESSING, progress=0)
        
        # Load image
        with open(image_path, 'rb') as f:
            image_data = f.read()
            image_base64 = base64.b64encode(image_data).decode('utf-8')
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=30)
        
        # Call Ollama API
        response = requests.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json={
                'model': OLLAMA_VISION_MODEL,
                'prompt': prompt,
                'images': [image_base64],
                'stream': False
            },
            timeout=120
        )
        
        response.raise_for_status()
        result = response.json()
        
        analysis_text = result.get('response', '')
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=80)
        
        # Cache result (optionnel)
        # ...
        
        # Get job info for notification
        from job_tracker import get_job
        job_info = get_job(job_id)
        asset_id = job_info.get('asset_id') if job_info else None
        
        update_job_status(job_id, JobStatus.COMPLETED, progress=100)
        
        # Send email notification
        try:
            from queue.job_notifications import notify_job_completion
            notify_job_completion(
                job_id=job_id,
                user_id=user_id,
                job_type='ai_generation',
                asset_id=asset_id,
                asset_name=f"Génération IA {job_id[:8]}"
            )
        except Exception as e:
            logger.warning(f"Failed to send completion notification: {e}")
        
        return {
            'success': True,
            'analysis_text': analysis_text,
            'job_id': job_id
        }
    
    except Exception as e:
        logger.error(f"Error processing AI vision job {job_id}: {e}")
        update_job_status(
            job_id,
            JobStatus.FAILED,
            progress=0,
            error_message=str(e)
        )
        raise

def process_ai_generation_job(
    job_id: str,
    generation_type: str,  # 'txt2img', 'img2img', 'inpainting'
    prompt: str,
    user_id: str,
    config: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Process AI generation avec Stable Diffusion
    
    Args:
        job_id: Job ID
        generation_type: Type of generation
        prompt: Generation prompt
        user_id: User ID
        config: Generation config
        
    Returns:
        Result dict with image URL
    """
    current_job = get_current_job()
    
    try:
        update_job_status(job_id, JobStatus.PROCESSING, progress=0)
        
        if config is None:
            config = {}
        
        # Prepare request selon type
        if generation_type == 'txt2img':
            sd_request = {
                'prompt': prompt,
                'negative_prompt': config.get('negative_prompt', ''),
                'steps': config.get('steps', 20),
                'cfg_scale': config.get('cfg_scale', 7.5),
                'width': config.get('width', 512),
                'height': config.get('height', 512),
                'seed': config.get('seed', -1)
            }
            endpoint = f"{SD_WEBUI_URL}/sdapi/v1/txt2img"
        
        elif generation_type == 'img2img':
            # Load input image
            input_image_path = config.get('input_image')
            with open(input_image_path, 'rb') as f:
                input_image_data = base64.b64encode(f.read()).decode('utf-8')
            
            sd_request = {
                'init_images': [input_image_data],
                'prompt': prompt,
                'steps': config.get('steps', 20),
                'denoising_strength': config.get('denoising_strength', 0.75)
            }
            endpoint = f"{SD_WEBUI_URL}/sdapi/v1/img2img"
        
        else:
            raise ValueError(f"Unsupported generation type: {generation_type}")
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=20)
        
        # Call Stable Diffusion API
        response = requests.post(
            endpoint,
            json=sd_request,
            timeout=300
        )
        
        response.raise_for_status()
        result = response.json()
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=80)
        
        # Get generated image
        if 'images' in result and len(result['images']) > 0:
            image_base64 = result['images'][0]
            image_data = base64.b64decode(image_base64.split(',')[1] if ',' in image_base64 else image_base64)
            
            # Upload to R2
            from api.r2_client import upload_file
            
            key = f"ai_generated/{user_id}/{job_id}/image.png"
            image_url = upload_file(
                image_data,
                key,
                'image/png'
            )
            
            # Get job info for notification
            from job_tracker import get_job
            job_info = get_job(job_id)
            asset_id = job_info.get('asset_id') if job_info else None
            
            update_job_status(
                job_id,
                JobStatus.COMPLETED,
                progress=100,
                output_url=image_url
            )
            
            # Send email notification
            try:
                from queue.job_notifications import notify_job_completion
                notify_job_completion(
                    job_id=job_id,
                    user_id=user_id,
                    job_type='ai_generation',
                    asset_id=asset_id,
                    asset_url=image_url,
                    asset_name=f"Image générée {job_id[:8]}"
                )
            except Exception as e:
                logger.warning(f"Failed to send completion notification: {e}")
            
            return {
                'success': True,
                'image_url': image_url,
                'seed': result.get('seed'),
                'job_id': job_id
            }
        else:
            raise ValueError("No image generated")
    
    except Exception as e:
        logger.error(f"Error processing AI generation job {job_id}: {e}")
        update_job_status(
            job_id,
            JobStatus.FAILED,
            progress=0,
            error_message=str(e)
        )
        raise

