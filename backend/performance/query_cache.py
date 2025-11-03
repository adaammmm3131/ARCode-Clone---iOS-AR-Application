#!/usr/bin/env python3
"""
Redis Query Caching
Cache database queries for performance
"""

import os
import json
import hashlib
import redis
from typing import Optional, Any, Dict
import logging
from datetime import timedelta

logger = logging.getLogger(__name__)

# Redis connection
redis_client = None
try:
    redis_client = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        db=1,  # Use separate DB for query cache
        decode_responses=False  # Keep binary for JSON
    )
    redis_client.ping()
except Exception as e:
    logger.warning(f"Redis not available for query cache: {e}")
    redis_client = None

# Default cache TTL (seconds)
DEFAULT_CACHE_TTL = int(os.getenv('QUERY_CACHE_TTL', '300'))  # 5 minutes

def generate_cache_key(query: str, params: Dict[str, Any] = None) -> str:
    """
    Generate cache key from query and parameters
    
    Args:
        query: SQL query string
        params: Query parameters
        
    Returns:
        Cache key string
    """
    key_data = f"{query}{json.dumps(params, sort_keys=True)}"
    key_hash = hashlib.sha256(key_data.encode()).hexdigest()
    return f"query_cache:{key_hash}"

def get_cached_query(
    query: str,
    params: Dict[str, Any] = None,
    ttl: int = DEFAULT_CACHE_TTL
) -> Optional[Any]:
    """
    Get cached query result
    
    Args:
        query: SQL query string
        params: Query parameters
        ttl: Cache TTL in seconds
        
    Returns:
        Cached result or None
    """
    if not redis_client:
        return None
    
    try:
        cache_key = generate_cache_key(query, params)
        cached = redis_client.get(cache_key)
        
        if cached:
            return json.loads(cached)
        
        return None
    
    except Exception as e:
        logger.error(f"Error getting cached query: {e}")
        return None

def cache_query(
    query: str,
    result: Any,
    params: Dict[str, Any] = None,
    ttl: int = DEFAULT_CACHE_TTL
) -> bool:
    """
    Cache query result
    
    Args:
        query: SQL query string
        result: Query result to cache
        params: Query parameters
        ttl: Cache TTL in seconds
        
    Returns:
        True if successful
    """
    if not redis_client:
        return False
    
    try:
        cache_key = generate_cache_key(query, params)
        
        # Serialize result
        result_json = json.dumps(result, default=str)
        
        redis_client.setex(cache_key, ttl, result_json.encode())
        
        return True
    
    except Exception as e:
        logger.error(f"Error caching query: {e}")
        return False

def invalidate_cache(pattern: str = None) -> int:
    """
    Invalidate cache entries
    
    Args:
        pattern: Cache key pattern (None = all query cache)
        
    Returns:
        Number of keys deleted
    """
    if not redis_client:
        return 0
    
    try:
        if pattern:
            keys = redis_client.keys(f"query_cache:{pattern}*")
        else:
            keys = redis_client.keys("query_cache:*")
        
        if keys:
            return redis_client.delete(*keys)
        
        return 0
    
    except Exception as e:
        logger.error(f"Error invalidating cache: {e}")
        return 0

def cache_decorator(ttl: int = DEFAULT_CACHE_TTL):
    """
    Decorator for caching function results
    
    Usage:
        @cache_decorator(ttl=600)
        def expensive_query():
            ...
    """
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and arguments
            cache_key_data = f"{func.__name__}{args}{kwargs}"
            cache_key = f"func_cache:{hashlib.sha256(cache_key_data.encode()).hexdigest()}"
            
            # Try to get from cache
            if redis_client:
                try:
                    cached = redis_client.get(cache_key)
                    if cached:
                        return json.loads(cached)
                except Exception:
                    pass
            
            # Execute function
            result = func(*args, **kwargs)
            
            # Cache result
            if redis_client:
                try:
                    result_json = json.dumps(result, default=str)
                    redis_client.setex(cache_key, ttl, result_json.encode())
                except Exception:
                    pass
            
            return result
        
        return wrapper
    return decorator







