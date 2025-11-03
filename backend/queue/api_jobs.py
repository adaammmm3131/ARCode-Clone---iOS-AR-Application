#!/usr/bin/env python3
"""
API Endpoints pour Jobs
Flask routes pour soumettre et suivre les jobs
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from job_service import (
    submit_photogrammetry_job,
    submit_gaussian_splatting_job,
    submit_ai_vision_job,
    submit_ai_generation_job,
    submit_mesh_optimization_job,
    get_job_status
)
from job_models import JobType, JobPriority
from auth_supabase import require_auth
from typing import Dict, Any

app = Flask(__name__)
CORS(app)

@app.route('/api/v1/jobs/photogrammetry', methods=['POST'])
@require_auth
def create_photogrammetry_job(user: Dict[str, Any]):
    """Submit photogrammetry job"""
    data = request.json
    video_path = data.get('video_path')
    priority = JobPriority(data.get('priority', 'default'))
    
    if not video_path:
        return jsonify({'error': 'video_path required'}), 400
    
    job_id = submit_photogrammetry_job(
        user_id=user['sub'],
        video_path=video_path,
        asset_id=data.get('asset_id'),
        priority=priority
    )
    
    return jsonify({
        'job_id': job_id,
        'status': 'queued'
    }), 201

@app.route('/api/v1/jobs/gaussian-splatting', methods=['POST'])
@require_auth
def create_gaussian_splatting_job(user: Dict[str, Any]):
    """Submit Gaussian Splatting job"""
    data = request.json
    video_path = data.get('video_path')
    config = data.get('config', {})
    
    if not video_path:
        return jsonify({'error': 'video_path required'}), 400
    
    job_id = submit_gaussian_splatting_job(
        user_id=user['sub'],
        video_path=video_path,
        config=config,
        asset_id=data.get('asset_id')
    )
    
    return jsonify({
        'job_id': job_id,
        'status': 'queued'
    }), 201

@app.route('/api/v1/jobs/ai-vision', methods=['POST'])
@require_auth
def create_ai_vision_job(user: Dict[str, Any]):
    """Submit AI vision job"""
    data = request.json
    image_path = data.get('image_path')
    prompt = data.get('prompt', 'Describe this image')
    
    if not image_path:
        return jsonify({'error': 'image_path required'}), 400
    
    job_id = submit_ai_vision_job(
        user_id=user['sub'],
        image_path=image_path,
        prompt=prompt
    )
    
    return jsonify({
        'job_id': job_id,
        'status': 'queued'
    }), 201

@app.route('/api/v1/jobs/ai-generation', methods=['POST'])
@require_auth
def create_ai_generation_job(user: Dict[str, Any]):
    """Submit AI generation job"""
    data = request.json
    generation_type = data.get('type')  # txt2img, img2img, inpainting
    prompt = data.get('prompt')
    config = data.get('config', {})
    
    if not generation_type or not prompt:
        return jsonify({'error': 'type and prompt required'}), 400
    
    job_id = submit_ai_generation_job(
        user_id=user['sub'],
        generation_type=generation_type,
        prompt=prompt,
        config=config
    )
    
    return jsonify({
        'job_id': job_id,
        'status': 'queued'
    }), 201

@app.route('/api/v1/jobs/<job_id>', methods=['GET'])
@require_auth
def get_job(job_id: str, user: Dict[str, Any]):
    """Get job status"""
    job = get_job_status(job_id)
    
    if not job:
        return jsonify({'error': 'Job not found'}), 404
    
    # Verify user owns job
    if job['user_id'] != user['sub']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    return jsonify(job), 200

@app.route('/api/v1/jobs', methods=['GET'])
@require_auth
def list_user_jobs(user: Dict[str, Any]):
    """List user's jobs"""
    from job_tracker import get_user_jobs
    
    limit = int(request.args.get('limit', 50))
    jobs = get_user_jobs(user['sub'], limit)
    
    return jsonify({
        'jobs': jobs,
        'count': len(jobs)
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)









