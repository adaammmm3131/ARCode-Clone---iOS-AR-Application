#!/usr/bin/env python3
"""
Gaussian Splatting Worker
Worker pour training Gaussian Splatting avec Nerfstudio
"""

import os
import sys
from pathlib import Path
from typing import Dict, Any
import logging
import subprocess
from job_tracker import update_job_status
from job_models import JobStatus
from rq import get_current_job

logger = logging.getLogger(__name__)

def process_gaussian_splatting_job(
    job_id: str,
    video_path: str,
    user_id: str,
    config: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Process Gaussian Splatting job avec Nerfstudio
    
    Args:
        job_id: Job ID
        video_path: Path to video file
        user_id: User ID
        config: Training configuration
        
    Returns:
        Result dict with splat file URL
    """
    current_job = get_current_job()
    
    try:
        update_job_status(job_id, JobStatus.PROCESSING, progress=0)
        
        # Workspace
        workspace = Path(f"/tmp/gaussian/processing/{job_id}")
        workspace.mkdir(parents=True, exist_ok=True)
        
        # Extract frames (progress 10-30%)
        frames_dir = workspace / "frames"
        frames_dir.mkdir(exist_ok=True)
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=10)
        
        # Extract frames avec ffmpeg
        subprocess.run([
            'ffmpeg', '-i', video_path,
            '-vf', 'fps=30',
            str(frames_dir / 'frame_%06d.jpg')
        ], check=True)
        
        frame_count = len(list(frames_dir.glob('*.jpg')))
        if frame_count < 100:
            raise ValueError(f"Insufficient frames: {frame_count} < 100")
        
        update_job_status(job_id, JobStatus.PROCESSING, progress=30)
        
        # Training avec Nerfstudio (progress 30-90%)
        output_dir = workspace / "output"
        output_dir.mkdir(exist_ok=True)
        
        # Run training (simplifié - ajuster selon setup Nerfstudio)
        training_cmd = [
            'ns-train', 'gaussian-splatting',
            '--data', str(frames_dir),
            '--output-dir', str(output_dir),
            '--max-num-iterations', str(config.get('max_iterations', 30000)),
            '--save-interval', '5000'
        ]
        
        # Monitor training progress
        process = subprocess.Popen(
            training_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Monitor output pour progress updates
        progress = 30
        for line in process.stdout:
            if current_job:
                current_job.meta['training_log'] = line
                current_job.save_meta()
            
            # Parse progress depuis logs (ajuster selon format Nerfstudio)
            if 'iteration' in line.lower():
                progress = min(90, 30 + (int(line.split()[1]) / config.get('max_iterations', 30000)) * 60)
                update_job_status(job_id, JobStatus.PROCESSING, progress=int(progress))
        
        process.wait()
        
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, training_cmd)
        
        # Export PLY file (progress 90-95%)
        update_job_status(job_id, JobStatus.PROCESSING, progress=90)
        
        ply_output = output_dir / "splat.ply"
        
        # Export command (ajuster selon Nerfstudio)
        export_cmd = [
            'ns-export', 'gaussian-splatting',
            '--load-config', str(output_dir / "config.yml"),
            '--output-dir', str(output_dir),
            '--format', 'ply'
        ]
        
        subprocess.run(export_cmd, check=True)
        
        # Upload to R2 (progress 95-100%)
        update_job_status(job_id, JobStatus.PROCESSING, progress=95)
        
        from api.r2_client import upload_file
        
        if ply_output.exists():
            with open(ply_output, 'rb') as f:
                ply_data = f.read()
                key = f"splats/{user_id}/{job_id}/splat.ply"
                splat_url = upload_file(
                    ply_data,
                    key,
                    'application/octet-stream'
                )
            
            # Get job info for notification
            from job_tracker import get_job
            job_info = get_job(job_id)
            asset_id = job_info.get('asset_id') if job_info else None
            
            update_job_status(
                job_id,
                JobStatus.COMPLETED,
                progress=100,
                output_url=splat_url
            )
            
            # Send email notification
            try:
                from queue.job_notifications import notify_job_completion
                notify_job_completion(
                    job_id=job_id,
                    user_id=user_id,
                    job_type='gaussian',
                    asset_id=asset_id,
                    asset_url=splat_url,
                    asset_name=f"Gaussian Splatting {job_id[:8]}"
                )
            except Exception as e:
                logger.warning(f"Failed to send completion notification: {e}")
            
            return {
                'success': True,
                'splat_url': splat_url,
                'job_id': job_id
            }
        else:
            raise FileNotFoundError("PLY file not generated")
    
    except Exception as e:
        logger.error(f"Error processing Gaussian Splatting job {job_id}: {e}")
        update_job_status(
            job_id,
            JobStatus.FAILED,
            progress=0,
            error_message=str(e)
        )
        raise

