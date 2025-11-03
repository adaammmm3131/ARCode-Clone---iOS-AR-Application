#!/usr/bin/env python3
"""
Cloudflare Cache Management
Cache purge, invalidation, cache status
"""

import os
import requests
import logging
from typing import List, Optional, Dict, Any

logger = logging.getLogger(__name__)

# Cloudflare API configuration
CF_API_TOKEN = os.getenv('CLOUDFLARE_API_TOKEN')
CF_ZONE_ID = os.getenv('CLOUDFLARE_ZONE_ID')
CF_API_URL = 'https://api.cloudflare.com/client/v4'

def purge_cache_by_urls(urls: List[str]) -> bool:
    """
    Purge cache for specific URLs
    
    Args:
        urls: List of URLs to purge
        
    Returns:
        True if successful
    """
    if not CF_API_TOKEN or not CF_ZONE_ID:
        logger.warning("Cloudflare API credentials not configured")
        return False
    
    try:
        response = requests.post(
            f'{CF_API_URL}/zones/{CF_ZONE_ID}/purge_cache',
            headers={
                'Authorization': f'Bearer {CF_API_TOKEN}',
                'Content-Type': 'application/json'
            },
            json={'files': urls},
            timeout=10
        )
        
        if response.status_code == 200:
            logger.info(f"Cache purged for {len(urls)} URLs")
            return True
        else:
            logger.error(f"Cache purge failed: {response.status_code} - {response.text}")
            return False
    
    except Exception as e:
        logger.error(f"Error purging cache: {e}")
        return False

def purge_cache_by_tags(tags: List[str]) -> bool:
    """
    Purge cache by tags (Enterprise only)
    
    Args:
        tags: List of cache tags
        
    Returns:
        True if successful
    """
    if not CF_API_TOKEN or not CF_ZONE_ID:
        return False
    
    try:
        response = requests.post(
            f'{CF_API_URL}/zones/{CF_ZONE_ID}/purge_cache',
            headers={
                'Authorization': f'Bearer {CF_API_TOKEN}',
                'Content-Type': 'application/json'
            },
            json={'tags': tags},
            timeout=10
        )
        
        return response.status_code == 200
    
    except Exception as e:
        logger.error(f"Error purging cache by tags: {e}")
        return False

def purge_everything() -> bool:
    """Purge entire cache"""
    if not CF_API_TOKEN or not CF_ZONE_ID:
        return False
    
    try:
        response = requests.post(
            f'{CF_API_URL}/zones/{CF_ZONE_ID}/purge_cache',
            headers={
                'Authorization': f'Bearer {CF_API_TOKEN}',
                'Content-Type': 'application/json'
            },
            json={'purge_everything': True},
            timeout=30
        )
        
        if response.status_code == 200:
            logger.info("Entire cache purged")
            return True
        else:
            logger.error(f"Cache purge failed: {response.status_code}")
            return False
    
    except Exception as e:
        logger.error(f"Error purging everything: {e}")
        return False

def get_cache_status(url: str) -> Optional[Dict[str, Any]]:
    """
    Get cache status for URL
    
    Args:
        url: URL to check
        
    Returns:
        Cache status dict or None
    """
    try:
        response = requests.head(
            url,
            allow_redirects=True,
            timeout=10
        )
        
        headers = response.headers
        
        return {
            'cf_cache_status': headers.get('CF-Cache-Status'),  # HIT, MISS, EXPIRED, etc.
            'cf_ray': headers.get('CF-Ray'),
            'cf_edge_location': headers.get('CF-Edge-Location'),
            'cache_control': headers.get('Cache-Control'),
            'etag': headers.get('ETag')
        }
    
    except Exception as e:
        logger.error(f"Error checking cache status: {e}")
        return None

def purge_asset_cache(asset_key: str, base_url: str = None) -> bool:
    """
    Purge cache for specific asset
    
    Args:
        asset_key: R2 key or asset identifier
        base_url: Base URL (from R2_PUBLIC_URL)
        
    Returns:
        True if successful
    """
    if not base_url:
        base_url = os.getenv('R2_PUBLIC_URL', 'https://assets.ar-code.com')
    
    url = f"{base_url}/{asset_key}"
    return purge_cache_by_urls([url])







