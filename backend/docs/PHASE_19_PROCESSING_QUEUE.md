# Phase 19.1 - Processing Queue Setup

Guide complet pour configurer le système de queue de traitement avec RQ (Redis Queue).

## Étape 1: Installation RQ

### 1.1. Installer RQ

```bash
cd backend/queue
pip install -r requirements.txt
```

### 1.2. Vérifier Redis

```bash
redis-cli ping
# Should return: PONG
```

## Étape 2: Configuration Queues

### 2.1. Queues par Priorité

Le système utilise 3 queues:
- **high**: Jobs haute priorité (AI vision rapide)
- **default**: Jobs normaux (photogrammetry, AI generation)
- **low**: Jobs longs (Gaussian Splatting)

### 2.2. Dead Letter Queue

Jobs qui échouent après tous les retries sont envoyés dans `dead_letter` queue.

## Étape 3: Démarrer Workers

### 3.1. Worker High Priority

```bash
python -m queue.worker_manager high --name worker-high-1
```

### 3.2. Worker Default

```bash
python -m queue.worker_manager default --name worker-default-1
```

### 3.3. Worker Low Priority

```bash
python -m queue.worker_manager low --name worker-low-1
```

### 3.4. Multiple Workers

Pour scaler, démarrer plusieurs workers:

```bash
# Terminal 1
python -m queue.worker_manager default --name worker-default-1

# Terminal 2
python -m queue.worker_manager default --name worker-default-2
```

## Étape 4: Monitoring Workers

### 4.1. RQ Dashboard (Optionnel)

```bash
pip install rq-dashboard
rq-dashboard
# Accessible sur http://localhost:9181
```

### 4.2. Via Redis CLI

```bash
# Voir jobs dans queue
redis-cli LRANGE rq:queue:default 0 -1

# Voir workers actifs
redis-cli KEYS rq:worker:*
```

## Étape 5: Retry Logic

### 5.1. Configuration Retry

Chaque type de job a sa stratégie de retry:

- **Photogrammetry**: 3 retries, intervalles 60s, 120s, 300s
- **Gaussian Splatting**: 2 retries, intervalles 300s, 600s
- **AI Vision**: 2 retries, intervalles 10s, 30s
- **AI Generation**: 2 retries, intervalles 30s, 60s

### 5.2. Exponential Backoff

Les retries utilisent exponential backoff pour éviter surcharge.

## Étape 6: Job Status Tracking

### 6.1. Status dans PostgreSQL

Chaque job est tracké dans table `processing_jobs`:
- Status: pending, queued, processing, completed, failed
- Progress: 0-100
- Metadata: JSONB avec détails

### 6.2. API Status

```bash
GET /api/v1/jobs/<job_id>
```

Retourne status, progress, output_url, error_message.

## Checklist

- [ ] RQ installé
- [ ] Redis fonctionnel
- [ ] Queues configurées (high, default, low)
- [ ] Workers démarrés
- [ ] Job tracking dans PostgreSQL
- [ ] Retry logic configuré
- [ ] Monitoring activé

## Prochaines étapes

Voir Phase 19.2 pour setup workers spécifiques (COLMAP, Gaussian, AI, Blender).









