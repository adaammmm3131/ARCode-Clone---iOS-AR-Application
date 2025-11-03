#!/usr/bin/env python3
"""
Sentry Configuration for Backend
Error tracking and performance monitoring
"""

import os
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.redis import RedisIntegration
import logging

logger = logging.getLogger(__name__)

def init_sentry():
    """Initialize Sentry SDK"""
    sentry_dsn = os.getenv('SENTRY_DSN')
    
    if not sentry_dsn:
        logger.warning("SENTRY_DSN not configured, skipping Sentry initialization")
        return
    
    sentry_sdk.init(
        dsn=sentry_dsn,
        environment=os.getenv('SENTRY_ENV', 'production'),
        release=os.getenv('SENTRY_RELEASE', 'ar-code@1.0.0'),
        traces_sample_rate=0.1,  # 10% of transactions
        profiles_sample_rate=0.1,  # 10% of transactions for profiling
        integrations=[
            FlaskIntegration(),
            SqlalchemyIntegration(),
            RedisIntegration()
        ],
        before_send=filter_sensitive_data,
        max_breadcrumbs=50
    )
    
    logger.info("Sentry initialized successfully")

def filter_sensitive_data(event, hint):
    """Filter sensitive data from Sentry events"""
    if 'request' in event and event['request']:
        # Filter headers
        if 'headers' in event['request']:
            headers = event['request']['headers']
            # Remove sensitive headers
            sensitive_headers = ['authorization', 'x-api-key', 'cookie', 'x-auth-token']
            for header in sensitive_headers:
                if header in headers:
                    headers[header] = '[Filtered]'
        
        # Filter body for POST requests
        if 'data' in event['request'] and isinstance(event['request']['data'], dict):
            sensitive_fields = ['password', 'secret', 'token', 'api_key']
            data = event['request']['data']
            for field in sensitive_fields:
                if field in data:
                    data[field] = '[Filtered]'
    
    return event

def capture_exception(exception: Exception, context: dict = None):
    """Capture exception with context"""
    with sentry_sdk.push_scope() as scope:
        if context:
            for key, value in context.items():
                scope.set_context(key, value)
        sentry_sdk.capture_exception(exception)

def capture_message(message: str, level: str = 'info'):
    """Capture message"""
    sentry_sdk.capture_message(message, level=level)

def set_user(user_id: str = None, email: str = None, username: str = None):
    """Set user context"""
    sentry_sdk.set_user({
        'id': user_id,
        'email': email,
        'username': username
    })







