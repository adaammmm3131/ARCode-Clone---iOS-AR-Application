#!/usr/bin/env python3
"""
ARCode Flask API - Simple Version (without DB dependencies)
For quick testing on Windows without PostgreSQL/Redis
"""

from flask import Flask, jsonify
from flask_cors import CORS
import os
import logging

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', 'dev-secret-key')
app.config['JSON_SORT_KEYS'] = False

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Health check endpoint (simple version)
@app.route('/health', methods=['GET'])
def health():
    """Simple health check"""
    return jsonify({
        'status': 'ok',
        'message': 'ARCode API is running',
        'version': '1.0.0'
    }), 200

@app.route('/health/live', methods=['GET'])
def liveness():
    """Liveness probe"""
    return jsonify({'status': 'alive'}), 200

@app.route('/health/ready', methods=['GET'])
def readiness():
    """Readiness probe (simplified - no DB check)"""
    return jsonify({'status': 'ready'}), 200

# Simple API endpoint for testing
@app.route('/api/v1/test', methods=['GET'])
def test():
    """Test endpoint"""
    return jsonify({
        'message': 'API is working!',
        'platform': 'Windows',
        'python_version': os.sys.version
    }), 200

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return jsonify({
        'name': 'ARCode API',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'health': '/health',
            'test': '/api/v1/test'
        }
    }), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'
    logger.info(f"Starting ARCode API on http://0.0.0.0:{port}")
    logger.info(f"Debug mode: {debug}")
    app.run(host='0.0.0.0', port=port, debug=debug)


