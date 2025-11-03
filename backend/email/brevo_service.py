#!/usr/bin/env python3
"""
Brevo Email Service
SMTP and API integration for transactional emails
"""

import os
import requests
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional, Dict, Any, List
import logging

logger = logging.getLogger(__name__)

# Brevo Configuration
BREVO_API_KEY = os.getenv('BREVO_API_KEY')
BREVO_SMTP_HOST = os.getenv('BREVO_SMTP_HOST', 'smtp-relay.brevo.com')
BREVO_SMTP_PORT = int(os.getenv('BREVO_SMTP_PORT', '587'))
BREVO_SMTP_USER = os.getenv('BREVO_SMTP_USER', BREVO_API_KEY) if BREVO_API_KEY else None
BREVO_SMTP_PASSWORD = os.getenv('BREVO_SMTP_PASSWORD', BREVO_API_KEY) if BREVO_API_KEY else None
BREVO_SENDER_EMAIL = os.getenv('BREVO_SENDER_EMAIL', '[email protected]')
BREVO_SENDER_NAME = os.getenv('BREVO_SENDER_NAME', 'AR Code')

def send_transactional_email(
    to_email: str,
    to_name: Optional[str],
    subject: str,
    html_content: str,
    text_content: Optional[str] = None,
    template_id: Optional[int] = None,
    params: Optional[Dict[str, Any]] = None,
    tags: Optional[List[str]] = None
) -> bool:
    """
    Send transactional email via Brevo API
    
    Args:
        to_email: Recipient email
        to_name: Recipient name
        subject: Email subject
        html_content: HTML email content
        text_content: Plain text content (optional)
        template_id: Brevo template ID (optional)
        params: Template parameters (optional)
        tags: Email tags for tracking (optional)
        
    Returns:
        True if successful
    """
    if not BREVO_API_KEY:
        logger.error("BREVO_API_KEY not configured")
        return False
    
    try:
        url = "https://api.brevo.com/v3/smtp/email"
        
        payload = {
            "sender": {
                "name": BREVO_SENDER_NAME,
                "email": BREVO_SENDER_EMAIL
            },
            "to": [{
                "email": to_email,
                "name": to_name or ""
            }],
            "subject": subject
        }
        
        # Use template or direct content
        if template_id:
            payload["templateId"] = template_id
            if params:
                payload["params"] = params
        else:
            payload["htmlContent"] = html_content
            if text_content:
                payload["textContent"] = text_content
        
        if tags:
            payload["tags"] = tags
        
        headers = {
            "accept": "application/json",
            "api-key": BREVO_API_KEY,
            "content-type": "application/json"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if response.status_code == 201:
            logger.info(f"Email sent successfully to {to_email}")
            return True
        else:
            logger.error(f"Brevo API error: {response.status_code} - {response.text}")
            return False
    
    except Exception as e:
        logger.error(f"Error sending email via Brevo API: {e}")
        return False

def send_email_smtp(
    to_email: str,
    subject: str,
    html_content: str,
    text_content: Optional[str] = None
) -> bool:
    """
    Send email via SMTP (fallback method)
    
    Args:
        to_email: Recipient email
        subject: Email subject
        html_content: HTML content
        text_content: Plain text content
        
    Returns:
        True if successful
    """
    if not BREVO_SMTP_USER or not BREVO_SMTP_PASSWORD:
        logger.error("SMTP credentials not configured")
        return False
    
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = f"{BREVO_SENDER_NAME} <{BREVO_SENDER_EMAIL}>"
        msg['To'] = to_email
        
        # Add both plain text and HTML versions
        if text_content:
            part1 = MIMEText(text_content, 'plain')
            msg.attach(part1)
        
        part2 = MIMEText(html_content, 'html')
        msg.attach(part2)
        
        # Connect to SMTP server
        server = smtplib.SMTP(BREVO_SMTP_HOST, BREVO_SMTP_PORT)
        server.starttls()
        server.login(BREVO_SMTP_USER, BREVO_SMTP_PASSWORD)
        
        # Send email
        server.send_message(msg)
        server.quit()
        
        logger.info(f"Email sent via SMTP to {to_email}")
        return True
    
    except Exception as e:
        logger.error(f"Error sending email via SMTP: {e}")
        return False

def send_welcome_email(user_email: str, user_name: Optional[str] = None) -> bool:
    """Send welcome email to new user"""
    from email.templates.welcome import get_welcome_email_html, get_welcome_email_text
    
    html_content = get_welcome_email_html(user_name)
    text_content = get_welcome_email_text(user_name)
    
    return send_transactional_email(
        to_email=user_email,
        to_name=user_name,
        subject="Bienvenue sur AR Code!",
        html_content=html_content,
        text_content=text_content,
        tags=["welcome", "onboarding"]
    )

def send_processing_complete_email(
    user_email: str,
    user_name: Optional[str],
    asset_type: str,
    asset_name: str,
    asset_url: str
) -> bool:
    """Send processing complete notification"""
    from email.templates.processing import get_processing_complete_html, get_processing_complete_text
    
    html_content = get_processing_complete_html(user_name, asset_type, asset_name, asset_url)
    text_content = get_processing_complete_text(user_name, asset_type, asset_name, asset_url)
    
    return send_transactional_email(
        to_email=user_email,
        to_name=user_name,
        subject=f"Votre {asset_type} est prêt!",
        html_content=html_content,
        text_content=text_content,
        tags=["processing", "notification"]
    )

def send_weekly_stats_email(
    user_email: str,
    user_name: Optional[str],
    stats: Dict[str, Any]
) -> bool:
    """Send weekly analytics digest"""
    from email.templates.weekly_stats import get_weekly_stats_html, get_weekly_stats_text
    
    html_content = get_weekly_stats_html(user_name, stats)
    text_content = get_weekly_stats_text(user_name, stats)
    
    return send_transactional_email(
        to_email=user_email,
        to_name=user_name,
        subject="Vos statistiques AR Code de la semaine",
        html_content=html_content,
        text_content=text_content,
        tags=["analytics", "weekly"]
    )

def send_error_alert_email(
    admin_email: str,
    error_type: str,
    error_message: str,
    context: Optional[Dict[str, Any]] = None
) -> bool:
    """Send error alert to admin"""
    from email.templates.error_alert import get_error_alert_html, get_error_alert_text
    
    html_content = get_error_alert_html(error_type, error_message, context)
    text_content = get_error_alert_text(error_type, error_message, context)
    
    return send_transactional_email(
        to_email=admin_email,
        to_name="Administrator",
        subject=f"[AR Code Alert] {error_type}",
        html_content=html_content,
        text_content=text_content,
        tags=["alert", "error"]
    )







