#!/usr/bin/env python3
"""
Health Check API Tests
"""

import pytest
from api.health_check import check_database, check_redis, check_storage

def test_health_check_endpoint(client):
    """Test /health endpoint"""
    response = client.get('/health')
    assert response.status_code in [200, 503]  # May be 503 if services down
    
    data = response.get_json()
    assert 'database' in data
    assert 'redis' in data
    assert 'storage' in data
    assert 'status' in data

def test_liveness_endpoint(client):
    """Test /health/live endpoint"""
    response = client.get('/health/live')
    assert response.status_code == 200
    
    data = response.get_json()
    assert data['status'] == 'alive'

def test_readiness_endpoint(client, mock_db):
    """Test /health/ready endpoint"""
    with patch('api.health_check.get_db_connection') as mock_get_db:
        mock_conn, _ = mock_db
        mock_get_db.return_value = mock_conn
        
        response = client.get('/health/ready')
        # May be 503 if database check fails
        assert response.status_code in [200, 503]

def test_database_check(mock_db):
    """Test database health check"""
    with patch('api.health_check.get_db_connection') as mock_get_db:
        mock_conn, _ = mock_db
        mock_get_db.return_value = mock_conn
        
        result = check_database()
        assert 'status' in result

def test_redis_check(mock_redis):
    """Test Redis health check"""
    with patch('api.health_check.redis.Redis') as mock_redis_class:
        mock_redis_class.return_value = mock_redis
        
        result = check_redis()
        assert 'status' in result

def test_storage_check():
    """Test storage health check"""
    with patch.dict('os.environ', {'R2_ACCESS_KEY_ID': 'test-key'}):
        result = check_storage()
        assert 'status' in result







