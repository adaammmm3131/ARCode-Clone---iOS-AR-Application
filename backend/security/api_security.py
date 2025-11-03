#!/usr/bin/env python3
"""
API Security
Rate limiting, CORS, API keys, request signing, IP whitelisting
"""

import os
import hmac
import hashlib
import time
from typing import Optional, Dict, Any, List, Tuple
from functools import wraps
from flask import request, jsonify, g
import logging
import redis
from datetime import timedelta

logger = logging.getLogger(__name__)

# Redis connection for rate limiting
redis_client = None
try:
    redis_client = redis.Redis(
        host=os.getenv('REDIS_HOST', 'localhost'),
        port=int(os.getenv('REDIS_PORT', 6379)),
        db=0,
        decode_responses=True
    )
    redis_client.ping()
except Exception as e:
    logger.warning(f"Redis not available: {e}")
    redis_client = None

# Rate limiting config
RATE_LIMIT_PER_USER = int(os.getenv('RATE_LIMIT_PER_USER', '100'))  # 100 req/min
RATE_LIMIT_WINDOW = 60  # 1 minute

# API Keys (in production, store in database)
API_KEYS: Dict[str, Dict[str, Any]] = {}

# IP Whitelist (optional)
IP_WHITELIST: List[str] = os.getenv('IP_WHITELIST', '').split(',') if os.getenv('IP_WHITELIST') else []

def check_rate_limit(user_id: Optional[str] = None) -> Tuple[bool, int, int]:
    """
    Check rate limit for user or IP
    
    Args:
        user_id: User ID (if authenticated)
        
    Returns:
        (allowed, remaining, reset_time)
    """
    if not redis_client:
        # No Redis, allow all (not recommended for production)
        return True, RATE_LIMIT_PER_USER, int(time.time()) + RATE_LIMIT_WINDOW
    
    # Use user_id if authenticated, else IP address
    key = f"rate_limit:{user_id}" if user_id else f"rate_limit:{request.remote_addr}"
    
    try:
        current = redis_client.get(key)
        
        if current is None:
            # First request in window
            redis_client.setex(key, RATE_LIMIT_WINDOW, 1)
            return True, RATE_LIMIT_PER_USER - 1, int(time.time()) + RATE_LIMIT_WINDOW
        
        current_count = int(current)
        
        if current_count >= RATE_LIMIT_PER_USER:
            # Rate limit exceeded
            ttl = redis_client.ttl(key)
            return False, 0, int(time.time()) + (ttl if ttl > 0 else RATE_LIMIT_WINDOW)
        
        # Increment counter
        new_count = redis_client.incr(key)
        redis_client.expire(key, RATE_LIMIT_WINDOW)
        
        remaining = RATE_LIMIT_PER_USER - new_count
        return True, remaining, int(time.time()) + redis_client.ttl(key)
    
    except Exception as e:
        logger.error(f"Rate limit check error: {e}")
        # On error, allow request (fail open, but log)
        return True, RATE_LIMIT_PER_USER, int(time.time()) + RATE_LIMIT_WINDOW

def require_rate_limit(f):
    """
    Decorator for rate limiting
    
    Usage:
        @app.route('/api/v1/data')
        @require_rate_limit
        def get_data(user):
            ...
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get user_id from g (set by require_auth)
        user_id = getattr(g, 'user', {}).get('sub') if hasattr(g, 'user') else None
        
        allowed, remaining, reset_time = check_rate_limit(user_id)
        
        # Add rate limit headers
        response = jsonify({})  # Will be replaced
        response.headers['X-RateLimit-Limit'] = str(RATE_LIMIT_PER_USER)
        response.headers['X-RateLimit-Remaining'] = str(remaining)
        response.headers['X-RateLimit-Reset'] = str(reset_time)
        
        if not allowed:
            return jsonify({
                'error': 'rate_limit_exceeded',
                'message': 'Rate limit exceeded. Please try again later.',
                'retry_after': reset_time - int(time.time())
            }), 429
        
        # Call original function
        result = f(*args, **kwargs)
        
        # Add headers to response
        if hasattr(result, 'headers'):
            result.headers['X-RateLimit-Limit'] = str(RATE_LIMIT_PER_USER)
            result.headers['X-RateLimit-Remaining'] = str(remaining)
            result.headers['X-RateLimit-Reset'] = str(reset_time)
        
        return result
    
    return decorated_function

def check_ip_whitelist() -> bool:
    """
    Check if IP is whitelisted
    
    Returns:
        True if whitelisted or no whitelist configured
    """
    if not IP_WHITELIST or len(IP_WHITELIST) == 0:
        return True  # No whitelist, allow all
    
    client_ip = request.remote_addr
    
    # Check Cloudflare real IP
    cf_ip = request.headers.get('CF-Connecting-IP')
    if cf_ip:
        client_ip = cf_ip
    
    return client_ip in IP_WHITELIST

def verify_api_key(api_key: str) -> Optional[Dict[str, Any]]:
    """
    Verify API key
    
    Args:
        api_key: API key string
        
    Returns:
        API key info or None
    """
    if api_key in API_KEYS:
        key_info = API_KEYS[api_key]
        
        # Check expiration
        if 'expires_at' in key_info:
            if time.time() > key_info['expires_at']:
                return None
        
        return key_info
    
    return None

def verify_request_signature(
    payload: str,
    signature: str,
    secret: str
) -> bool:
    """
    Verify HMAC signature for request
    
    Args:
        payload: Request payload (string)
        signature: HMAC signature from header
        secret: Shared secret
        
    Returns:
        True if signature is valid
    """
    try:
        expected = hmac.new(
            secret.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(expected, signature)
    
    except Exception as e:
        logger.error(f"Signature verification error: {e}")
        return False

def get_cors_headers() -> Dict[str, str]:
    """
    Get CORS headers (strict)
    
    Returns:
        Dict of CORS headers
    """
    origin = request.headers.get('Origin')
    
    # Allowed origins (in production, from config/database)
    allowed_origins = [
        'https://ar-code.com',
        'https://www.ar-code.com',
        'ar-code://',  # iOS app
    ]
    
    # Check if origin is allowed
    if origin and origin in allowed_origins:
        return {
            'Access-Control-Allow-Origin': origin,
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key',
            'Access-Control-Allow-Credentials': 'true',
            'Access-Control-Max-Age': '3600'
        }
    
    return {}

