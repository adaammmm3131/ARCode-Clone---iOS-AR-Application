#!/usr/bin/env python3
"""
Analytics Batch Processor
Batch processing pour aggregations et retention policy
"""

import os
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import logging
from typing import Dict, Any, List

logger = logging.getLogger(__name__)

# Retention policy (days)
RETENTION_DAYS = int(os.getenv('ANALYTICS_RETENTION_DAYS', '365'))

def get_db_connection():
    """Get PostgreSQL connection"""
    return psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=int(os.getenv('DB_PORT', 5432)),
        database=os.getenv('DB_NAME', 'arcode_db'),
        user=os.getenv('DB_USER', 'arcode_user'),
        password=os.getenv('DB_PASSWORD')
    )

def aggregate_daily_stats(date: datetime) -> bool:
    """Aggregate daily stats from events"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create aggregations table if not exists
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS analytics_daily_stats (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                date DATE NOT NULL,
                ar_code_id UUID REFERENCES ar_codes(id) ON DELETE CASCADE,
                event_type VARCHAR(50) NOT NULL,
                count INTEGER DEFAULT 0,
                unique_users INTEGER DEFAULT 0,
                unique_sessions INTEGER DEFAULT 0,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(date, ar_code_id, event_type)
            )
        """)
        
        # Aggregate events for date
        start_date = date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=1)
        
        cursor.execute("""
            INSERT INTO analytics_daily_stats (
                date, ar_code_id, event_type, count, unique_users, unique_sessions
            )
            SELECT 
                DATE(created_at) as date,
                ar_code_id,
                event_type,
                COUNT(*) as count,
                COUNT(DISTINCT user_id) as unique_users,
                COUNT(DISTINCT (event_data->>'session_id')) as unique_sessions
            FROM analytics_events
            WHERE created_at >= %s AND created_at < %s
            GROUP BY DATE(created_at), ar_code_id, event_type
            ON CONFLICT (date, ar_code_id, event_type)
            DO UPDATE SET
                count = EXCLUDED.count,
                unique_users = EXCLUDED.unique_users,
                unique_sessions = EXCLUDED.unique_sessions
        """, (start_date, end_date))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Aggregated stats for {date.date()}")
        return True
    
    except Exception as e:
        logger.error(f"Error aggregating stats: {e}")
        return False

def cleanup_old_events() -> int:
    """Delete events older than retention policy"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cutoff_date = datetime.utcnow() - timedelta(days=RETENTION_DAYS)
        
        cursor.execute("""
            DELETE FROM analytics_events
            WHERE created_at < %s
        """, (cutoff_date,))
        
        deleted_count = cursor.rowcount
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"Deleted {deleted_count} old events")
        return deleted_count
    
    except Exception as e:
        logger.error(f"Error cleaning up old events: {e}")
        return 0

def process_yesterday_stats():
    """Process stats for yesterday"""
    yesterday = datetime.utcnow() - timedelta(days=1)
    return aggregate_daily_stats(yesterday)

if __name__ == '__main__':
    # Run batch processing
    process_yesterday_stats()
    cleanup_old_events()

