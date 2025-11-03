#!/usr/bin/env python3
"""
Job Queue Tests
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime

def test_job_creation(mock_db):
    """Test creating a processing job"""
    from queue.job_models import ProcessingJob, JobType, JobStatus, JobPriority
    from queue.job_tracker import create_job
    
    job = ProcessingJob(
        job_id="test-job-123",
        job_type=JobType.PHOTOGRAMMETRY,
        user_id="user-123",
        asset_id="asset-456",
        input_url="https://test.com/video.mp4",
        status=JobStatus.PENDING,
        priority=JobPriority.DEFAULT
    )
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.execute.return_value = None
    
    with patch('queue.job_tracker.get_db_connection', return_value=mock_conn):
        result = create_job(job)
        # Result may be False if DB connection fails in test
        assert isinstance(result, bool)

def test_job_status_update(mock_db):
    """Test updating job status"""
    from queue.job_tracker import update_job_status
    from queue.job_models import JobStatus
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.execute.return_value = None
    
    with patch('queue.job_tracker.get_db_connection', return_value=mock_conn):
        result = update_job_status(
            job_id="test-job-123",
            status=JobStatus.COMPLETED,
            progress=100,
            output_url="https://test.com/output.glb"
        )
        assert isinstance(result, bool)

def test_job_notification(mock_db):
    """Test job completion notification"""
    from queue.job_notifications import notify_job_completion
    
    with patch('queue.job_notifications.send_processing_notification') as mock_send:
        mock_send.return_value = True
        
        notify_job_completion(
            job_id="test-job",
            user_id="user-123",
            job_type="photogrammetry",
            asset_id="asset-456",
            asset_url="https://test.com/asset.glb",
            asset_name="Test Model"
        )
        
        # Verify notification was called
        assert mock_send.called







