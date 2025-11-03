#!/usr/bin/env python3
"""
Database Migration Script
Automated migrations for PostgreSQL
"""

import os
import sys
import psycopg2
import argparse
from pathlib import Path
from typing import List
import logging

logger = logging.getLogger(__name__)

def get_db_connection(env: str = 'staging'):
    """Get PostgreSQL connection based on environment"""
    if env == 'production':
        return psycopg2.connect(
            host=os.getenv('DB_HOST_PROD'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME_PROD', 'arcode_db'),
            user=os.getenv('DB_USER_PROD', 'arcode_user'),
            password=os.getenv('DB_PASSWORD_PROD')
        )
    else:
        return psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME', 'arcode_db'),
            user=os.getenv('DB_USER', 'arcode_user'),
            password=os.getenv('DB_PASSWORD')
        )

def create_migrations_table(conn):
    """Create migrations tracking table"""
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version VARCHAR(255) PRIMARY KEY,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
    """)
    conn.commit()
    cursor.close()

def get_applied_migrations(conn) -> List[str]:
    """Get list of applied migrations"""
    cursor = conn.cursor()
    cursor.execute("SELECT version FROM schema_migrations ORDER BY version")
    versions = [row[0] for row in cursor.fetchall()]
    cursor.close()
    return versions

def apply_migration(conn, migration_file: Path):
    """Apply a single migration"""
    version = migration_file.stem
    
    logger.info(f"Applying migration: {version}")
    
    with open(migration_file, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    cursor = conn.cursor()
    try:
        # Execute migration (handle multiple statements)
        # Split by semicolon and execute each statement
        statements = [s.strip() for s in sql.split(';') if s.strip()]
        for statement in statements:
            if statement:
                cursor.execute(statement)
        
        # Record migration
        cursor.execute(
            "INSERT INTO schema_migrations (version) VALUES (%s)",
            (version,)
        )
        
        conn.commit()
        logger.info(f"✅ Migration {version} applied successfully")
        
    except Exception as e:
        conn.rollback()
        logger.error(f"❌ Migration {version} failed: {e}")
        raise
    finally:
        cursor.close()

def run_migrations(env: str = 'staging'):
    """Run all pending migrations"""
    conn = get_db_connection(env)
    
    try:
        # Create migrations table if not exists
        create_migrations_table(conn)
        
        # Get applied migrations
        applied = get_applied_migrations(conn)
        
        # Find migration files
        migrations_dir = Path(__file__).parent / 'migrations'
        migrations_dir.mkdir(exist_ok=True)
        
        migration_files = sorted(migrations_dir.glob('*.sql'))
        
        pending = [
            f for f in migration_files
            if f.stem not in applied
        ]
        
        if not pending:
            logger.info("✅ No pending migrations")
            return
        
        logger.info(f"📝 Found {len(pending)} pending migrations")
        
        # Apply migrations
        for migration_file in pending:
            apply_migration(conn, migration_file)
        
        logger.info("✅ All migrations applied successfully")
        
    except Exception as e:
        logger.error(f"❌ Migration failed: {e}")
        raise
    finally:
        conn.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run database migrations')
    parser.add_argument(
        '--env',
        choices=['staging', 'production'],
        default='staging',
        help='Environment (default: staging)'
    )
    
    args = parser.parse_args()
    
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    run_migrations(args.env)

