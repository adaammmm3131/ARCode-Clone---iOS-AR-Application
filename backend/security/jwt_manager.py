#!/usr/bin/env python3
"""
JWT Token Management
Generation, validation, refresh tokens, expiration
"""

import os
import jwt
import secrets
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# JWT Configuration
JWT_SECRET = os.getenv('JWT_SECRET', secrets.token_urlsafe(32))
JWT_ALGORITHM = 'HS256'
ACCESS_TOKEN_EXPIRY = int(os.getenv('ACCESS_TOKEN_EXPIRY', '3600'))  # 1 hour
REFRESH_TOKEN_EXPIRY = int(os.getenv('REFRESH_TOKEN_EXPIRY', '2592000'))  # 30 days

def generate_access_token(
    user_id: str,
    email: str,
    scope: str = 'read write',
    additional_claims: Optional[Dict[str, Any]] = None
) -> str:
    """
    Generate JWT access token
    
    Args:
        user_id: User identifier
        email: User email
        scope: Token scope (default: 'read write')
        additional_claims: Additional JWT claims
        
    Returns:
        JWT token string
    """
    now = datetime.utcnow()
    payload = {
        'sub': user_id,
        'email': email,
        'iat': int(now.timestamp()),
        'exp': int((now + timedelta(seconds=ACCESS_TOKEN_EXPIRY)).timestamp()),
        'scope': scope,
        'type': 'access'
    }
    
    if additional_claims:
        payload.update(additional_claims)
    
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token

def generate_refresh_token(
    user_id: str,
    access_token: str
) -> str:
    """
    Generate refresh token
    
    Args:
        user_id: User identifier
        access_token: Associated access token
        
    Returns:
        Refresh token string
    """
    now = datetime.utcnow()
    payload = {
        'sub': user_id,
        'iat': int(now.timestamp()),
        'exp': int((now + timedelta(seconds=REFRESH_TOKEN_EXPIRY)).timestamp()),
        'type': 'refresh',
        'access_token': access_token  # Link to access token
    }
    
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token

def verify_token(token: str, token_type: str = 'access') -> Optional[Dict[str, Any]]:
    """
    Verify and decode JWT token
    
    Args:
        token: JWT token string
        token_type: Expected token type ('access' or 'refresh')
        
    Returns:
        Decoded payload or None
    """
    try:
        # Remove 'Bearer ' prefix if present
        if token.startswith('Bearer '):
            token = token[7:]
        
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
            audience='authenticated'
        )
        
        # Verify token type
        if payload.get('type') != token_type:
            logger.warning(f"Token type mismatch: expected {token_type}, got {payload.get('type')}")
            return None
        
        # Check expiration (jwt.decode already checks, but double-check)
        exp = payload.get('exp')
        if exp and datetime.utcnow().timestamp() > exp:
            logger.warning("Token expired")
            return None
        
        return payload
    
    except jwt.ExpiredSignatureError:
        logger.warning("JWT token expired")
        return None
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid JWT token: {e}")
        return None

def refresh_access_token(refresh_token: str) -> Optional[Dict[str, str]]:
    """
    Generate new access token from refresh token
    
    Args:
        refresh_token: Valid refresh token
        
    Returns:
        Dict with new tokens or None
    """
    payload = verify_token(refresh_token, token_type='refresh')
    
    if not payload:
        return None
    
    user_id = payload.get('sub')
    email = payload.get('email', '')
    
    if not user_id:
        logger.warning("Refresh token missing user ID")
        return None
    
    # Generate new access token
    new_access_token = generate_access_token(
        user_id=user_id,
        email=email,
        scope=payload.get('scope', 'read write')
    )
    
    # Generate new refresh token (rotate)
    new_refresh_token = generate_refresh_token(user_id, new_access_token)
    
    return {
        'access_token': new_access_token,
        'refresh_token': new_refresh_token,
        'token_type': 'Bearer',
        'expires_in': ACCESS_TOKEN_EXPIRY
    }







