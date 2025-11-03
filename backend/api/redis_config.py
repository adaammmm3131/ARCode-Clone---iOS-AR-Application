#!/usr/bin/env python3
"""
Redis Configuration
Cache layer, rate limiting, session storage
"""

import redis
import os
import json
import logging
from typing import Optional, Any, Dict, Tuple
from functools import wraps
from datetime import timedelta

logger = logging.getLogger(__name__)

# Redis client
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True,
    socket_connect_timeout=5,
    socket_keepalive=True,
    health_check_interval=30
)

def test_redis() -> bool:
    """Test Redis connection"""
    try:
        redis_client.ping()
        return True
    except Exception as e:
        logger.error(f"Redis connection error: {e}")
        return False

def cache_get(key: str) -> Optional[Any]:
    """Get value from cache"""
    try:
        value = redis_client.get(key)
        if value:
            return json.loads(value)
        return None
    except Exception as e:
        logger.error(f"Redis get error: {e}")
        return None

def cache_set(key: str, value: Any, ttl: int = 3600) -> bool:
    """Set value in cache with TTL"""
    try:
        redis_client.setex(
            key,
            ttl,
            json.dumps(value)
        )
        return True
    except Exception as e:
        logger.error(f"Redis set error: {e}")
        return False

def cache_delete(key: str) -> bool:
    """Delete key from cache"""
    try:
        redis_client.delete(key)
        return True
    except Exception as e:
        logger.error(f"Redis delete error: {e}")
        return False

def cache_delete_pattern(pattern: str) -> int:
    """Delete all keys matching pattern"""
    try:
        keys = redis_client.keys(pattern)
        if keys:
            return redis_client.delete(*keys)
        return 0
    except Exception as e:
        logger.error(f"Redis delete pattern error: {e}")
        return 0

def rate_limit_check(key: str, limit: int, window: int) -> Tuple[bool, int]:
    """
    Check rate limit
    
    Args:
        key: Rate limit key (e.g., user_id or IP)
        limit: Max requests
        window: Time window in seconds
        
    Returns:
        (is_allowed, remaining)
    """
    try:
        current = redis_client.incr(key)
        
        if current == 1:
            # First request, set expiry
            redis_client.expire(key, window)
        
        remaining = max(0, limit - current)
        is_allowed = current <= limit
        
        return is_allowed, remaining
    except Exception as e:
        logger.error(f"Rate limit error: {e}")
        # Fail open (allow request if Redis fails)
        return True, limit

def get_redis_info() -> Dict[str, Any]:
    """Get Redis server information"""
    try:
        info = redis_client.info()
        return {
            'used_memory': info.get('used_memory_human'),
            'connected_clients': info.get('connected_clients'),
            'total_commands': info.get('total_commands_processed'),
            'keyspace_hits': info.get('keyspace_hits'),
            'keyspace_misses': info.get('keyspace_misses'),
            'uptime': info.get('uptime_in_seconds')
        }
    except Exception as e:
        logger.error(f"Redis info error: {e}")
        return {}

