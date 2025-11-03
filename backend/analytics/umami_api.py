#!/usr/bin/env python3
"""
Umami Analytics API Integration
Self-hosted privacy-focused analytics
"""

import os
import requests
import hashlib
import time
from typing import Dict, Any, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

# Umami configuration
UMAMI_URL = os.getenv('UMAMI_URL', 'http://localhost:3000')
UMAMI_WEBSITE_ID = os.getenv('UMAMI_WEBSITE_ID')
UMAMI_API_KEY = os.getenv('UMAMI_API_KEY')  # For server-side tracking

def generate_visitor_id(session_id: str, user_id: Optional[str] = None) -> str:
    """Generate unique visitor ID"""
    data = f"{session_id}{user_id or ''}"
    return hashlib.sha256(data.encode()).hexdigest()[:16]

def track_event(
    event_name: str,
    event_data: Dict[str, Any],
    session_id: str,
    user_id: Optional[str] = None,
    ar_code_id: Optional[str] = None,
    url: Optional[str] = None,
    referrer: Optional[str] = None
):
    """
    Track event to Umami
    
    Args:
        event_name: Event name (qr_scan, placement, interaction, etc.)
        event_data: Event metadata
        session_id: Session identifier
        user_id: User ID (optional)
        ar_code_id: AR Code ID (optional)
        url: Page/AR experience URL
        referrer: Referrer URL
    """
    try:
        visitor_id = generate_visitor_id(session_id, user_id)
        
        payload = {
            'website': UMAMI_WEBSITE_ID,
            'hostname': 'ar-code.com',
            'url': url or f'/ar/{ar_code_id or ""}',
            'referrer': referrer,
            'visitor_id': visitor_id,
            'session_id': session_id,
            'event_name': event_name,
            'event_data': event_data
        }
        
        response = requests.post(
            f"{UMAMI_URL}/api/send",
            json=payload,
            headers={
                'Content-Type': 'application/json'
            },
            timeout=5
        )
        
        if response.status_code == 200:
            logger.debug(f"Event tracked: {event_name}")
        else:
            logger.warning(f"Failed to track event: {response.status_code}")
    
    except Exception as e:
        logger.error(f"Error tracking event to Umami: {e}")

def track_pageview(
    url: str,
    session_id: str,
    user_id: Optional[str] = None,
    referrer: Optional[str] = None
):
    """Track pageview to Umami"""
    try:
        visitor_id = generate_visitor_id(session_id, user_id)
        
        payload = {
            'website': UMAMI_WEBSITE_ID,
            'hostname': 'ar-code.com',
            'url': url,
            'referrer': referrer,
            'visitor_id': visitor_id,
            'session_id': session_id
        }
        
        response = requests.post(
            f"{UMAMI_URL}/api/send",
            json=payload,
            timeout=5
        )
        
        return response.status_code == 200
    
    except Exception as e:
        logger.error(f"Error tracking pageview: {e}")
        return False









