#!/usr/bin/env python3
"""
Flask API Metrics for Prometheus
Custom metrics endpoint for application monitoring
"""

from flask import Flask, Response
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time
from functools import wraps

# Metrics definitions
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

http_request_size_bytes = Histogram(
    'http_request_size_bytes',
    'HTTP request size in bytes',
    ['method', 'endpoint']
)

active_connections = Gauge(
    'active_connections',
    'Active API connections'
)

processing_jobs_total = Counter(
    'processing_jobs_total',
    'Total processing jobs',
    ['job_type', 'status']
)

processing_job_duration_seconds = Histogram(
    'processing_job_duration_seconds',
    'Processing job duration',
    ['job_type']
)

def metrics_middleware(app: Flask):
    """Add metrics middleware to Flask app"""
    
    @app.before_request
    def before_request():
        request.start_time = time.time()
    
    @app.after_request
    def after_request(response):
        # Record request metrics
        duration = time.time() - request.start_time
        
        http_requests_total.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown',
            status=response.status_code
        ).inc()
        
        http_request_duration_seconds.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown'
        ).observe(duration)
        
        if request.content_length:
            http_request_size_bytes.labels(
                method=request.method,
                endpoint=request.endpoint or 'unknown'
            ).observe(request.content_length)
        
        return response
    
    @app.route('/metrics')
    def metrics():
        """Prometheus metrics endpoint"""
        return Response(
            generate_latest(),
            mimetype=CONTENT_TYPE_LATEST
        )

def track_processing_job(job_type: str, status: str, duration: float):
    """Track processing job metrics"""
    processing_jobs_total.labels(
        job_type=job_type,
        status=status
    ).inc()
    
    processing_job_duration_seconds.labels(
        job_type=job_type
    ).observe(duration)







