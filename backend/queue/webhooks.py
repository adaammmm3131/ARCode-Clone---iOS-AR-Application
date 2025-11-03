#!/usr/bin/env python3
"""
Webhooks System
Signature validation, retry logic, delivery tracking
"""

import os
import hmac
import hashlib
import requests
import json
import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
from enum import Enum
from job_tracker import get_db_connection
from psycopg2.extras import RealDictCursor
import uuid

logger = logging.getLogger(__name__)

class WebhookEvent(str, Enum):
    AR_CODE_CREATED = "ar_code.created"
    AR_CODE_SCANNED = "ar_code.scanned"
    PROCESSING_COMPLETED = "processing.completed"
    PROCESSING_FAILED = "processing.failed"
    ANALYTICS_UPDATED = "analytics.updated"

class DeliveryStatus(str, Enum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"

def generate_webhook_signature(payload: str, secret: str) -> str:
    """Generate HMAC signature for webhook payload"""
    return hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

def verify_webhook_signature(payload: str, signature: str, secret: str) -> bool:
    """Verify webhook signature"""
    expected_signature = generate_webhook_signature(payload, secret)
    return hmac.compare_digest(expected_signature, signature)

def register_webhook(
    user_id: str,
    url: str,
    events: List[str],
    ar_code_id: Optional[str] = None
) -> str:
    """Register a new webhook"""
    webhook_id = str(uuid.uuid4())
    secret = os.urandom(32).hex()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO webhooks (
                id, user_id, ar_code_id, url, events, secret, is_active, created_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s
            )
        """, (
            webhook_id,
            user_id,
            ar_code_id,
            url,
            events,
            secret,
            True,
            datetime.utcnow()
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return webhook_id
    
    except Exception as e:
        logger.error(f"Error registering webhook: {e}")
        raise

def trigger_webhook(
    event_type: WebhookEvent,
    payload: Dict[str, Any],
    webhook_id: Optional[str] = None,
    ar_code_id: Optional[str] = None,
    user_id: Optional[str] = None
):
    """Trigger webhook for event"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Find webhooks for this event
        query = """
            SELECT * FROM webhooks
            WHERE is_active = TRUE
            AND %s = ANY(events)
        """
        params = [event_type.value]
        
        if webhook_id:
            query += " AND id = %s"
            params.append(webhook_id)
        elif ar_code_id:
            query += " AND (ar_code_id = %s OR ar_code_id IS NULL)"
            params.append(ar_code_id)
        elif user_id:
            query += " AND user_id = %s"
            params.append(user_id)
        
        cursor.execute(query, params)
        webhooks = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        # Deliver to each webhook
        for webhook in webhooks:
            deliver_webhook(webhook, event_type, payload)
    
    except Exception as e:
        logger.error(f"Error triggering webhook: {e}")

def deliver_webhook(
    webhook: Dict[str, Any],
    event_type: WebhookEvent,
    payload: Dict[str, Any]
):
    """Deliver webhook with retry logic"""
    webhook_id = webhook['id']
    url = webhook['url']
    secret = webhook['secret']
    
    # Prepare payload
    full_payload = {
        'event': event_type.value,
        'timestamp': datetime.utcnow().isoformat(),
        'data': payload
    }
    
    payload_json = json.dumps(full_payload)
    signature = generate_webhook_signature(payload_json, secret)
    
    # Headers
    headers = {
        'Content-Type': 'application/json',
        'X-ARCode-Signature': signature,
        'X-ARCode-Event': event_type.value
    }
    
    # Create delivery record
    delivery_id = str(uuid.uuid4())
    max_retries = 3
    retry_count = 0
    
    while retry_count <= max_retries:
        try:
            # Send webhook
            response = requests.post(
                url,
                json=full_payload,
                headers=headers,
                timeout=10
            )
            
            # Record delivery
            record_delivery(
                delivery_id,
                webhook_id,
                event_type.value,
                full_payload,
                DeliveryStatus.SUCCESS if response.status_code == 200 else DeliveryStatus.FAILED,
                response.status_code,
                response.text[:1000] if response.text else None,
                retry_count
            )
            
            if response.status_code == 200:
                return
            
            # Retry on failure
            retry_count += 1
            if retry_count <= max_retries:
                # Exponential backoff
                wait_time = 2 ** retry_count
                import time
                time.sleep(wait_time)
        
        except requests.RequestException as e:
            logger.error(f"Webhook delivery error: {e}")
            
            # Record failed delivery
            record_delivery(
                delivery_id,
                webhook_id,
                event_type.value,
                full_payload,
                DeliveryStatus.FAILED,
                None,
                str(e),
                retry_count
            )
            
            retry_count += 1
            if retry_count <= max_retries:
                wait_time = 2 ** retry_count
                import time
                time.sleep(wait_time)

def record_delivery(
    delivery_id: str,
    webhook_id: str,
    event_type: str,
    payload: Dict[str, Any],
    status: DeliveryStatus,
    status_code: Optional[int],
    response_body: Optional[str],
    retry_count: int
):
    """Record webhook delivery in database"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO webhook_deliveries (
                id, webhook_id, event_type, payload, status,
                status_code, response_body, retry_count, created_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s
            )
        """, (
            delivery_id,
            webhook_id,
            event_type,
            json.dumps(payload),
            status.value,
            status_code,
            response_body,
            retry_count,
            datetime.utcnow()
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
    
    except Exception as e:
        logger.error(f"Error recording delivery: {e}")









