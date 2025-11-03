# Phase 24 - Email Brevo - Guide Complet

## Vue d'ensemble

Phase 24 intègre Brevo (anciennement Sendinblue) pour l'envoi d'emails transactionnels et de notifications.

## Phase 24.1 - Brevo Configuration

### Création du compte Brevo

1. S'inscrire sur [Brevo](https://www.brevo.com/)
2. Plan Free: 300 emails/jour
3. Vérifier l'email

### Génération de la clé API

1. **Accéder aux paramètres:**
   - Connexion Brevo
   - Paramètres → SMTP & API
   - Onglet "Clés API & MCP"

2. **Créer une clé API:**
   - Cliquer "Générer une nouvelle clé API"
   - Nommer la clé (ex: "AR Code Integration")
   - Copier et sauvegarder la clé

### Configuration SMTP

**SMTP Settings:**
- Host: `smtp-relay.brevo.com`
- Port: `587` (TLS) ou `465` (SSL)
- Username: Votre clé API
- Password: Votre clé API

## Phase 24.2 - Email Templates

### Templates créés

1. **Welcome Email**
   - Fichier: `backend/email/templates/welcome.py`
   - Usage: Nouveaux utilisateurs
   - Design responsive HTML

2. **Processing Complete Email**
   - Fichier: `backend/email/templates/processing.py`
   - Usage: Notification fin de traitement
   - Inclut lien vers asset

3. **Weekly Stats Email**
   - Fichier: `backend/email/templates/weekly_stats.py`
   - Usage: Digest hebdomadaire analytics
   - Statistiques visuelles

4. **Error Alert Email**
   - Fichier: `backend/email/templates/error_alert.py`
   - Usage: Alertes erreurs admin
   - Contexte détaillé

## Phase 24.3 - Notification Service

### Préférences utilisateur

**Champs database:**
- `email_notifications_processing` (default: TRUE)
- `email_notifications_scans` (default: FALSE)
- `email_notifications_weekly_stats` (default: TRUE)
- `email_notifications_marketing` (default: FALSE)

### Types de notifications

1. **Processing Complete**
   - Déclencheur: Job terminé
   - Contenu: Type asset, nom, URL
   - Préférence: `email_notifications_processing`

2. **AR Code Scanned**
   - Déclencheur: QR Code scanné
   - Contenu: Nom AR Code, timestamp
   - Préférence: `email_notifications_scans`

3. **Weekly Stats**
   - Déclencheur: Tâche cron hebdomadaire
   - Contenu: Scans, vues, codes actifs, top code
   - Préférence: `email_notifications_weekly_stats`

4. **Error Alerts**
   - Déclencheur: Erreur système
   - Destinataire: Admin
   - Contenu: Type erreur, message, contexte

## Configuration

### Environment Variables

```bash
# Brevo API
BREVO_API_KEY=your-api-key-here
BREVO_SMTP_HOST=smtp-relay.brevo.com
BREVO_SMTP_PORT=587
BREVO_SENDER_EMAIL=[email protected]
BREVO_SENDER_NAME=AR Code
```

### Database Migration

Ajouter colonnes notification preferences:
```sql
ALTER TABLE users ADD COLUMN email_notifications_processing BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN email_notifications_scans BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN email_notifications_weekly_stats BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN email_notifications_marketing BOOLEAN DEFAULT FALSE;
```

## Usage

### Envoyer email de bienvenue

```python
from email.brevo_service import send_welcome_email

send_welcome_email("[email protected]", "John Doe")
```

### Notification traitement terminé

```python
from email.notification_service import send_processing_notification

send_processing_notification(
    user_id="user-123",
    asset_type="3D Model",
    asset_name="Mon modèle",
    asset_url="https://ar-code.com/assets/model-123"
)
```

### Stats hebdomadaires batch

```python
from email.notification_service import send_weekly_stats_to_users

# Cron job: Tous les lundis
sent_count = send_weekly_stats_to_users()
```

### Erreur admin

```python
from email.brevo_service import send_error_alert_email

send_error_alert_email(
    admin_email="[email protected]",
    error_type="Processing Error",
    error_message="Failed to process mesh",
    context={"job_id": "job-123", "user_id": "user-456"}
)
```

## Checklist Phase 24

- [x] Brevo account setup
- [x] API key generation
- [x] SMTP configuration
- [x] Welcome email template
- [x] Processing complete template
- [x] Weekly stats template
- [x] Error alert template
- [x] Notification service
- [x] User preferences
- [x] Database schema update

## Prochaines étapes

Voir Phase 25 - Monitoring pour Grafana, Prometheus et Sentry.







