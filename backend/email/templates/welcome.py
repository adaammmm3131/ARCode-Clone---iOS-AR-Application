#!/usr/bin/env python3
"""
Welcome Email Template
"""

from typing import Optional

def get_welcome_email_html(user_name: Optional[str] = None) -> str:
    """Generate welcome email HTML"""
    name = user_name or "Cher utilisateur"
    
    return f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur AR Code</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden;">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #6C5CE7 0%, #00B894 100%); padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px;">Bienvenue sur AR Code!</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                Bonjour {name},
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                Nous sommes ravis de vous accueillir sur AR Code, la plateforme qui vous permet de créer des expériences de réalité augmentée époustouflantes.
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                <strong>Pour commencer :</strong>
                            </p>
                            
                            <ul style="color: #333333; font-size: 16px; line-height: 1.8; margin: 0 0 30px 0; padding-left: 20px;">
                                <li>Créez votre premier AR Code</li>
                                <li>Explorez nos fonctionnalités (3D Upload, Object Capture, AR Face, AI Code)</li>
                                <li>Partagez vos créations avec le monde</li>
                            </ul>
                            
                            <table width="100%" cellpadding="0" cellspacing="0">
                                <tr>
                                    <td align="center">
                                        <a href="https://ar-code.com/dashboard" style="display: inline-block; padding: 15px 30px; background-color: #6C5CE7; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">
                                            Accéder au Dashboard
                                        </a>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f8f8; padding: 20px; text-align: center; border-top: 1px solid #e0e0e0;">
                            <p style="color: #666666; font-size: 14px; margin: 0 0 10px 0;">
                                © 2024 AR Code. Tous droits réservés.
                            </p>
                            <p style="color: #999999; font-size: 12px; margin: 0;">
                                <a href="https://ar-code.com/unsubscribe" style="color: #999999;">Se désabonner</a>
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

def get_welcome_email_text(user_name: Optional[str] = None) -> str:
    """Generate welcome email plain text"""
    name = user_name or "Cher utilisateur"
    
    return f"""
Bienvenue sur AR Code!

Bonjour {name},

Nous sommes ravis de vous accueillir sur AR Code, la plateforme qui vous permet de créer des expériences de réalité augmentée époustouflantes.

Pour commencer :
- Créez votre premier AR Code
- Explorez nos fonctionnalités (3D Upload, Object Capture, AR Face, AI Code)
- Partagez vos créations avec le monde

Accéder au dashboard : https://ar-code.com/dashboard

© 2024 AR Code. Tous droits réservés.
"""

