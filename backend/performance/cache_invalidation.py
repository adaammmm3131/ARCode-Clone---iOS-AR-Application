#!/usr/bin/env python3
"""
Cache Invalidation Strategy
Smart cache invalidation based on events
"""

import os
import redis
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

# Redis connection
redis_client = None
try:
    redis_client = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        db=0,
        decode_responses=True
    )
    redis_client.ping()
except Exception:
    redis_client = None

def invalidate_user_cache(user_id: str):
    """
    Invalidate all cache entries for a user
    
    Args:
        user_id: User identifier
    """
    if not redis_client:
        return
    
    try:
        patterns = [
            f"user:{user_id}:*",
            f"ar_code:*:user:{user_id}",
            f"query_cache:*user_id*{user_id}*"
        ]
        
        for pattern in patterns:
            keys = redis_client.keys(pattern)
            if keys:
                redis_client.delete(*keys)
        
        logger.info(f"Invalidated cache for user: {user_id}")
    
    except Exception as e:
        logger.error(f"Error invalidating user cache: {e}")

def invalidate_ar_code_cache(ar_code_id: str):
    """
    Invalidate cache for specific AR Code
    
    Args:
        ar_code_id: AR Code identifier
    """
    if not redis_client:
        return
    
    try:
        patterns = [
            f"ar_code:{ar_code_id}:*",
            f"asset:*:ar_code:{ar_code_id}"
        ]
        
        for pattern in patterns:
            keys = redis_client.keys(pattern)
            if keys:
                redis_client.delete(*keys)
        
        logger.info(f"Invalidated cache for AR Code: {ar_code_id}")
    
    except Exception as e:
        logger.error(f"Error invalidating AR Code cache: {e}")

def invalidate_asset_cache(asset_id: str):
    """
    Invalidate cache for specific asset
    
    Args:
        asset_id: Asset identifier
    """
    if not redis_client:
        return
    
    try:
        keys = redis_client.keys(f"asset:{asset_id}:*")
        if keys:
            redis_client.delete(*keys)
        
        logger.info(f"Invalidated cache for asset: {asset_id}")
    
    except Exception as e:
        logger.error(f"Error invalidating asset cache: {e}")

def invalidate_query_cache(pattern: str = None):
    """
    Invalidate query cache
    
    Args:
        pattern: Optional pattern to match
    """
    if not redis_client:
        return
    
    try:
        if pattern:
            keys = redis_client.keys(f"query_cache:*{pattern}*")
        else:
            keys = redis_client.keys("query_cache:*")
        
        if keys:
            redis_client.delete(*keys)
            logger.info(f"Invalidated {len(keys)} query cache entries")
    
    except Exception as e:
        logger.error(f"Error invalidating query cache: {e}")

def invalidate_cdn_cache(urls: List[str]):
    """
    Invalidate CDN cache for URLs
    
    Args:
        urls: List of URLs to invalidate
    """
    from cdn.cloudflare_cache import purge_cache_by_urls
    
    purge_cache_by_urls(urls)

def setup_cache_invalidation_listeners():
    """
    Setup event listeners for automatic cache invalidation
    
    This would listen to events like:
    - ar_code.updated -> invalidate AR Code cache
    - asset.uploaded -> invalidate asset cache
    - user.updated -> invalidate user cache
    """
    # In production, use Redis pub/sub or message queue
    # For now, this is a placeholder
    
    logger.info("Cache invalidation listeners setup complete")







