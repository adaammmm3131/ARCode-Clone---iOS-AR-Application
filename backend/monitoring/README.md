# Monitoring Setup Guide

## Quick Start

### 1. Install Prometheus and Exporters

```bash
chmod +x install_prometheus.sh install_exporters.sh
sudo ./install_prometheus.sh
sudo ./install_exporters.sh
```

### 2. Install Grafana

```bash
chmod +x install_grafana.sh
sudo ./install_grafana.sh
```

### 3. Configure Prometheus

Copy `prometheus.yml` to `/etc/prometheus/prometheus.yml`:
```bash
sudo cp prometheus.yml /etc/prometheus/
sudo systemctl restart prometheus
```

### 4. Setup Grafana

1. Access Grafana at `http://your-server:3000`
2. Login with `admin/admin` (change password)
3. Add Prometheus as data source:
   - URL: `http://localhost:9090`
   - Access: Server (default)
4. Import dashboards from `grafana_dashboards/`

### 5. Configure Sentry

**Backend:**
```python
from monitoring.sentry_config import init_sentry
init_sentry()
```

**iOS:**
```swift
import Sentry

SentryService.shared.initialize()
```

### 6. Configure Alerting

1. In Grafana: Alerting → Notification channels
2. Add email channel (Brevo SMTP)
3. Import alert rules from `alert_rules.yml`

## Access URLs

- Grafana: `https://ar-code.com/grafana/`
- Prometheus: `https://ar-code.com/prometheus/`
- API Metrics: `https://ar-code.com/metrics`

## Verification

```bash
# Check Prometheus
curl http://localhost:9090/api/v1/targets

# Check Node Exporter
curl http://localhost:9100/metrics

# Check PostgreSQL Exporter
curl http://localhost:9187/metrics

# Check Redis Exporter
curl http://localhost:9121/metrics

# Check Grafana
curl http://localhost:3000/api/health
```

## Troubleshooting

**Prometheus not collecting metrics:**
- Check exporter services: `sudo systemctl status node_exporter`
- Check Prometheus config: `sudo promtool check config /etc/prometheus/prometheus.yml`

**Grafana can't connect to Prometheus:**
- Verify Prometheus is running: `sudo systemctl status prometheus`
- Check firewall: `sudo ufw allow 9090`

**Sentry not capturing errors:**
- Verify DSN is correct
- Check network connectivity
- Enable debug mode temporarily







