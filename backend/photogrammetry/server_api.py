#!/usr/bin/env python3
"""
API Serveur pour Photogrammétrie
Endpoints REST pour upload, processing, status, download
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import uuid
from pathlib import Path
from datetime import datetime
import json
import subprocess
import threading
from typing import Dict

app = Flask(__name__)
CORS(app)  # Permettre requêtes cross-origin

# Configuration
UPLOAD_FOLDER = Path('/tmp/photogrammetry/uploads')
PROCESSING_FOLDER = Path('/tmp/photogrammetry/processing')
RESULTS_FOLDER = Path('/tmp/photogrammetry/results')

UPLOAD_FOLDER.mkdir(parents=True, exist_ok=True)
PROCESSING_FOLDER.mkdir(parents=True, exist_ok=True)
RESULTS_FOLDER.mkdir(parents=True, exist_ok=True)

# Jobs tracking
processing_jobs = {}

@app.route('/api/v1/photogrammetry/upload', methods=['POST'])
def upload_video():
    """
    Upload vidéo pour photogrammétrie
    
    Returns:
        JSON avec job_id et status
    """
    if 'video' not in request.files:
        return jsonify({'error': 'Aucun fichier vidéo'}), 400
    
    video_file = request.files['video']
    
    # Validation
    if video_file.filename == '':
        return jsonify({'error': 'Fichier vide'}), 400
    
    allowed_extensions = {'.mp4', '.mov', '.MOV', '.MP4'}
    if not any(video_file.filename.endswith(ext) for ext in allowed_extensions):
        return jsonify({'error': 'Format non supporté (MP4/MOV requis)'}), 400
    
    # Générer job ID
    job_id = str(uuid.uuid4())
    upload_path = UPLOAD_FOLDER / f"{job_id}_{video_file.filename}"
    
    # Sauvegarder vidéo
    video_file.save(str(upload_path))
    
    # Vérifier taille
    file_size_mb = upload_path.stat().st_size / (1024 * 1024)
    if file_size_mb > 250:
        upload_path.unlink()
        return jsonify({'error': 'Fichier trop volumineux (max 250MB)'}), 400
    
    # Créer job
    job = {
        'job_id': job_id,
        'status': 'uploaded',
        'upload_path': str(upload_path),
        'created_at': datetime.now().isoformat(),
        'progress': 0,
        'stages': {}
    }
    
    processing_jobs[job_id] = job
    
    # Démarrer processing en background
    thread = threading.Thread(target=process_video, args=(job_id, str(upload_path)))
    thread.daemon = True
    thread.start()
    
    return jsonify({
        'job_id': job_id,
        'status': 'uploaded',
        'message': 'Vidéo uploadée, processing démarré'
    }), 200

def process_video(job_id: str, video_path: str):
    """
    Traite la vidéo en background
    
    Args:
        job_id: ID du job
        video_path: Chemin vidéo
    """
    job = processing_jobs[job_id]
    
    try:
        job['status'] = 'processing'
        job['progress'] = 10
        
        # Workspace pour ce job
        workspace = PROCESSING_FOLDER / job_id
        workspace.mkdir(parents=True, exist_ok=True)
        
        # Pipeline complet
        from pipeline import PhotogrammetryPipeline
        
        pipeline = PhotogrammetryPipeline(str(workspace))
        
        job['progress'] = 20
        results = pipeline.run_full_pipeline(video_path, extract_fps=30)
        
        if results['success']:
            job['status'] = 'completed'
            job['progress'] = 100
            job['results'] = results
            
            # Copier résultats vers dossier final
            results_dir = RESULTS_FOLDER / job_id
            results_dir.mkdir(parents=True, exist_ok=True)
            
            # TODO: Copier fichiers mesh/GLB vers results_dir
            
            job['results_path'] = str(results_dir)
        else:
            job['status'] = 'failed'
            job['error'] = results.get('error', 'Processing failed')
            
    except Exception as e:
        job['status'] = 'failed'
        job['error'] = str(e)
        job['progress'] = 0

@app.route('/api/v1/photogrammetry/status/<job_id>', methods=['GET'])
def get_job_status(job_id: str):
    """
    Obtient status d'un job
    
    Args:
        job_id: ID du job
        
    Returns:
        JSON avec status et progression
    """
    if job_id not in processing_jobs:
        return jsonify({'error': 'Job non trouvé'}), 404
    
    job = processing_jobs[job_id]
    
    return jsonify({
        'job_id': job_id,
        'status': job['status'],
        'progress': job.get('progress', 0),
        'created_at': job['created_at'],
        'stages': job.get('stages', {}),
        'error': job.get('error')
    }), 200

@app.route('/api/v1/photogrammetry/download/<job_id>', methods=['GET'])
def download_results(job_id: str):
    """
    Télécharge résultats (GLB/USDZ)
    
    Args:
        job_id: ID du job
        
    Returns:
        Fichier GLB/USDZ
    """
    if job_id not in processing_jobs:
        return jsonify({'error': 'Job non trouvé'}), 404
    
    job = processing_jobs[job_id]
    
    if job['status'] != 'completed':
        return jsonify({'error': 'Job non terminé'}), 400
    
    # Format demandé (GLB par défaut)
    format_type = request.args.get('format', 'glb').lower()
    
    # Chercher fichier résultat
    results_path = Path(job.get('results_path', ''))
    
    if format_type == 'glb':
        glb_file = results_path / 'mesh_high.glb'
        if glb_file.exists():
            return send_file(str(glb_file), as_attachment=True, mimetype='model/gltf-binary')
    
    return jsonify({'error': 'Fichier résultat non trouvé'}), 404

@app.route('/api/v1/photogrammetry/preview/<job_id>', methods=['GET'])
def get_preview(job_id: str):
    """
    Obtient preview 3D (thumbnail ou snapshot)
    
    Args:
        job_id: ID du job
        
    Returns:
        Image preview
    """
    # TODO: Générer thumbnail/preview du mesh
    return jsonify({'error': 'Preview non implémenté'}), 501

if __name__ == '__main__':
    # Configuration serveur
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)










