#!/usr/bin/env python3
"""
AR Data API - Endpoints REST pour données dynamiques
OAuth 2.0, rate limiting, webhook support, JSON format
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import os
import json
from datetime import datetime
from typing import Dict, Any, Optional
import jwt
import secrets

app = Flask(__name__)
CORS(app)

# Rate Limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["100 per minute", "1000 per hour"],
    storage_uri="memory://"  # Utiliser Redis en production
)

# Configuration
JWT_SECRET = os.getenv("JWT_SECRET", secrets.token_urlsafe(32))
JWT_ALGORITHM = "HS256"
TOKEN_EXPIRY = 3600  # 1 heure

# Client credentials (en production, depuis base de données)
CLIENTS = {
    "default_client_id": {
        "secret": "default_client_secret",
        "redirect_uris": ["ar-code://oauth/callback"]
    }
}

# Store tokens (en production, utiliser Redis ou database)
access_tokens: Dict[str, Dict] = {}
refresh_tokens: Dict[str, Dict] = {}

# Webhooks registry
webhooks: Dict[str, Dict] = {}

# OAuth 2.0 Authorization Endpoint
@app.route('/oauth/authorize', methods=['GET'])
def authorize():
    """
    OAuth 2.0 Authorization endpoint
    """
    client_id = request.args.get('client_id')
    redirect_uri = request.args.get('redirect_uri')
    response_type = request.args.get('response_type')
    
    if response_type != 'code':
        return jsonify({'error': 'unsupported_response_type'}), 400
    
    # Générer authorization code
    auth_code = secrets.token_urlsafe(32)
    
    # En production, sauvegarder auth_code avec expiration
    # Pour l'instant, simuler retour code
    if redirect_uri:
        return jsonify({
            'authorization_code': auth_code,
            'redirect_uri': redirect_uri
        }), 200
    
    return jsonify({'error': 'invalid_request'}), 400

# OAuth 2.0 Token Endpoint
@app.route('/oauth/token', methods=['POST'])
def token():
    """
    OAuth 2.0 Token endpoint
    Exchange authorization code or refresh token
    """
    data = request.get_json()
    grant_type = data.get('grant_type')
    
    if grant_type == 'authorization_code':
        code = data.get('code')
        client_id = data.get('client_id')
        client_secret = data.get('client_secret')
        
        # Vérifier credentials
        if client_id not in CLIENTS or CLIENTS[client_id]['secret'] != client_secret:
            return jsonify({'error': 'invalid_client'}), 401
        
        # En production, vérifier code avec base de données
        # Pour l'instant, accepter n'importe quel code
        
        # Générer tokens
        access_token = secrets.token_urlsafe(32)
        refresh_token = secrets.token_urlsafe(32)
        
        access_tokens[access_token] = {
            'client_id': client_id,
            'expires_at': datetime.now().timestamp() + TOKEN_EXPIRY,
            'scope': 'read write'
        }
        
        refresh_tokens[refresh_token] = {
            'client_id': client_id,
            'access_token': access_token
        }
        
        return jsonify({
            'access_token': access_token,
            'refresh_token': refresh_token,
            'token_type': 'Bearer',
            'expires_in': TOKEN_EXPIRY,
            'scope': 'read write'
        }), 200
    
    elif grant_type == 'refresh_token':
        refresh_token = data.get('refresh_token')
        client_id = data.get('client_id')
        client_secret = data.get('client_secret')
        
        if client_id not in CLIENTS or CLIENTS[client_id]['secret'] != client_secret:
            return jsonify({'error': 'invalid_client'}), 401
        
        if refresh_token not in refresh_tokens:
            return jsonify({'error': 'invalid_grant'}), 400
        
        # Générer nouveau access token
        access_token = secrets.token_urlsafe(32)
        access_tokens[access_token] = {
            'client_id': client_id,
            'expires_at': datetime.now().timestamp() + TOKEN_EXPIRY,
            'scope': 'read write'
        }
        
        return jsonify({
            'access_token': access_token,
            'token_type': 'Bearer',
            'expires_in': TOKEN_EXPIRY
        }), 200
    
    return jsonify({'error': 'unsupported_grant_type'}), 400

# Data API Endpoint
@app.route('/api/v1/data', methods=['GET'])
@limiter.limit("100 per minute")
def get_data():
    """
    Endpoint générique pour récupérer données dynamiques
    Support templates: IoT, Pricing, Member Card
    """
    # Vérifier authentification
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'unauthorized'}), 401
    
    token = auth_header.split(' ')[1]
    if token not in access_tokens:
        return jsonify({'error': 'invalid_token'}), 401
    
    token_data = access_tokens[token]
    if datetime.now().timestamp() > token_data['expires_at']:
        return jsonify({'error': 'token_expired'}), 401
    
    # Type de données demandé
    data_type = request.args.get('type', 'generic')
    template = request.args.get('template', 'generic')
    
    # Générer données selon template
    data = generate_template_data(data_type, template)
    
    return jsonify({
        'data': data,
        'timestamp': datetime.now().isoformat(),
        'source': f'{data_type}_{template}',
        'template': template
    }), 200

# Webhook Registration
@app.route('/api/v1/webhooks/register', methods=['POST'])
@limiter.limit("10 per minute")
def register_webhook():
    """
    Enregistrer webhook pour notifications
    """
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'unauthorized'}), 401
    
    token = auth_header.split(' ')[1]
    if token not in access_tokens:
        return jsonify({'error': 'invalid_token'}), 401
    
    data = request.get_json()
    url = data.get('url')
    events = data.get('events', [])
    secret = data.get('secret')
    
    if not url or not events:
        return jsonify({'error': 'invalid_request'}), 400
    
    # Enregistrer webhook
    webhook_id = secrets.token_urlsafe(16)
    webhooks[webhook_id] = {
        'url': url,
        'events': events,
        'secret': secret,
        'client_id': access_tokens[token]['client_id'],
        'created_at': datetime.now().isoformat()
    }
    
    return jsonify({
        'webhook_id': webhook_id,
        'url': url,
        'events': events
    }), 201

# Webhook Trigger (simulation)
@app.route('/api/v1/webhooks/trigger/<webhook_id>', methods=['POST'])
def trigger_webhook(webhook_id: str):
    """
    Déclencher webhook (pour tests)
    """
    if webhook_id not in webhooks:
        return jsonify({'error': 'webhook_not_found'}), 404
    
    # En production, envoyer requête HTTP POST au webhook URL
    # Avec signature validation
    
    return jsonify({'status': 'triggered'}), 200

# Helper Functions
def generate_template_data(data_type: str, template: str) -> Dict[str, Any]:
    """
    Génère données exemple selon template
    """
    if template == 'iot':
        return {
            'temperature': round(20.5 + (datetime.now().timestamp() % 10), 2),
            'humidity': round(45.0 + (datetime.now().timestamp() % 15), 2),
            'pressure': round(1013.25 + (datetime.now().timestamp() % 5), 2),
            'status': 'active'
        }
    elif template == 'pricing':
        return {
            'product_name': 'Sample Product',
            'price': round(99.99 + (datetime.now().timestamp() % 10), 2),
            'price_change': round(-2.5 + (datetime.now().timestamp() % 5), 2),
            'change_percent': round(-2.5 + (datetime.now().timestamp() % 5), 2),
            'currency': 'EUR'
        }
    elif template == 'member_card':
        return {
            'name': 'John Doe',
            'member_id': 'MEM123456',
            'status': 'active',
            'points': int(1000 + (datetime.now().timestamp() % 100))
        }
    else:
        # Generic
        return {
            'value1': f'Data {int(datetime.now().timestamp())}',
            'value2': round(datetime.now().timestamp() % 100, 2),
            'status': 'ok'
        }

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5003))
    app.run(host='0.0.0.0', port=port, debug=False)









