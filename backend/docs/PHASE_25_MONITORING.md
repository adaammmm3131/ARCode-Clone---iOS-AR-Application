# Phase 25 - Monitoring - Guide Complet

## Vue d'ensemble

Phase 25 met en place un système de monitoring complet avec Grafana, Prometheus et Sentry pour surveiller les performances, la disponibilité et les erreurs.

## Phase 25.1 - Monitoring Grafana

### Installation

**Script:** `backend/monitoring/install_grafana.sh`

1. Ajouter repository Grafana
2. Installer Grafana
3. Configurer service systemd
4. Accès via reverse proxy Nginx

**Accès:**
- Direct: `http://server-ip:3000`
- Via Nginx: `https://ar-code.com/grafana/`
- Credentials: `admin/admin` (changer au premier login)

### Dashboards

**Dashboard System:**
- CPU Usage
- Memory Usage
- Disk Usage
- Network Traffic

### Alerting

**Notification Channels:**
- Email (Brevo)
- Slack (optionnel)
- Webhooks (optionnel)

**Alert Rules:**
- High CPU (>80%)
- High Memory (>85%)
- Low Disk Space (<15%)
- Service down

## Phase 25.2 - Monitoring Prometheus

### Installation

**Script:** `backend/monitoring/install_prometheus.sh`

1. Télécharger Prometheus
2. Créer user prometheus
3. Configurer service systemd
4. Fichier config: `prometheus.yml`

**Accès:**
- Direct: `http://server-ip:9090`
- Via Nginx: `https://ar-code.com/prometheus/`

### Exporters

**Installation:** `backend/monitoring/install_exporters.sh`

**Exporters installés:**
1. **Node Exporter** (port 9100)
   - CPU, Memory, Disk, Network
   
2. **PostgreSQL Exporter** (port 9187)
   - Connections, queries, cache
   
3. **Redis Exporter** (port 9121)
   - Memory, commands, keys
   
4. **Nginx Exporter** (port 9113)
   - Requests, errors, active connections

### Metrics Custom

**Fichier:** `backend/monitoring/api_metrics.py`

**Métriques:**
- `http_requests_total` - Total requests
- `http_request_duration_seconds` - Response time
- `processing_jobs_total` - Job counts
- `processing_job_duration_seconds` - Job duration
- `active_connections` - Active connections

**Endpoint:** `/metrics`

## Phase 25.3 - Monitoring Sentry

### Configuration Backend

**Fichier:** `backend/monitoring/sentry_config.py`

- Integration Flask
- Integration SQLAlchemy
- Integration Redis
- Filtering sensitive data
- Performance monitoring (10% sample)

### Configuration iOS

**Fichier:** `Sources/Services/SentryService.swift`

**Fonctionnalités:**
- Error tracking
- Performance monitoring
- User context
- Breadcrumbs
- Release tracking

### Installation iOS SDK

**Via SPM:**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.0.0")
]
```

## Configuration

### Environment Variables

```bash
# Sentry
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
SENTRY_ENV=production
SENTRY_RELEASE=ar-code@1.0.0

# Prometheus (no env vars needed, uses prometheus.yml)

# Grafana (no env vars needed)
```

### Nginx Configuration

Ajout routes:
- `/metrics` → Flask metrics endpoint
- `/grafana/` → Grafana (port 3000)
- `/prometheus/` → Prometheus (port 9090, avec auth)

## Alerting Rules

### System Alerts
- High CPU usage (>80% for 5m)
- High memory (>85% for 5m)
- Low disk space (<15% for 5m)

### Database Alerts
- PostgreSQL down (1m)
- Too many connections (>80 for 5m)

### Redis Alerts
- Redis down (1m)
- High memory usage (>90% for 5m)

### Application Alerts
- High error rate (>0.1 req/s for 5m)
- Slow response (>2s p95 for 5m)
- Job queue backlog (>100 for 10m)

## Checklist Phase 25

- [x] Grafana installation
- [x] System dashboards
- [x] Alerting rules
- [x] Prometheus installation
- [x] Node exporter
- [x] PostgreSQL exporter
- [x] Redis exporter
- [x] Nginx exporter
- [x] Custom API metrics
- [x] Sentry backend config
- [x] Sentry iOS SDK
- [x] Error tracking
- [x] Performance monitoring

## Prochaines étapes

Voir Phase 26 - CI/CD pour:
- GitHub Actions workflows
- Automated deployment
- Testing automation







