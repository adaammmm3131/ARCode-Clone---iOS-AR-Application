# Phase 20 - Analytics Tracking - Guide Complet

## Vue d'ensemble

Phase 20 implémente un système complet d'analytics avec:
- Umami (self-hosted, privacy-focused)
- Event tracking (QR scan, placement, interactions, screenshot, conversion)
- Location tracking (geographic heatmap)
- Device/browser breakdown
- Retargeting pixels (Facebook, Google Ads, LinkedIn, Twitter)
- Batch processing et retention policy

## Phase 20.1 - Analytics Tracking

### Événements Trackés

1. **qr_scan**: Scan de QR Code
   - Metadata: code_id, scan_location, scan_method

2. **placement**: Placement d'objet AR
   - Metadata: code_id, position (x, y, z), plane_type

3. **interaction**: Interactions avec objets AR
   - Metadata: code_id, interaction_type (tap, rotate, scale, etc.)

4. **screenshot**: Capture d'écran AR
   - Metadata: code_id, timestamp

5. **conversion**: Conversion (CTA cliqué, etc.)
   - Metadata: code_id, value, conversion_type

### Metadata Collectée

- Location: latitude, longitude, city, country
- Device: OS, OS version, model, browser
- Session: session_id, user_id
- IP address: pour géolocalisation (hashé si GDPR)

## Phase 20.2 - Analytics Storage

### Schema Database

Table `analytics_events`:
- Event type, data (JSONB)
- Location (lat/long, city, country)
- Device info
- Timestamps

Table `analytics_daily_stats`:
- Aggregations quotidiennes
- Counts, unique users, sessions

### Batch Processing

Script `batch_processor.py`:
- Agrège événements quotidiennement
- Crée stats quotidiennes pour performance
- Nettoie événements anciens (retention policy)

### Retention Policy

- Default: 365 jours
- Configurable via `ANALYTICS_RETENTION_DAYS`
- Anciens événements supprimés automatiquement

## Phase 20.3 - Analytics Visualization

### iOS Dashboard

Utilise Charts framework (iOS 16+):
- Time-series graphs pour scans
- Device breakdown charts
- Browser stats

### MapKit Heatmap

Geographic visualization:
- Clustering locations
- Heatmap intensity par nombre scans
- Annotation pour villes

### Export

- CSV export pour events
- JSON export pour stats
- Date range filtering

## Phase 20.4 - Retargeting Pixels

### Facebook Pixel

- Server-Side API (Conversions API)
- Event tracking (PageView, Purchase, etc.)
- User data hashing pour privacy

### Google Ads Pixel

- Measurement Protocol
- Conversion tracking
- Transaction value tracking

### LinkedIn Insight Tag

- Conversion tracking API
- Event-based tracking

### Twitter Pixel

- Conversions API
- Event tracking

## Configuration

### Umami Setup

1. Installer Umami (self-hosted):
```bash
docker run -d \
  --name umami \
  -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:pass@localhost/umami \
  ghcr.io/umami-software/umami:postgresql-latest
```

2. Créer website dans Umami
3. Récupérer Website ID
4. Configurer dans app (Info.plist)

### Pixel IDs Configuration

Variables d'environnement backend:
- `FACEBOOK_PIXEL_ID`
- `FACEBOOK_ACCESS_TOKEN`
- `GOOGLE_ADS_CONVERSION_ID`
- `GOOGLE_ADS_CONVERSION_LABEL`
- `LINKEDIN_PARTNER_ID`
- `TWITTER_PIXEL_ID`

## API Endpoints

### Track Event

```
POST /api/v1/analytics/track
{
  "event_type": "qr_scan",
  "ar_code_id": "xxx",
  "event_data": {...},
  "device_type": "ios",
  "location": {...}
}
```

### Get Events

```
GET /api/v1/analytics/events?ar_code_id=xxx&start_date=...&end_date=...
```

### Get Stats

```
GET /api/v1/analytics/stats?ar_code_id=xxx
```

## Checklist

- [x] Umami integration (backend + iOS)
- [x] Event tracking complet
- [x] Location tracking
- [x] Device info collection
- [x] Analytics API endpoints
- [x] Database schema optimisé
- [x] Batch processing aggregations
- [x] Retention policy
- [x] Retargeting pixels
- [x] iOS Analytics Service
- [x] Dashboard visualization








