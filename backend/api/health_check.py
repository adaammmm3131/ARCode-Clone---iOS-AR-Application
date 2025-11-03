#!/usr/bin/env python3
"""
Health Check Endpoint
For deployment verification and monitoring
"""

from flask import Flask, jsonify
import psycopg2
import redis
import requests
import os

app = Flask(__name__)

def check_database():
    """Check PostgreSQL connection"""
    try:
        conn = psycopg2.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', 5432)),
            database=os.getenv('DB_NAME', 'arcode_db'),
            user=os.getenv('DB_USER', 'arcode_user'),
            password=os.getenv('DB_PASSWORD'),
            connect_timeout=5
        )
        conn.close()
        return {'status': 'healthy', 'latency_ms': 0}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}

def check_redis():
    """Check Redis connection"""
    try:
        r = redis.Redis(
            host=os.getenv('REDIS_HOST', 'localhost'),
            port=int(os.getenv('REDIS_PORT', 6379)),
            password=os.getenv('REDIS_PASSWORD'),
            socket_timeout=5
        )
        r.ping()
        return {'status': 'healthy'}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}

def check_storage():
    """Check Cloudflare R2 (S3-compatible)"""
    try:
        # Simple check - verify credentials are configured
        if not os.getenv('R2_ACCESS_KEY_ID'):
            return {'status': 'unhealthy', 'error': 'R2 credentials not configured'}
        return {'status': 'healthy'}
    except Exception as e:
        return {'status': 'unhealthy', 'error': str(e)}

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    checks = {
        'database': check_database(),
        'redis': check_redis(),
        'storage': check_storage(),
        'status': 'healthy'
    }
    
    # Determine overall status
    unhealthy = [
        name for name, result in checks.items()
        if name != 'status' and result.get('status') != 'healthy'
    ]
    
    if unhealthy:
        checks['status'] = 'unhealthy'
        return jsonify(checks), 503
    
    return jsonify(checks), 200

@app.route('/health/live', methods=['GET'])
def liveness():
    """Kubernetes liveness probe"""
    return jsonify({'status': 'alive'}), 200

@app.route('/health/ready', methods=['GET'])
def readiness():
    """Kubernetes readiness probe"""
    db_check = check_database()
    if db_check['status'] != 'healthy':
        return jsonify({'status': 'not ready'}), 503
    return jsonify({'status': 'ready'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)







