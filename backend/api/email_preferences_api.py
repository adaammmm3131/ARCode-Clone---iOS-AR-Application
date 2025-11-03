#!/usr/bin/env python3
"""
Email Preferences API
Manage user email notification preferences
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from auth_supabase import require_auth
import os
import psycopg2
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

@app.route('/api/v1/email/preferences', methods=['GET'])
@require_auth
def get_email_preferences(user):
    """Get user email preferences"""
    try:
        user_id = user.get('sub')
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                email_notifications_processing,
                email_notifications_scans,
                email_notifications_weekly_stats,
                email_notifications_marketing
            FROM users
            WHERE id = %s
        """, (user_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if row:
            return jsonify({
                'processing': row[0],
                'scans': row[1],
                'weekly_stats': row[2],
                'marketing': row[3]
            }), 200
        else:
            return jsonify({'error': 'User not found'}), 404
    
    except Exception as e:
        logger.error(f"Error getting email preferences: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/email/preferences', methods=['POST'])
@require_auth
def update_email_preferences(user):
    """Update user email preferences"""
    try:
        user_id = user.get('sub')
        data = request.json
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE users 
            SET 
                email_notifications_processing = %s,
                email_notifications_scans = %s,
                email_notifications_weekly_stats = %s,
                email_notifications_marketing = %s,
                updated_at = NOW()
            WHERE id = %s
        """, (
            data.get('processing', True),
            data.get('scans', False),
            data.get('weekly_stats', True),
            data.get('marketing', False),
            user_id
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'message': 'Preferences updated'}), 200
    
    except Exception as e:
        logger.error(f"Error updating email preferences: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)







