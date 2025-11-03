#!/usr/bin/env python3
"""
Job Service
Service principal pour soumettre et gérer les jobs
"""

import os
import uuid
from typing import Dict, Any, Optional
from datetime import datetime
from job_models import ProcessingJob, JobType, JobStatus, JobPriority
from job_tracker import create_job, get_job as get_job_db
from rq_config import get_queue
from rq import Retry
from webhooks import trigger_webhook, WebhookEvent

# Import workers
from workers.colmap_worker import process_photogrammetry_job
from workers.gaussian_worker import process_gaussian_splatting_job
from workers.ai_worker import process_ai_vision_job, process_ai_generation_job
from workers.mesh_worker import process_mesh_optimization_job

def submit_photogrammetry_job(
    user_id: str,
    video_path: str,
    asset_id: Optional[str] = None,
    priority: JobPriority = JobPriority.DEFAULT
) -> str:
    """Submit photogrammetry job"""
    job_id = str(uuid.uuid4())
    
    # Create job in database
    job = ProcessingJob(
        job_id=job_id,
        job_type=JobType.PHOTOGRAMMETRY,
        user_id=user_id,
        asset_id=asset_id,
        input_url=video_path,
        status=JobStatus.PENDING,
        priority=priority
    )
    
    create_job(job)
    
    # Queue job
    queue = get_queue(priority.value)
    queue.enqueue(
        process_photogrammetry_job,
        job_id,
        video_path,
        user_id,
        job_id=job_id,
        retry=Retry(max=3, interval=[60, 120, 300]),
        timeout=3600  # 1 hour
    )
    
    # Trigger webhook
    trigger_webhook(
        WebhookEvent.PROCESSING_COMPLETED if priority == JobPriority.HIGH else None,
        {'job_id': job_id, 'type': 'photogrammetry'},
        user_id=user_id
    )
    
    return job_id

def submit_gaussian_splatting_job(
    user_id: str,
    video_path: str,
    config: Dict[str, Any],
    asset_id: Optional[str] = None,
    priority: JobPriority = JobPriority.LOW  # Gaussian Splatting prend du temps
) -> str:
    """Submit Gaussian Splatting job"""
    job_id = str(uuid.uuid4())
    
    job = ProcessingJob(
        job_id=job_id,
        job_type=JobType.GAUSSIAN_SPLATTING,
        user_id=user_id,
        asset_id=asset_id,
        input_url=video_path,
        status=JobStatus.PENDING,
        priority=priority,
        metadata=config
    )
    
    create_job(job)
    
    queue = get_queue(priority.value)
    queue.enqueue(
        process_gaussian_splatting_job,
        job_id,
        video_path,
        user_id,
        config,
        job_id=job_id,
        retry=Retry(max=2, interval=[300, 600]),
        timeout=7200  # 2 hours
    )
    
    return job_id

def submit_ai_vision_job(
    user_id: str,
    image_path: str,
    prompt: str,
    priority: JobPriority = JobPriority.HIGH  # AI vision est rapide
) -> str:
    """Submit AI vision job"""
    job_id = str(uuid.uuid4())
    
    job = ProcessingJob(
        job_id=job_id,
        job_type=JobType.AI_VISION,
        user_id=user_id,
        input_url=image_path,
        status=JobStatus.PENDING,
        priority=priority,
        metadata={'prompt': prompt}
    )
    
    create_job(job)
    
    queue = get_queue(priority.value)
    queue.enqueue(
        process_ai_vision_job,
        job_id,
        image_path,
        prompt,
        user_id,
        job_id=job_id,
        retry=Retry(max=2, interval=[10, 30]),
        timeout=180  # 3 minutes
    )
    
    return job_id

def submit_ai_generation_job(
    user_id: str,
    generation_type: str,
    prompt: str,
    config: Dict[str, Any],
    priority: JobPriority = JobPriority.DEFAULT
) -> str:
    """Submit AI generation job"""
    job_id = str(uuid.uuid4())
    
    job = ProcessingJob(
        job_id=job_id,
        job_type=JobType.AI_GENERATION,
        user_id=user_id,
        status=JobStatus.PENDING,
        priority=priority,
        metadata={'type': generation_type, 'prompt': prompt, **config}
    )
    
    create_job(job)
    
    queue = get_queue(priority.value)
    queue.enqueue(
        process_ai_generation_job,
        job_id,
        generation_type,
        prompt,
        user_id,
        config,
        job_id=job_id,
        retry=Retry(max=2, interval=[30, 60]),
        timeout=600  # 10 minutes
    )
    
    return job_id

def submit_mesh_optimization_job(
    user_id: str,
    mesh_path: str,
    asset_id: Optional[str] = None,
    lod_levels: list = ['high', 'medium', 'low'],
    priority: JobPriority = JobPriority.DEFAULT
) -> str:
    """Submit mesh optimization job"""
    job_id = str(uuid.uuid4())
    
    job = ProcessingJob(
        job_id=job_id,
        job_type=JobType.MESH_OPTIMIZATION,
        user_id=user_id,
        asset_id=asset_id,
        input_url=mesh_path,
        status=JobStatus.PENDING,
        priority=priority,
        metadata={'lod_levels': lod_levels}
    )
    
    create_job(job)
    
    queue = get_queue(priority.value)
    queue.enqueue(
        process_mesh_optimization_job,
        job_id,
        mesh_path,
        user_id,
        lod_levels,
        job_id=job_id,
        retry=Retry(max=2, interval=[60, 120]),
        timeout=1800  # 30 minutes
    )
    
    return job_id

def get_job_status(job_id: str) -> Optional[Dict[str, Any]]:
    """Get job status from database"""
    return get_job_db(job_id)

