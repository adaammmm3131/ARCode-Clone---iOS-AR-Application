#!/usr/bin/env python3
"""
CTA Links API
Endpoints pour gestion des Call-to-Action links dans AR experiences
"""

from flask import Blueprint, request, jsonify
from auth_supabase import require_auth, optional_auth
import psycopg2
from psycopg2.extras import RealDictCursor
import os

def get_db_connection():
    """Get database connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'arcode'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD', '')
    )
import json
import uuid
from datetime import datetime
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

cta_links_bp = Blueprint('cta_links', __name__)

@cta_links_bp.route('/api/v1/cta-links/<ar_code_id>', methods=['GET'])
@optional_auth
def get_cta_links(user: Optional[Dict], ar_code_id: str):
    """Get all CTA links for an AR Code"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, ar_code_id, button_text, button_style, destination_url,
                   destination_type, position, is_enabled, analytics_id, variant,
                   created_at, updated_at
            FROM cta_links
            WHERE ar_code_id = %s AND is_enabled = TRUE
            ORDER BY position, created_at
        """, (ar_code_id,))
        
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        links = []
        for row in rows:
            links.append({
                'id': str(row[0]),
                'ar_code_id': str(row[1]),
                'button_text': row[2],
                'button_style': row[3],
                'destination_url': row[4],
                'destination_type': row[5],
                'position': row[6],
                'is_enabled': row[7],
                'analytics_id': str(row[8]) if row[8] else None,
                'variant': row[9],
                'created_at': row[10].isoformat() if row[10] else None,
                'updated_at': row[11].isoformat() if row[11] else None
            })
        
        return jsonify(links), 200
    
    except Exception as e:
        logger.error(f"Error getting CTA links: {e}")
        return jsonify({'error': 'Failed to get CTA links'}), 500

@cta_links_bp.route('/api/v1/cta-links', methods=['POST'])
@require_auth
def create_cta_link(user: Dict):
    """Create a new CTA link"""
    try:
        data = request.get_json()
        
        link_id = str(uuid.uuid4())
        ar_code_id = data.get('ar_code_id')
        button_text = data.get('button_text')
        button_style = data.get('button_style', 'primary')
        destination_url = data.get('destination_url')
        destination_type = data.get('destination_type')
        position = data.get('position', 'bottom_center')
        is_enabled = data.get('is_enabled', True)
        analytics_id = data.get('analytics_id')
        variant = data.get('variant')
        
        # Validate required fields
        if not all([ar_code_id, button_text, destination_url, destination_type]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO cta_links (
                id, ar_code_id, button_text, button_style, destination_url,
                destination_type, position, is_enabled, analytics_id, variant,
                created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            RETURNING id, created_at, updated_at
        """, (
            link_id, ar_code_id, button_text, button_style, destination_url,
            destination_type, position, is_enabled, analytics_id, variant
        ))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'ar_code_id': ar_code_id,
            'button_text': button_text,
            'button_style': button_style,
            'destination_url': destination_url,
            'destination_type': destination_type,
            'position': position,
            'is_enabled': is_enabled,
            'analytics_id': str(analytics_id) if analytics_id else None,
            'variant': variant,
            'created_at': result[1].isoformat(),
            'updated_at': result[2].isoformat()
        }), 201
    
    except Exception as e:
        logger.error(f"Error creating CTA link: {e}")
        return jsonify({'error': 'Failed to create CTA link'}), 500

@cta_links_bp.route('/api/v1/cta-links/<link_id>', methods=['PUT'])
@require_auth
def update_cta_link(user: Dict, link_id: str):
    """Update a CTA link"""
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Build update query dynamically
        updates = []
        values = []
        
        if 'button_text' in data:
            updates.append("button_text = %s")
            values.append(data['button_text'])
        if 'button_style' in data:
            updates.append("button_style = %s")
            values.append(data['button_style'])
        if 'destination_url' in data:
            updates.append("destination_url = %s")
            values.append(data['destination_url'])
        if 'destination_type' in data:
            updates.append("destination_type = %s")
            values.append(data['destination_type'])
        if 'position' in data:
            updates.append("position = %s")
            values.append(data['position'])
        if 'is_enabled' in data:
            updates.append("is_enabled = %s")
            values.append(data['is_enabled'])
        
        if not updates:
            return jsonify({'error': 'No fields to update'}), 400
        
        updates.append("updated_at = NOW()")
        values.append(link_id)
        
        query = f"""
            UPDATE cta_links
            SET {', '.join(updates)}
            WHERE id = %s
            RETURNING *
        """
        
        cursor.execute(query, values)
        result = cursor.fetchone()
        
        if not result:
            cursor.close()
            conn.close()
            return jsonify({'error': 'CTA link not found'}), 404
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'ar_code_id': str(result[1]),
            'button_text': result[2],
            'button_style': result[3],
            'destination_url': result[4],
            'destination_type': result[5],
            'position': result[6],
            'is_enabled': result[7],
            'analytics_id': str(result[8]) if result[8] else None,
            'variant': result[9],
            'created_at': result[10].isoformat() if result[10] else None,
            'updated_at': result[11].isoformat() if result[11] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error updating CTA link: {e}")
        return jsonify({'error': 'Failed to update CTA link'}), 500

@cta_links_bp.route('/api/v1/cta-links/<link_id>', methods=['DELETE'])
@require_auth
def delete_cta_link(user: Dict, link_id: str):
    """Delete a CTA link"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM cta_links WHERE id = %s", (link_id,))
        
        if cursor.rowcount == 0:
            cursor.close()
            conn.close()
            return jsonify({'error': 'CTA link not found'}), 404
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'CTA link deleted'}), 200
    
    except Exception as e:
        logger.error(f"Error deleting CTA link: {e}")
        return jsonify({'error': 'Failed to delete CTA link'}), 500

@cta_links_bp.route('/api/v1/analytics/cta-click', methods=['POST'])
@optional_auth
def track_cta_click(user: Optional[Dict]):
    """Track CTA link click"""
    try:
        data = request.get_json()
        link_id = data.get('link_id')
        variant = data.get('variant')
        timestamp = data.get('timestamp', datetime.utcnow().timestamp())
        
        if not link_id:
            return jsonify({'error': 'Missing link_id'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Insert analytics event
        cursor.execute("""
            INSERT INTO analytics_events (
                event_type, event_data, user_id, created_at
            ) VALUES (
                'cta_click',
                %s::jsonb,
                %s,
                to_timestamp(%s)
            )
        """, (
            json.dumps({
                'link_id': link_id,
                'variant': variant
            }),
            user.get('sub') if user else None,
            timestamp
        ))
        
        # Update CTA link click count
        cursor.execute("""
            UPDATE cta_links
            SET metadata = COALESCE(metadata, '{}'::jsonb) || 
                jsonb_build_object('clicks', COALESCE((metadata->>'clicks')::int, 0) + 1)
            WHERE id = %s
        """, (link_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Click tracked'}), 200
    
    except Exception as e:
        logger.error(f"Error tracking CTA click: {e}")
        return jsonify({'error': 'Failed to track click'}), 500

