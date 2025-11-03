#!/usr/bin/env python3
"""
Retargeting Pixels Server-Side Tracking
Facebook, Google Ads, LinkedIn, Twitter pixels
"""

import os
import requests
import logging
from typing import Dict, Any, Optional
from datetime import datetime
import hashlib
import hmac

logger = logging.getLogger(__name__)

# Pixel IDs from environment
FACEBOOK_PIXEL_ID = os.getenv('FACEBOOK_PIXEL_ID')
GOOGLE_ADS_CONVERSION_ID = os.getenv('GOOGLE_ADS_CONVERSION_ID')
GOOGLE_ADS_CONVERSION_LABEL = os.getenv('GOOGLE_ADS_CONVERSION_LABEL')
LINKEDIN_PARTNER_ID = os.getenv('LINKEDIN_PARTNER_ID')
TWITTER_PIXEL_ID = os.getenv('TWITTER_PIXEL_ID')

def track_facebook_pixel(
    event_name: str,
    event_data: Dict[str, Any],
    user_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None
):
    """Track event to Facebook Pixel (Server-Side API)"""
    if not FACEBOOK_PIXEL_ID:
        return
    
    try:
        # Facebook Conversions API
        payload = {
            'data': [{
                'event_name': event_name,
                'event_time': int(datetime.utcnow().timestamp()),
                'event_id': event_data.get('event_id', ''),
                'user_data': {
                    'client_ip_address': ip_address,
                    'client_user_agent': user_agent,
                },
                'custom_data': event_data
            }],
            'access_token': os.getenv('FACEBOOK_ACCESS_TOKEN', ''),
            'pixel_id': FACEBOOK_PIXEL_ID
        }
        
        if user_id:
            # Hash user ID for privacy
            payload['data'][0]['user_data']['external_id'] = hash_user_id(user_id)
        
        response = requests.post(
            f'https://graph.facebook.com/v18.0/{FACEBOOK_PIXEL_ID}/events',
            json=payload,
            timeout=5
        )
        
        if response.status_code == 200:
            logger.debug(f"Facebook Pixel tracked: {event_name}")
        else:
            logger.warning(f"Facebook Pixel error: {response.status_code}")
    
    except Exception as e:
        logger.error(f"Error tracking Facebook Pixel: {e}")

def track_google_ads_pixel(
    event_name: str,
    event_data: Dict[str, Any],
    user_id: Optional[str] = None
):
    """Track event to Google Ads (Measurement Protocol)"""
    if not GOOGLE_ADS_CONVERSION_ID:
        return
    
    try:
        # Google Ads Measurement Protocol
        payload = {
            'conversion_id': GOOGLE_ADS_CONVERSION_ID,
            'conversion_label': GOOGLE_ADS_CONVERSION_LABEL,
            'conversion_value': event_data.get('value', 0),
            'transaction_id': event_data.get('transaction_id', ''),
            'currency_code': 'USD'
        }
        
        response = requests.post(
            'https://www.google-analytics.com/collect',
            params=payload,
            timeout=5
        )
        
        if response.status_code == 200:
            logger.debug(f"Google Ads tracked: {event_name}")
        else:
            logger.warning(f"Google Ads error: {response.status_code}")
    
    except Exception as e:
        logger.error(f"Error tracking Google Ads: {e}")

def track_linkedin_pixel(
    event_name: str,
    event_data: Dict[str, Any],
    user_id: Optional[str] = None
):
    """Track event to LinkedIn Insight Tag"""
    if not LINKEDIN_PARTNER_ID:
        return
    
    try:
        # LinkedIn Conversion Tracking API
        payload = {
            'conversionId': LINKEDIN_PARTNER_ID,
            'eventName': event_name,
            'eventTime': int(datetime.utcnow().timestamp()),
            'userData': {
                'userId': hash_user_id(user_id) if user_id else None
            },
            'customData': event_data
        }
        
        response = requests.post(
            'https://www.linkedin.com/px',
            json=payload,
            timeout=5
        )
        
        if response.status_code == 200:
            logger.debug(f"LinkedIn Insight tracked: {event_name}")
        else:
            logger.warning(f"LinkedIn Insight error: {response.status_code}")
    
    except Exception as e:
        logger.error(f"Error tracking LinkedIn Insight: {e}")

def track_twitter_pixel(
    event_name: str,
    event_data: Dict[str, Any],
    user_id: Optional[str] = None
):
    """Track event to Twitter Pixel"""
    if not TWITTER_PIXEL_ID:
        return
    
    try:
        # Twitter Conversions API
        payload = {
            'pixel_id': TWITTER_PIXEL_ID,
            'event': event_name,
            'event_time_ms': int(datetime.utcnow().timestamp() * 1000),
            'properties': event_data
        }
        
        if user_id:
            payload['user_id'] = hash_user_id(user_id)
        
        # Twitter Conversions API
        response = requests.post(
            f'https://ads-api.twitter.com/12/measurement/conversions/{TWITTER_PIXEL_ID}',
            json=payload,
            headers={
                'Authorization': f'Bearer {os.getenv("TWITTER_ACCESS_TOKEN", "")}'
            },
            timeout=5
        )
        
        if response.status_code == 200:
            logger.debug(f"Twitter Pixel tracked: {event_name}")
        else:
            logger.warning(f"Twitter Pixel error: {response.status_code}")
    
    except Exception as e:
        logger.error(f"Error tracking Twitter Pixel: {e}")

def hash_user_id(user_id: str) -> str:
    """Hash user ID for privacy compliance"""
    return hashlib.sha256(user_id.encode()).hexdigest()

