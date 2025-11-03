#!/usr/bin/env python3
"""
RQ (Redis Queue) Configuration
Job queue system avec Redis backend
"""

import os
from rq import Queue, Retry
from rq.job import Job
from redis import Redis
from typing import Optional
import logging

logger = logging.getLogger(__name__)

# Redis connection
redis_conn = Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD'),
    db=0
)

# Queues par priorité
high_priority_queue = Queue('high', connection=redis_conn)
default_queue = Queue('default', connection=redis_conn)
low_priority_queue = Queue('low', connection=redis_conn)

# Dead letter queue
dead_letter_queue = Queue('dead_letter', connection=redis_conn)

# Queue mapping
QUEUES = {
    'high': high_priority_queue,
    'default': default_queue,
    'low': low_priority_queue
}

def get_queue(priority: str = 'default') -> Queue:
    """Get queue by priority"""
    return QUEUES.get(priority, default_queue)

def get_job(job_id: str) -> Optional[Job]:
    """Get job by ID from any queue"""
    for queue in QUEUES.values():
        try:
            job = Job.fetch(job_id, connection=redis_conn)
            return job
        except Exception:
            continue
    return None

def cancel_job(job_id: str) -> bool:
    """Cancel a job"""
    try:
        job = get_job(job_id)
        if job:
            job.cancel()
            return True
        return False
    except Exception as e:
        logger.error(f"Error cancelling job {job_id}: {e}")
        return False









