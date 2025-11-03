#!/usr/bin/env python3
"""
Processing Complete Email Template
"""

from typing import Optional

def get_processing_complete_html(
    user_name: Optional[str],
    asset_type: str,
    asset_name: str,
    asset_url: str
) -> str:
    """Generate processing complete email HTML"""
    name = user_name or "Cher utilisateur"
    
    return f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Votre {asset_type} est prêt!</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden;">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #00B894 0%, #6C5CE7 100%); padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px;">✓ Traitement terminé!</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                Bonjour {name},
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                Excellent! Le traitement de votre <strong>{asset_type}</strong> "<strong>{asset_name}</strong>" est maintenant terminé.
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Votre contenu AR est prêt à être utilisé. Vous pouvez maintenant créer votre AR Code et le partager!
                            </p>
                            
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 30px 0;">
                                <tr>
                                    <td align="center">
                                        <a href="{asset_url}" style="display: inline-block; padding: 15px 30px; background-color: #00B894; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">
                                            Voir mon {asset_type}
                                        </a>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="color: #666666; font-size: 14px; line-height: 1.6; margin: 0;">
                                Besoin d'aide? <a href="https://ar-code.com/support" style="color: #6C5CE7;">Contactez notre support</a>
                            </p>
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

def get_processing_complete_text(
    user_name: Optional[str],
    asset_type: str,
    asset_name: str,
    asset_url: str
) -> str:
    """Generate processing complete email plain text"""
    name = user_name or "Cher utilisateur"
    
    return f"""
Traitement terminé!

Bonjour {name},

Excellent! Le traitement de votre {asset_type} "{asset_name}" est maintenant terminé.

Votre contenu AR est prêt à être utilisé. Vous pouvez maintenant créer votre AR Code et le partager!

Voir mon {asset_type}: {asset_url}

Besoin d'aide? https://ar-code.com/support

© 2024 AR Code. Tous droits réservés.
"""







