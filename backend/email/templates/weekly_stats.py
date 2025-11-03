#!/usr/bin/env python3
"""
Weekly Stats Email Template
"""

from typing import Optional, Dict, Any

def get_weekly_stats_html(user_name: Optional[str], stats: Dict[str, Any]) -> str:
    """Generate weekly stats email HTML"""
    name = user_name or "Cher utilisateur"
    
    total_scans = stats.get('total_scans', 0)
    total_views = stats.get('total_views', 0)
    active_codes = stats.get('active_codes', 0)
    top_code = stats.get('top_code', 'N/A')
    
    return f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vos statistiques de la semaine</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden;">
                    <!-- Header -->
                    <tr>
                        <td style="background: linear-gradient(135deg, #6C5CE7 0%, #00B894 100%); padding: 40px 20px; text-align: center;">
                            <h1 style="color: #ffffff; margin: 0; font-size: 32px;">📊 Vos statistiques de la semaine</h1>
                        </td>
                    </tr>
                    
                    <!-- Content -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Bonjour {name},
                            </p>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px 0;">
                                Voici un résumé de l'activité de vos AR Codes cette semaine :
                            </p>
                            
                            <!-- Stats Cards -->
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 0 0 30px 0;">
                                <tr>
                                    <td width="33%" style="padding: 15px; background-color: #f8f8f8; border-radius: 5px; text-align: center;">
                                        <div style="font-size: 32px; font-weight: bold; color: #6C5CE7; margin: 0 0 5px 0;">{total_scans}</div>
                                        <div style="font-size: 14px; color: #666666;">Scans</div>
                                    </td>
                                    <td width="33%" style="padding: 15px; background-color: #f8f8f8; border-radius: 5px; text-align: center;">
                                        <div style="font-size: 32px; font-weight: bold; color: #00B894; margin: 0 0 5px 0;">{total_views}</div>
                                        <div style="font-size: 14px; color: #666666;">Vues</div>
                                    </td>
                                    <td width="33%" style="padding: 15px; background-color: #f8f8f8; border-radius: 5px; text-align: center;">
                                        <div style="font-size: 32px; font-weight: bold; color: #FD79A8; margin: 0 0 5px 0;">{active_codes}</div>
                                        <div style="font-size: 14px; color: #666666;">Codes actifs</div>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
                                <strong>Code le plus populaire :</strong> {top_code}
                            </p>
                            
                            <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
                                <tr>
                                    <td align="center">
                                        <a href="https://ar-code.com/analytics" style="display: inline-block; padding: 15px 30px; background-color: #6C5CE7; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">
                                            Voir toutes les statistiques
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
                                <a href="https://ar-code.com/unsubscribe" style="color: #999999;">Se désabonner</a> | 
                                <a href="https://ar-code.com/email-preferences" style="color: #999999;">Gérer les préférences</a>
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

def get_weekly_stats_text(user_name: Optional[str], stats: Dict[str, Any]) -> str:
    """Generate weekly stats email plain text"""
    name = user_name or "Cher utilisateur"
    
    total_scans = stats.get('total_scans', 0)
    total_views = stats.get('total_views', 0)
    active_codes = stats.get('active_codes', 0)
    top_code = stats.get('top_code', 'N/A')
    
    return f"""
Vos statistiques de la semaine

Bonjour {name},

Voici un résumé de l'activité de vos AR Codes cette semaine :

📊 Statistiques:
- Scans: {total_scans}
- Vues: {total_views}
- Codes actifs: {active_codes}

Code le plus populaire: {top_code}

Voir toutes les statistiques: https://ar-code.com/analytics

© 2024 AR Code. Tous droits réservés.
"""







