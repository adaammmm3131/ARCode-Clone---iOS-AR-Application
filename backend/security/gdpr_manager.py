#!/usr/bin/env python3
"""
GDPR Compliance
Data export, data deletion, consent management
"""

import os
import json
import psycopg2
from typing import Dict, Any, List, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

def get_db_connection():
    """Get PostgreSQL connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', 5432)),
        database=os.getenv('DB_NAME', 'arcode_db'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD')
    )

def export_user_data(user_id: str) -> Dict[str, Any]:
    """
    Export all user data for GDPR compliance
    
    Args:
        user_id: User identifier
        
    Returns:
        Dict containing all user data
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        data = {
            'user_id': user_id,
            'export_date': datetime.utcnow().isoformat(),
            'data': {}
        }
        
        # Export user profile
        cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        user_row = cursor.fetchone()
        if user_row:
            columns = [desc[0] for desc in cursor.description]
            data['data']['profile'] = dict(zip(columns, user_row))
        
        # Export AR Codes
        cursor.execute("SELECT * FROM ar_codes WHERE user_id = %s", (user_id,))
        ar_codes = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        data['data']['ar_codes'] = [dict(zip(columns, row)) for row in ar_codes]
        
        # Export analytics events
        cursor.execute("SELECT * FROM analytics_events WHERE user_id = %s", (user_id,))
        events = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        data['data']['analytics'] = [dict(zip(columns, row)) for row in events]
        
        # Export assets
        cursor.execute("SELECT * FROM assets WHERE user_id = %s", (user_id,))
        assets = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        data['data']['assets'] = [dict(zip(columns, row)) for row in assets]
        
        cursor.close()
        conn.close()
        
        return data
    
    except Exception as e:
        logger.error(f"Error exporting user data: {e}")
        raise

def delete_user_data(user_id: str) -> bool:
    """
    Delete all user data (GDPR right to be forgotten)
    
    Args:
        user_id: User identifier
        
    Returns:
        True if successful
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Delete in correct order (respect foreign keys)
        
        # 1. Delete analytics events
        cursor.execute("DELETE FROM analytics_events WHERE user_id = %s", (user_id,))
        
        # 2. Delete assets (cascade will handle ar_codes)
        cursor.execute("DELETE FROM assets WHERE user_id = %s", (user_id,))
        
        # 3. Delete AR Codes
        cursor.execute("DELETE FROM ar_codes WHERE user_id = %s", (user_id,))
        
        # 4. Delete processing jobs
        cursor.execute("DELETE FROM processing_jobs WHERE user_id = %s", (user_id,))
        
        # 5. Delete webhooks
        cursor.execute("DELETE FROM webhooks WHERE user_id = %s", (user_id,))
        
        # 6. Delete user
        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"User data deleted: {user_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error deleting user data: {e}")
        conn.rollback()
        return False

def anonymize_user_data(user_id: str) -> bool:
    """
    Anonymize user data instead of deletion
    
    Args:
        user_id: User identifier
        
    Returns:
        True if successful
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Anonymize user
        cursor.execute("""
            UPDATE users 
            SET email = %s, 
                name = %s,
                updated_at = NOW()
            WHERE id = %s
        """, (
            f'anonymous_{user_id[:8]}@deleted.local',
            'Anonymous User',
            user_id
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"User data anonymized: {user_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error anonymizing user data: {e}")
        conn.rollback()
        return False

def get_consent_status(user_id: str) -> Dict[str, Any]:
    """
    Get user consent status
    
    Args:
        user_id: User identifier
        
    Returns:
        Consent status dict
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT 
                consent_analytics,
                consent_marketing,
                consent_cookies,
                consent_updated_at
            FROM users
            WHERE id = %s
        """, (user_id,))
        
        row = cursor.fetchone()
        
        if row:
            return {
                'analytics': row[0],
                'marketing': row[1],
                'cookies': row[2],
                'updated_at': row[3].isoformat() if row[3] else None
            }
        
        return {
            'analytics': False,
            'marketing': False,
            'cookies': False,
            'updated_at': None
        }
    
    except Exception as e:
        logger.error(f"Error getting consent status: {e}")
        return {}

def update_consent(user_id: str, consents: Dict[str, bool]) -> bool:
    """
    Update user consent preferences
    
    Args:
        user_id: User identifier
        consents: Dict of consent types and values
        
    Returns:
        True if successful
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE users 
            SET 
                consent_analytics = %s,
                consent_marketing = %s,
                consent_cookies = %s,
                consent_updated_at = NOW()
            WHERE id = %s
        """, (
            consents.get('analytics', False),
            consents.get('marketing', False),
            consents.get('cookies', False),
            user_id
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Consent updated for user: {user_id}")
        return True
    
    except Exception as e:
        logger.error(f"Error updating consent: {e}")
        conn.rollback()
        return False







