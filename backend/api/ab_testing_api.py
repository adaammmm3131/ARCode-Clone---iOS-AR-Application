#!/usr/bin/env python3
"""
A/B Testing API
Endpoints pour gestion des tests A/B des CTA links
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

ab_testing_bp = Blueprint('ab_testing', __name__)

@ab_testing_bp.route('/api/v1/ab-tests/<ar_code_id>', methods=['GET'])
@optional_auth
def get_ab_test(user: Optional[Dict], ar_code_id: str):
    """Get active A/B test for an AR Code"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT id, ar_code_id, name, is_active, variants, start_date,
                   end_date, winner_variant_id, created_at, updated_at
            FROM ab_tests
            WHERE ar_code_id = %s AND is_active = TRUE
            ORDER BY created_at DESC
            LIMIT 1
        """, (ar_code_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return jsonify(None), 200
        
        return jsonify({
            'id': str(row[0]),
            'ar_code_id': str(row[1]),
            'name': row[2],
            'is_active': row[3],
            'variants': row[4],  # JSONB
            'start_date': row[5].isoformat() if row[5] else None,
            'end_date': row[6].isoformat() if row[6] else None,
            'winner_variant_id': row[7],
            'created_at': row[8].isoformat() if row[8] else None,
            'updated_at': row[9].isoformat() if row[9] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting AB test: {e}")
        return jsonify({'error': 'Failed to get AB test'}), 500

@ab_testing_bp.route('/api/v1/ab-tests', methods=['POST'])
@require_auth
def create_ab_test(user: Dict):
    """Create a new A/B test"""
    try:
        data = request.get_json()
        
        test_id = str(uuid.uuid4())
        ar_code_id = data.get('ar_code_id')
        name = data.get('name')
        variants = data.get('variants', [])
        is_active = data.get('is_active', True)
        
        if not all([ar_code_id, name, variants]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO ab_tests (
                id, ar_code_id, name, is_active, variants, start_date, created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s::jsonb, NOW(), NOW(), NOW())
            RETURNING id, start_date, created_at, updated_at
        """, (test_id, ar_code_id, name, is_active, json.dumps(variants)))
        
        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'ar_code_id': ar_code_id,
            'name': name,
            'is_active': is_active,
            'variants': variants,
            'start_date': result[1].isoformat(),
            'end_date': None,
            'winner_variant_id': None,
            'created_at': result[2].isoformat(),
            'updated_at': result[3].isoformat()
        }), 201
    
    except Exception as e:
        logger.error(f"Error creating AB test: {e}")
        return jsonify({'error': 'Failed to create AB test'}), 500

@ab_testing_bp.route('/api/v1/ab-tests/<test_id>/results', methods=['GET'])
@require_auth
def get_ab_test_results(user: Dict, test_id: str):
    """Get A/B test results"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get test
        cursor.execute("""
            SELECT id, ar_code_id, name, is_active, variants, start_date,
                   end_date, winner_variant_id
            FROM ab_tests
            WHERE id = %s
        """, (test_id,))
        
        test_row = cursor.fetchone()
        if not test_row:
            return jsonify({'error': 'AB test not found'}), 404
        
        # Get results
        cursor.execute("""
            SELECT variant_id, SUM(clicks) as total_clicks, SUM(conversions) as total_conversions
            FROM ab_test_results
            WHERE test_id = %s
            GROUP BY variant_id
        """, (test_id,))
        
        results_rows = cursor.fetchall()
        cursor.close()
        conn.close()
        
        # Build results dict
        results = {}
        for row in results_rows:
            results[row[0]] = {
                'variant_id': row[0],
                'clicks': row[1] or 0,
                'conversions': row[2] or 0,
                'conversion_rate': (row[2] / row[1] * 100) if row[1] and row[1] > 0 else 0.0
            }
        
        return jsonify({
            'id': str(test_row[0]),
            'ar_code_id': str(test_row[1]),
            'name': test_row[2],
            'is_active': test_row[3],
            'variants': test_row[4],
            'start_date': test_row[5].isoformat() if test_row[5] else None,
            'end_date': test_row[6].isoformat() if test_row[6] else None,
            'winner_variant_id': test_row[7],
            'results': results
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting AB test results: {e}")
        return jsonify({'error': 'Failed to get AB test results'}), 500

@ab_testing_bp.route('/api/v1/analytics/ab-test-conversion', methods=['POST'])
@optional_auth
def track_ab_test_conversion(user: Optional[Dict]):
    """Track A/B test conversion"""
    try:
        data = request.get_json()
        variant_id = data.get('variant_id')
        
        if not variant_id:
            return jsonify({'error': 'Missing variant_id'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Find test for this variant
        cursor.execute("""
            SELECT id FROM ab_tests
            WHERE variants::jsonb @> %s::jsonb
            AND is_active = TRUE
        """, (json.dumps([{'variantId': variant_id}]),))
        
        test_row = cursor.fetchone()
        if not test_row:
            return jsonify({'error': 'AB test not found for variant'}), 404
        
        test_id = test_row[0]
        
        # Update or insert result
        cursor.execute("""
            INSERT INTO ab_test_results (test_id, variant_id, conversions, updated_at)
            VALUES (%s, %s, 1, NOW())
            ON CONFLICT (test_id, variant_id)
            DO UPDATE SET
                conversions = ab_test_results.conversions + 1,
                updated_at = NOW()
        """, (test_id, variant_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Conversion tracked'}), 200
    
    except Exception as e:
        logger.error(f"Error tracking AB test conversion: {e}")
        return jsonify({'error': 'Failed to track conversion'}), 500

@ab_testing_bp.route('/api/v1/ab-tests/<test_id>/conclude', methods=['POST'])
@require_auth
def conclude_ab_test(user: Dict, test_id: str):
    """Conclude an A/B test and set winner"""
    try:
        data = request.get_json()
        winner_variant_id = data.get('winner_variant_id')
        
        if not winner_variant_id:
            return jsonify({'error': 'Missing winner_variant_id'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE ab_tests
            SET is_active = FALSE,
                winner_variant_id = %s,
                end_date = NOW(),
                updated_at = NOW()
            WHERE id = %s
            RETURNING *
        """, (winner_variant_id, test_id))
        
        result = cursor.fetchone()
        if not result:
            cursor.close()
            conn.close()
            return jsonify({'error': 'AB test not found'}), 404
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            'id': str(result[0]),
            'winner_variant_id': winner_variant_id,
            'is_active': False,
            'end_date': result[6].isoformat() if result[6] else None
        }), 200
    
    except Exception as e:
        logger.error(f"Error concluding AB test: {e}")
        return jsonify({'error': 'Failed to conclude AB test'}), 500

