#!/usr/bin/env python3
"""
Job Tracker
Tracking des jobs dans PostgreSQL database
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Optional, Dict, Any, List
from datetime import datetime
from job_models import ProcessingJob, JobStatus, JobType, JobPriority
import logging
import json

logger = logging.getLogger(__name__)

# Database connection
def get_db_connection():
    """Get PostgreSQL connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', 5432)),
        database=os.getenv('DB_NAME', 'arcode_db'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD')
    )

def create_job(job: ProcessingJob) -> bool:
    """Create job in database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO processing_jobs (
                id, user_id, asset_id, job_type, status, progress,
                input_url, output_url, metadata, created_at, updated_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
        """, (
            job.job_id,
            job.user_id,
            job.asset_id,
            job.job_type.value,
            job.status.value,
            job.progress,
            job.input_url,
            job.output_url,
            json.dumps(job.metadata),
            job.created_at,
            job.updated_at
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
    
    except Exception as e:
        logger.error(f"Error creating job: {e}")
        return False

def update_job_status(
    job_id: str,
    status: JobStatus,
    progress: Optional[int] = None,
    error_message: Optional[str] = None,
    output_url: Optional[str] = None
) -> bool:
    """Update job status in database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        updates = ["status = %s", "updated_at = %s"]
        values = [status.value, datetime.utcnow()]
        
        if progress is not None:
            updates.append("progress = %s")
            values.append(progress)
        
        if error_message:
            updates.append("error_message = %s")
            values.append(error_message)
        
        if output_url:
            updates.append("output_url = %s")
            values.append(output_url)
        
        if status == JobStatus.PROCESSING:
            updates.append("started_at = COALESCE(started_at, %s)")
            values.append(datetime.utcnow())
        
        if status in [JobStatus.COMPLETED, JobStatus.FAILED]:
            updates.append("completed_at = %s")
            values.append(datetime.utcnow())
        
        values.append(job_id)
        
        query = f"UPDATE processing_jobs SET {', '.join(updates)} WHERE id = %s"
        cursor.execute(query, values)
        
        conn.commit()
        cursor.close()
        conn.close()
        return True
    
    except Exception as e:
        logger.error(f"Error updating job status: {e}")
        return False

def get_job(job_id: str) -> Optional[Dict[str, Any]]:
    """Get job from database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT * FROM processing_jobs WHERE id = %s
        """, (job_id,))
        
        job = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if job:
            return dict(job)
        return None
    
    except Exception as e:
        logger.error(f"Error getting job: {e}")
        return None

def get_user_jobs(user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
    """Get user's jobs"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("""
            SELECT * FROM processing_jobs
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT %s
        """, (user_id, limit))
        
        jobs = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return [dict(job) for job in jobs]
    
    except Exception as e:
        logger.error(f"Error getting user jobs: {e}")
        return []









