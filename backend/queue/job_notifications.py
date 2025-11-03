#!/usr/bin/env python3
"""
Job Completion Notifications
Send email notifications when processing jobs complete
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from email.notification_service import send_processing_notification
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

def notify_job_completion(
    job_id: str,
    user_id: str,
    job_type: str,
    asset_id: Optional[str] = None,
    asset_url: Optional[str] = None,
    asset_name: Optional[str] = None
):
    """
    Send email notification when job completes
    
    Args:
        job_id: Job identifier
        user_id: User identifier
        job_type: Type of job (photogrammetry, gaussian, mesh_optimization)
        asset_id: Asset identifier (optional)
        asset_url: Asset URL (optional)
        asset_name: Asset name (optional)
    """
    try:
        # Map job types to asset types
        asset_type_map = {
            'photogrammetry': 'Modèle 3D',
            'gaussian': 'Gaussian Splatting',
            'mesh_optimization': 'Modèle 3D optimisé',
            'ai_generation': 'Génération IA'
        }
        
        asset_type = asset_type_map.get(job_type, 'Asset')
        
        # Get asset name if not provided
        if not asset_name:
            asset_name = f"{asset_type} #{asset_id[:8]}" if asset_id else f"{asset_type}"
        
        # Construct asset URL if not provided
        if not asset_url and asset_id:
            asset_url = f"https://ar-code.com/assets/{asset_id}"
        elif not asset_url:
            asset_url = f"https://ar-code.com/dashboard"
        
        # Send notification
        send_processing_notification(
            user_id=user_id,
            asset_type=asset_type,
            asset_name=asset_name,
            asset_url=asset_url
        )
        
        logger.info(f"Notification sent for job {job_id}")
    
    except Exception as e:
        logger.error(f"Error sending job completion notification: {e}")







