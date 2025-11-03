#!/usr/bin/env python3
"""
Analytics API Backend
Endpoints pour tracking events et récupération analytics
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from auth_supabase import require_auth, optional_auth
from typing import Dict, Any
import os
import uuid
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor
import json
import logging

logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

def get_db_connection():
    """Get PostgreSQL connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', 5432)),
        database=os.getenv('DB_NAME', 'arcode_db'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD')
    )

@app.route('/api/v1/analytics/track', methods=['POST'])
@optional_auth
def track_event(user: Dict[str, Any]):
    """Track analytics event"""
    data = request.json
    
    event_type = data.get('event_type')
    ar_code_id = data.get('ar_code_id')
    event_data = data.get('event_data', {})
    
    # Extract metadata
    ip_address = request.remote_addr
    user_agent = request.headers.get('User-Agent', '')
    device_type = data.get('device_type', 'web')
    browser = data.get('browser')
    
    # Location (if provided)
    location = data.get('location')
    latitude = location.get('latitude') if location else None
    longitude = location.get('longitude') if location else None
    location_country = location.get('country') if location else None
    location_city = location.get('city') if location else None
    
    # User ID (from JWT if authenticated)
    user_id = user.get('sub') if user else None
    
    # Session ID (stored in event_data)
    session_id = data.get('session_id') or str(uuid.uuid4())
    event_data['session_id'] = session_id
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO analytics_events (
                ar_code_id, user_id, event_type, event_data,
                ip_address, user_agent, device_type, browser,
                location_country, location_city, latitude, longitude,
                created_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
        """, (
            ar_code_id,
            user_id,
            event_type,
            json.dumps(event_data),
            ip_address,
            user_agent,
            device_type,
            browser,
            location_country,
            location_city,
            latitude,
            longitude,
            datetime.utcnow()
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        # Track to Umami (async)
        from analytics.umami_api import track_event
        track_event(
            event_name=event_type,
            event_data=event_data,
            session_id=session_id,
            user_id=user_id,
            ar_code_id=ar_code_id
        )
        
        return jsonify({'success': True, 'session_id': session_id}), 200
    
    except Exception as e:
        logger.error(f"Error tracking event: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/analytics/events', methods=['GET'])
@require_auth
def get_events(user: Dict[str, Any]):
    """Get analytics events for user's AR Codes"""
    ar_code_id = request.args.get('ar_code_id')
    event_type = request.args.get('event_type')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    limit = int(request.args.get('limit', 100))
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        query = """
            SELECT e.*, c.title as ar_code_title
            FROM analytics_events e
            LEFT JOIN ar_codes c ON e.ar_code_id = c.id
            WHERE c.user_id = %s
        """
        params = [user['sub']]
        
        if ar_code_id:
            query += " AND e.ar_code_id = %s"
            params.append(ar_code_id)
        
        if event_type:
            query += " AND e.event_type = %s"
            params.append(event_type)
        
        if start_date:
            query += " AND e.created_at >= %s"
            params.append(start_date)
        
        if end_date:
            query += " AND e.created_at <= %s"
            params.append(end_date)
        
        query += " ORDER BY e.created_at DESC LIMIT %s"
        params.append(limit)
        
        cursor.execute(query, params)
        events = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'events': [dict(event) for event in events],
            'count': len(events)
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting events: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/analytics/stats', methods=['GET'])
@require_auth
def get_stats(user: Dict[str, Any]):
    """Get aggregated analytics stats"""
    ar_code_id = request.args.get('ar_code_id')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Base query
        query = """
            SELECT 
                event_type,
                COUNT(*) as count,
                COUNT(DISTINCT user_id) as unique_users,
                COUNT(DISTINCT (event_data->>'session_id')) as unique_sessions
            FROM analytics_events e
            JOIN ar_codes c ON e.ar_code_id = c.id
            WHERE c.user_id = %s
        """
        params = [user['sub']]
        
        if ar_code_id:
            query += " AND e.ar_code_id = %s"
            params.append(ar_code_id)
        
        if start_date:
            query += " AND e.created_at >= %s"
            params.append(start_date)
        
        if end_date:
            query += " AND e.created_at <= %s"
            params.append(end_date)
        
        query += " GROUP BY event_type"
        
        cursor.execute(query, params)
        stats = cursor.fetchall()
        
        # Geographic stats (only if location data available)
        geo_query = """
            SELECT 
                location_country,
                location_city,
                COUNT(*) as count,
                AVG(latitude) as avg_latitude,
                AVG(longitude) as avg_longitude
            FROM analytics_events e
            JOIN ar_codes c ON e.ar_code_id = c.id
            WHERE c.user_id = %s
            AND latitude IS NOT NULL
            AND longitude IS NOT NULL
        """
        geo_params = [user['sub']]
        
        if ar_code_id:
            geo_query += " AND e.ar_code_id = %s"
            geo_params.append(ar_code_id)
        
        if start_date:
            geo_query += " AND e.created_at >= %s"
            geo_params.append(start_date)
        
        if end_date:
            geo_query += " AND e.created_at <= %s"
            geo_params.append(end_date)
        
        geo_query += " GROUP BY location_country, location_city"
        
        cursor.execute(geo_query, geo_params)
        geo_stats = cursor.fetchall()
        
        # Device breakdown
        device_query = """
            SELECT 
                device_type,
                browser,
                COUNT(*) as count
            FROM analytics_events e
            JOIN ar_codes c ON e.ar_code_id = c.id
            WHERE c.user_id = %s
        """
        device_params = [user['sub']]
        
        if ar_code_id:
            device_query += " AND e.ar_code_id = %s"
            device_params.append(ar_code_id)
        
        if start_date:
            device_query += " AND e.created_at >= %s"
            device_params.append(start_date)
        
        if end_date:
            device_query += " AND e.created_at <= %s"
            device_params.append(end_date)
        
        device_query += " GROUP BY device_type, browser"
        
        cursor.execute(device_query, device_params)
        device_stats = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'event_stats': [dict(s) for s in stats],
            'geographic_stats': [dict(g) for g in geo_stats],
            'device_stats': [dict(d) for d in device_stats]
        }), 200
    
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)

