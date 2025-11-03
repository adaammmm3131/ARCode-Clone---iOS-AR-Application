#!/usr/bin/env python3
"""
Pytest Configuration
Fixtures and setup for backend tests
"""

import pytest
import os
import sys
from unittest.mock import Mock, patch
from flask import Flask
import psycopg2
from psycopg2.extras import RealDictCursor

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

@pytest.fixture
def app():
    """Create Flask test app"""
    from api.app import app as flask_app
    flask_app.config['TESTING'] = True
    flask_app.config['SECRET_KEY'] = 'test-secret-key'
    return flask_app

@pytest.fixture
def client(app):
    """Create test client"""
    return app.test_client()

@pytest.fixture
def mock_db():
    """Mock database connection"""
    mock_conn = Mock()
    mock_cursor = Mock()
    mock_conn.cursor.return_value = mock_cursor
    return mock_conn, mock_cursor

@pytest.fixture
def mock_redis():
    """Mock Redis connection"""
    mock_redis = Mock()
    mock_redis.ping.return_value = True
    mock_redis.get.return_value = None
    mock_redis.set.return_value = True
    return mock_redis

@pytest.fixture
def mock_network_service():
    """Mock network service"""
    mock_service = Mock()
    mock_service.request.return_value = {"success": True}
    return mock_service

@pytest.fixture(autouse=True)
def reset_environment():
    """Reset environment variables before each test"""
    original_env = os.environ.copy()
    yield
    os.environ.clear()
    os.environ.update(original_env)







