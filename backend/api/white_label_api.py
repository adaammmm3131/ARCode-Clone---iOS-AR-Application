#!/usr/bin/env python3
"""
White Label API
Endpoints pour gestion du white label (custom domain, branding, etc.)
"""

from flask import Blueprint, request, jsonify
from auth_supabase import require_auth
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import json
import uuid
import re
from datetime import datetime
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

white_label_bp = Blueprint('white_label', __name__)

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'arcode'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD', '')
    )

@white_label_bp.route('/api/v1/white-label/config', methods=['GET'])
@require_auth
def get_white_label_config(user: Dict):
    """Get white label configuration for current user/workspace"""
    try:
        user_id = user.get('sub')
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, user_id, settings, is_active, created_at, updated_at
            FROM white_label_configs
            WHERE user_id = %s AND is_active = TRUE
            ORDER BY updated_at DESC
            LIMIT 1
        """, (user_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return jsonify(None), 200
        
        return jsonify({
            'id': str(row[0]),
            'user_id': str(row[1]),
            'settings': row[2] if row[2] else {},
            'is_active': row[3],
            'created_at': row[4].isoformat() if row[4] else None,
            'updated_at': row[5].isoformat() if row[5] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting white label config: {e}")
        return jsonify({'error': 'Failed to get white label config'}), 500

@white_label_bp.route('/api/v1/white-label/config/<config_id>', methods=['PUT'])
@require_auth
def update_white_label_config(user: Dict, config_id: str):
    """Update white label configuration"""
    try:
        data = request.get_json()
        settings = data.get('settings', {})
        is_active = data.get('is_active', True)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE white_label_configs
            SET settings = %s::jsonb,
                is_active = %s,
                updated_at = NOW()
            WHERE id = %s AND user_id = %s
            RETURNING *
        """, (json.dumps(settings), is_active, config_id, user.get('sub')))
        
        row = cursor.fetchone()
        if not row:
            cursor.close()
            conn.close()
            return jsonify({'error': 'Config not found'}), 404
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(row[0]),
            'user_id': str(row[1]),
            'settings': row[2] if row[2] else {},
            'is_active': row[3],
            'created_at': row[4].isoformat() if row[4] else None,
            'updated_at': row[5].isoformat() if row[5] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error updating white label config: {e}")
        return jsonify({'error': 'Failed to update white label config'}), 500

@white_label_bp.route('/api/v1/white-label/validate-domain', methods=['POST'])
@require_auth
def validate_custom_domain(user: Dict):
    """Validate custom domain"""
    try:
        data = request.get_json()
        domain = data.get('domain')
        
        if not domain:
            return jsonify({'error': 'Missing domain'}), 400
        
        # Basic domain validation
        domain_pattern = r'^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$'
        if not re.match(domain_pattern, domain.lower()):
            return jsonify({
                'is_valid': False,
                'message': 'Invalid domain format'
            }), 200
        
        # Check if domain is already taken
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id FROM white_label_configs
            WHERE settings->>'custom_domain' = %s
            AND is_active = TRUE
            AND user_id != %s
        """, (domain.lower(), user.get('sub')))
        
        existing = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if existing:
            return jsonify({
                'is_valid': False,
                'message': 'Domain already in use'
            }), 200
        
        # TODO: DNS validation (check if CNAME/A record points to our server)
        # For now, return valid if format is correct
        
        return jsonify({
            'is_valid': True,
            'message': 'Domain format is valid. Please configure DNS CNAME to point to ar-code.com'
        }), 200
    
    except Exception as e:
        logger.error(f"Error validating domain: {e}")
        return jsonify({'error': 'Failed to validate domain'}), 500







