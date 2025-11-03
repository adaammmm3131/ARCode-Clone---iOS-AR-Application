#!/usr/bin/env python3
"""
Supabase Auth Integration
OAuth 2.0, JWT validation, session management
"""

import os
import jwt
import requests
from typing import Optional, Dict, Any
from functools import wraps
from flask import request, jsonify, g
import logging

logger = logging.getLogger(__name__)

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_KEY')  # Backend only
SUPABASE_JWT_SECRET = os.getenv('SUPABASE_JWT_SECRET')

def verify_jwt_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Verify JWT token from Supabase
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload or None
    """
    try:
        # Remove 'Bearer ' prefix if present
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Verify and decode token
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=['HS256'],
            audience='authenticated'
        )
        
        return payload
    
    except jwt.ExpiredSignatureError:
        logger.warning("JWT token expired")
        return None
    
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid JWT token: {e}")
        return None

def get_user_from_supabase(user_id: str) -> Optional[Dict[str, Any]]:
    """
    Get user info from Supabase
    
    Args:
        user_id: Supabase user ID
        
    Returns:
        User data or None
    """
    try:
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}'
        }
        
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users",
            headers=headers,
            params={'id': f'eq.{user_id}'},
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            if data:
                return data[0]
        
        return None
    
    except Exception as e:
        logger.error(f"Supabase user fetch error: {e}")
        return None

def require_auth(f):
    """
    Decorator pour endpoints nécessitant authentification
    
    Usage:
        @app.route('/protected')
        @require_auth
        def protected_route(user):
            return jsonify({"user_id": user["sub"]})
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get Authorization header
        auth_header = request.headers.get('Authorization')
        
        if not auth_header:
            return jsonify({'error': 'Authorization header missing'}), 401
        
        # Verify token
        user = verify_jwt_token(auth_header)
        
        if not user:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add user to Flask g for access in route
        g.user = user
        
        # Call original function with user as first arg
        return f(user, *args, **kwargs)
    
    return decorated_function

def optional_auth(f):
    """
    Decorator pour endpoints avec authentification optionnelle
    
    Usage:
        @app.route('/public')
        @optional_auth
        def public_route(user=None):
            if user:
                return jsonify({"authenticated": True})
            return jsonify({"authenticated": False})
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        user = None
        
        if auth_header:
            user = verify_jwt_token(auth_header)
        
        g.user = user
        return f(user, *args, **kwargs)
    
    return decorated_function

def reset_password(email: str) -> bool:
    """
    Send password reset email via Supabase
    
    Args:
        email: User email
        
    Returns:
        True if successful
    """
    try:
        response = requests.post(
            f"{SUPABASE_URL}/auth/v1/recover",
            json={'email': email},
            headers={
                'apikey': SUPABASE_ANON_KEY,
                'Content-Type': 'application/json'
            },
            timeout=5
        )
        
        return response.status_code == 200
    
    except Exception as e:
        logger.error(f"Password reset error: {e}")
        return False

def sign_in_with_oauth(provider: str, redirect_to: str) -> str:
    """
    Generate OAuth sign-in URL
    
    Args:
        provider: 'apple' or 'google'
        redirect_to: Redirect URL after auth
        
    Returns:
        OAuth URL
    """
    return f"{SUPABASE_URL}/auth/v1/authorize?provider={provider}&redirect_to={redirect_to}"









