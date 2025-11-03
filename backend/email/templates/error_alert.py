#!/usr/bin/env python3
"""
Error Alert Email Template
"""

from typing import Optional, Dict, Any
import json

def get_error_alert_html(
    error_type: str,
    error_message: str,
    context: Optional[Dict[str, Any]] = None
) -> str:
    """Generate error alert email HTML"""
    context_str = json.dumps(context, indent=2) if context else "N/A"
    
    return f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alert: {error_type}</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; border-left: 4px solid #DC3545;">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #DC3545; padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px;">⚠️ Erreur détectée</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                <strong>Type d'erreur:</strong> {error_type}
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                <strong>Message:</strong><br>
                                <code style="background-color: #f8f8f8; padding: 10px; border-radius: 5px; display: block; font-size: 14px; color: #DC3545;">
                                    {error_message}
                                </code>
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                <strong>Contexte:</strong>
                            </p>
                            
                            <pre style="background-color: #f8f8f8; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 12px; color: #333333;">
{context_str}
                            </pre>
                            
                            <p style="color: #666666; font-size: 14px; line-height: 1.6; margin: 30px 0 0 0;">
                                Action requise: Vérifier les logs serveur et résoudre le problème.
                            </p>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f8f8; padding: 20px; text-align: center; border-top: 1px solid #e0e0e0;">
                            <p style="color: #666666; font-size: 14px; margin: 0;">
                                AR Code Monitoring System
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
"""

def get_error_alert_text(
    error_type: str,
    error_message: str,
    context: Optional[Dict[str, Any]] = None
) -> str:
    """Generate error alert email plain text"""
    context_str = json.dumps(context, indent=2) if context else "N/A"
    
    return f"""
Erreur détectée

Type d'erreur: {error_type}

Message:
{error_message}

Contexte:
{context_str}

Action requise: Vérifier les logs serveur et résoudre le problème.

AR Code Monitoring System
"""







