# Phase 19.4 - Webhooks System

Guide complet pour système de webhooks avec signature validation et retry logic.

## Vue d'ensemble

Le système de webhooks permet de notifier des événements externes:
- `ar_code.created`: Nouveau AR Code créé
- `ar_code.scanned`: AR Code scanné
- `processing.completed`: Job terminé avec succès
- `processing.failed`: Job échoué
- `analytics.updated`: Analytics mises à jour

## Étape 1: Enregistrer Webhook

### 1.1. API Endpoint

```python
POST /api/v1/webhooks
{
    "url": "https://example.com/webhook",
    "events": ["ar_code.created", "processing.completed"],
    "ar_code_id": "optional-specific-ar-code-id"
}
```

### 1.2. Génération Secret

Un secret unique est généré pour chaque webhook pour signature validation.

## Étape 2: Signature Validation

### 2.1. Signature Headers

Chaque webhook delivery inclut:
- `X-ARCode-Signature`: HMAC SHA256 signature
- `X-ARCode-Event`: Type d'événement

### 2.2. Validation Côté Client

```python
import hmac
import hashlib

def verify_signature(payload: str, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

## Étape 3: Retry Logic

### 3.1. Stratégie Retry

- Max retries: 3
- Intervalles: 2s, 4s, 8s (exponential backoff)
- Timeout: 10 secondes par tentative

### 3.2. Dead Letter

Webhooks qui échouent après 3 retries sont marqués comme failed dans `webhook_deliveries`.

## Étape 4: Delivery Tracking

### 4.1. Table webhook_deliveries

Chaque tentative de delivery est enregistrée:
- Status: pending, success, failed
- Status code HTTP
- Response body (premiers 1000 chars)
- Retry count

### 4.2. Query Deliveries

```sql
SELECT * FROM webhook_deliveries
WHERE webhook_id = 'xxx'
ORDER BY created_at DESC;
```

## Étape 5: Trigger Webhooks

### 5.1. Dans Code

```python
from queue.webhooks import trigger_webhook, WebhookEvent

# Quand job complété
trigger_webhook(
    WebhookEvent.PROCESSING_COMPLETED,
    {
        'job_id': job_id,
        'output_url': output_url,
        'job_type': 'photogrammetry'
    },
    user_id=user_id
)
```

### 5.2. Events Disponibles

- `ar_code.created`
- `ar_code.scanned`
- `processing.completed`
- `processing.failed`
- `analytics.updated`

## Checklist

- [ ] Webhooks table créée
- [ ] Signature generation implémentée
- [ ] Verification function créée
- [ ] Retry logic implémentée
- [ ] Delivery tracking activé
- [ ] Trigger functions créées
- [ ] API endpoints pour registration









