#!/usr/bin/env python3
"""
Email Notification Service
Manage user notification preferences and send notifications
"""

import os
import psycopg2
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import logging
from brevo_service import (
    send_welcome_email,
    send_processing_complete_email,
    send_weekly_stats_email,
    send_error_alert_email
)

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

def get_user_notification_preferences(user_id: str) -> Dict[str, bool]:
    """
    Get user notification preferences
    
    Args:
        user_id: User identifier
        
    Returns:
        Dict of notification preferences
    """
    try:
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
            return {
                'processing': row[0] if row[0] is not None else True,
                'scans': row[1] if row[1] is not None else False,
                'weekly_stats': row[2] if row[2] is not None else True,
                'marketing': row[3] if row[3] is not None else False
            }
        
        return {
            'processing': True,
            'scans': False,
            'weekly_stats': True,
            'marketing': False
        }
    
    except Exception as e:
        logger.error(f"Error getting notification preferences: {e}")
        return {
            'processing': True,
            'scans': False,
            'weekly_stats': True,
            'marketing': False
        }

def send_processing_notification(
    user_id: str,
    asset_type: str,
    asset_name: str,
    asset_url: str
) -> bool:
    """Send processing complete notification if enabled"""
    try:
        preferences = get_user_notification_preferences(user_id)
        
        if not preferences.get('processing', True):
            return False
        
        # Get user email and name
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT email, full_name FROM users WHERE id = %s
        """, (user_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return False
        
        user_email = row[0]
        user_name = row[1]
        
        return send_processing_complete_email(
            user_email=user_email,
            user_name=user_name,
            asset_type=asset_type,
            asset_name=asset_name,
            asset_url=asset_url
        )
    
    except Exception as e:
        logger.error(f"Error sending processing notification: {e}")
        return False

def send_ar_code_scanned_notification(
    ar_code_id: str,
    scanner_email: Optional[str] = None
) -> bool:
    """Send notification when AR Code is scanned (if enabled)"""
    try:
        # Get AR Code owner
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT u.id, u.email, u.full_name, ac.title
            FROM ar_codes ac
            JOIN users u ON ac.user_id = u.id
            WHERE ac.id = %s
        """, (ar_code_id,))
        
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not row:
            return False
        
        user_id = row[0]
        user_email = row[1]
        user_name = row[2]
        ar_code_title = row[3]
        
        preferences = get_user_notification_preferences(user_id)
        
        if not preferences.get('scans', False):
            return False
        
        # Send scan notification email (custom template)
        from brevo_service import send_transactional_email
        
        html_content = f"""
        <h2>Votre AR Code a été scanné!</h2>
        <p>Bonjour {user_name or 'Cher utilisateur'},</p>
        <p>Votre AR Code "<strong>{ar_code_title}</strong>" vient d'être scanné!</p>
        <p><a href="https://ar-code.com/ar-codes/{ar_code_id}">Voir les détails</a></p>
        """
        
        return send_transactional_email(
            to_email=user_email,
            to_name=user_name,
            subject=f"Votre AR Code '{ar_code_title}' a été scanné!",
            html_content=html_content,
            tags=["scan", "notification"]
        )
    
    except Exception as e:
        logger.error(f"Error sending scan notification: {e}")
        return False

def send_weekly_stats_to_users() -> int:
    """Send weekly stats to all users who opted in"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get users who opted in for weekly stats
        cursor.execute("""
            SELECT id, email, full_name
            FROM users
            WHERE email_notifications_weekly_stats = TRUE
            AND is_active = TRUE
        """)
        
        users = cursor.fetchall()
        cursor.close()
        conn.close()
        
        sent_count = 0
        
        for user_id, email, full_name in users:
            try:
                # Get weekly stats
                stats = get_user_weekly_stats(user_id)
                
                # Send email
                if send_weekly_stats_email(email, full_name, stats):
                    sent_count += 1
            
            except Exception as e:
                logger.error(f"Error sending weekly stats to {email}: {e}")
        
        return sent_count
    
    except Exception as e:
        logger.error(f"Error in weekly stats batch: {e}")
        return 0

def get_user_weekly_stats(user_id: str) -> Dict[str, Any]:
    """Get user weekly stats"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get stats for last 7 days
        week_ago = datetime.utcnow() - timedelta(days=7)
        
        # Total scans
        cursor.execute("""
            SELECT COUNT(*)
            FROM analytics_events
            WHERE user_id = %s
            AND event_type = 'qr_scan'
            AND created_at >= %s
        """, (user_id, week_ago))
        total_scans = cursor.fetchone()[0] or 0
        
        # Total views
        cursor.execute("""
            SELECT COUNT(*)
            FROM analytics_events
            WHERE user_id = %s
            AND event_type = 'placement'
            AND created_at >= %s
        """, (user_id, week_ago))
        total_views = cursor.fetchone()[0] or 0
        
        # Active AR Codes
        cursor.execute("""
            SELECT COUNT(DISTINCT ar_code_id)
            FROM analytics_events
            WHERE user_id = %s
            AND created_at >= %s
            AND ar_code_id IS NOT NULL
        """, (user_id, week_ago))
        active_codes = cursor.fetchone()[0] or 0
        
        # Top AR Code
        cursor.execute("""
            SELECT ac.title, COUNT(*) as scan_count
            FROM analytics_events ae
            JOIN ar_codes ac ON ae.ar_code_id = ac.id
            WHERE ae.user_id = %s
            AND ae.event_type = 'qr_scan'
            AND ae.created_at >= %s
            GROUP BY ac.id, ac.title
            ORDER BY scan_count DESC
            LIMIT 1
        """, (user_id, week_ago))
        top_row = cursor.fetchone()
        top_code = top_row[0] if top_row else 'Aucun'
        
        cursor.close()
        conn.close()
        
        return {
            'total_scans': total_scans,
            'total_views': total_views,
            'active_codes': active_codes,
            'top_code': top_code
        }
    
    except Exception as e:
        logger.error(f"Error getting weekly stats: {e}")
        return {
            'total_scans': 0,
            'total_views': 0,
            'active_codes': 0,
            'top_code': 'N/A'
        }







