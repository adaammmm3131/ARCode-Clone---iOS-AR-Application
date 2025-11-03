#!/usr/bin/env python3
"""
COLMAP Worker
Worker pour traitement photogrammetry avec COLMAP
"""

import os
import sys
from pathlib import Path
from typing import Dict, Any
import logging
from job_tracker import update_job_status, get_job
from job_models import JobStatus
from rq import get_current_job

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent.parent))

from photogrammetry.pipeline import PhotogrammetryPipeline

logger = logging.getLogger(__name__)

def process_photogrammetry_job(job_id: str, video_path: str, user_id: str) -> Dict[str, Any]:
    """
    Process photogrammetry job avec COLMAP
    
    Args:
        job_id: Job ID
        video_path: Path to video file
        user_id: User ID
        
    Returns:
        Result dict with output URLs
    """
    current_job = get_current_job()
    
    try:
        # Update status to processing
        update_job_status(job_id, JobStatus.PROCESSING, progress=0)
        
        # Workspace
        workspace = Path(f"/tmp/photogrammetry/processing/{job_id}")
        workspace.mkdir(parents=True, exist_ok=True)
        
        # Initialize pipeline
        pipeline = PhotogrammetryPipeline(str(workspace))
        
        # Update progress
        def progress_callback(stage: str, progress: int, message: str):
            """Callback pour updates progression"""
            update_job_status(job_id, JobStatus.PROCESSING, progress=progress)
            if current_job:
                current_job.meta['stage'] = stage
                current_job.meta['message'] = message
                current_job.save_meta()
        
        # Run pipeline
        update_job_status(job_id, JobStatus.PROCESSING, progress=10)
        results = pipeline.run_full_pipeline(
            video_path,
            extract_fps=30,
            progress_callback=progress_callback
        )
        
        if results.get('success'):
            # Upload results to R2
            from api.r2_client import upload_file
            
            output_urls = {}
            
            # Upload GLB model
            if results.get('glb_path'):
                with open(results['glb_path'], 'rb') as f:
                    glb_data = f.read()
                    key = f"models/{user_id}/{job_id}/model.glb"
                    output_urls['glb_url'] = upload_file(
                        glb_data,
                        key,
                        'model/gltf-binary'
                    )
            
            # Upload USDZ model
            if results.get('usdz_path'):
                with open(results['usdz_path'], 'rb') as f:
                    usdz_data = f.read()
                    key = f"models/{user_id}/{job_id}/model.usdz"
                    output_urls['usdz_url'] = upload_file(
                        usdz_data,
                        key,
                        'model/vnd.usdz+zip'
                    )
            
            # Get job info for notification
            job_info = get_job(job_id)
            asset_id = job_info.get('asset_id') if job_info else None
            
            # Update job as completed
            update_job_status(
                job_id,
                JobStatus.COMPLETED,
                progress=100,
                output_url=output_urls.get('glb_url')
            )
            
            # Send email notification
            try:
                from queue.job_notifications import notify_job_completion
                notify_job_completion(
                    job_id=job_id,
                    user_id=user_id,
                    job_type='photogrammetry',
                    asset_id=asset_id,
                    asset_url=output_urls.get('glb_url'),
                    asset_name=f"Modèle 3D {job_id[:8]}"
                )
            except Exception as e:
                logger.warning(f"Failed to send completion notification: {e}")
            
            return {
                'success': True,
                'output_urls': output_urls,
                'job_id': job_id
            }
        else:
            # Job failed
            error_msg = results.get('error', 'Processing failed')
            update_job_status(
                job_id,
                JobStatus.FAILED,
                progress=0,
                error_message=error_msg
            )
            return {
                'success': False,
                'error': error_msg
            }
    
    except Exception as e:
        logger.error(f"Error processing photogrammetry job {job_id}: {e}")
        update_job_status(
            job_id,
            JobStatus.FAILED,
            progress=0,
            error_message=str(e)
        )
        raise

