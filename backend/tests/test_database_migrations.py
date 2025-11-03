#!/usr/bin/env python3
"""
Database Migration Tests
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path

def test_migration_table_creation(mock_db):
    """Test schema_migrations table creation"""
    from database.migrate import create_migrations_table
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.execute.return_value = None
    
    create_migrations_table(mock_conn)
    
    # Verify table creation was attempted
    assert mock_cursor.execute.called

def test_get_applied_migrations(mock_db):
    """Test getting applied migrations"""
    from database.migrate import get_applied_migrations
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.fetchall.return_value = [
        ('20240101_120000_initial',),
        ('20240102_120000_add_users',)
    ]
    
    migrations = get_applied_migrations(mock_conn)
    
    assert len(migrations) == 2
    assert '20240101_120000_initial' in migrations

def test_apply_migration(mock_db):
    """Test applying a migration"""
    from database.migrate import apply_migration
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.execute.return_value = None
    
    # Create temporary migration file
    migration_file = Path('/tmp/test_migration.sql')
    migration_file.write_text('CREATE TABLE test (id INT);')
    
    try:
        apply_migration(mock_conn, migration_file)
        assert mock_cursor.execute.called
    finally:
        migration_file.unlink(missing_ok=True)

def test_run_migrations_integration(mock_db):
    """Test running migrations"""
    from database.migrate import run_migrations
    
    mock_conn, mock_cursor = mock_db
    mock_cursor.fetchall.return_value = []  # No applied migrations
    
    with patch('database.migrate.get_db_connection', return_value=mock_conn):
        with patch('pathlib.Path.glob', return_value=[]):  # No migration files
            run_migrations('staging')
            # Should complete without errors







