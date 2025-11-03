#!/usr/bin/env python3
"""
GDPR API Endpoints
Data export, deletion, consent management
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from auth_supabase import require_auth
from security.gdpr_manager import (
    export_user_data,
    delete_user_data,
    anonymize_user_data,
    get_consent_status,
    update_consent
)
import json
import logging

logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

@app.route('/api/v1/gdpr/export', methods=['GET'])
@require_auth
def export_data(user):
    """Export all user data"""
    try:
        user_id = user.get('sub')
        data = export_user_data(user_id)
        
        return jsonify(data), 200
    
    except Exception as e:
        logger.error(f"Error exporting data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/gdpr/delete', methods=['POST'])
@require_auth
def delete_data(user):
    """Delete all user data (right to be forgotten)"""
    try:
        user_id = user.get('sub')
        
        # Confirm deletion (should require password in production)
        confirm = request.json.get('confirm', False)
        if not confirm:
            return jsonify({'error': 'Confirmation required'}), 400
        
        success = delete_user_data(user_id)
        
        if success:
            return jsonify({'message': 'Data deleted successfully'}), 200
        else:
            return jsonify({'error': 'Failed to delete data'}), 500
    
    except Exception as e:
        logger.error(f"Error deleting data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/gdpr/anonymize', methods=['POST'])
@require_auth
def anonymize_data(user):
    """Anonymize user data instead of deletion"""
    try:
        user_id = user.get('sub')
        success = anonymize_user_data(user_id)
        
        if success:
            return jsonify({'message': 'Data anonymized successfully'}), 200
        else:
            return jsonify({'error': 'Failed to anonymize data'}), 500
    
    except Exception as e:
        logger.error(f"Error anonymizing data: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/gdpr/consent', methods=['GET'])
@require_auth
def get_consent(user):
    """Get user consent status"""
    try:
        user_id = user.get('sub')
        consent = get_consent_status(user_id)
        
        return jsonify(consent), 200
    
    except Exception as e:
        logger.error(f"Error getting consent: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/gdpr/consent', methods=['POST'])
@require_auth
def update_consent_endpoint(user):
    """Update user consent preferences"""
    try:
        user_id = user.get('sub')
        data = request.json
        
        consents = {
            'analytics': data.get('analytics', False),
            'marketing': data.get('marketing', False),
            'cookies': data.get('cookies', False)
        }
        
        success = update_consent(user_id, consents)
        
        if success:
            return jsonify({'message': 'Consent updated'}), 200
        else:
            return jsonify({'error': 'Failed to update consent'}), 500
    
    except Exception as e:
        logger.error(f"Error updating consent: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)







