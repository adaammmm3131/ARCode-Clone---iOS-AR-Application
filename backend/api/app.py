#!/usr/bin/env python3
"""
ARCode Flask API - Main Application
Central entry point for all API endpoints
"""

from flask import Flask
from flask_cors import CORS
import os
import logging

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', os.urandom(32))
app.config['JSON_SORT_KEYS'] = False

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import and register blueprints/routes
from api import health_check
from api import data_api
from api import email_preferences_api
from api import auth_supabase
from api import redis_config
from api import cta_links_api
from api import ab_testing_api
from api import workspaces_api
from api import white_label_api

# Health check routes (no prefix, accessible at root)
app.add_url_rule('/health', 'health', health_check.health)
app.add_url_rule('/health/live', 'liveness', health_check.liveness)
app.add_url_rule('/health/ready', 'readiness', health_check.readiness)

# Register blueprints
app.register_blueprint(cta_links_api.cta_links_bp)
app.register_blueprint(ab_testing_api.ab_testing_bp)
app.register_blueprint(workspaces_api.workspaces_bp)
app.register_blueprint(white_label_api.white_label_bp)

# For now, routes are defined directly in each module
# They will be accessible when those modules are imported

# Initialize Sentry if configured
try:
    from monitoring.sentry_config import init_sentry
    init_sentry()
    logger.info("Sentry initialized")
except Exception as e:
    logger.warning(f"Sentry not initialized: {e}")

# Initialize Prometheus metrics if configured
try:
    from monitoring.api_metrics import metrics_middleware
    metrics_middleware(app)
    logger.info("Prometheus metrics enabled")
except Exception as e:
    logger.warning(f"Prometheus metrics not enabled: {e}")

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)

