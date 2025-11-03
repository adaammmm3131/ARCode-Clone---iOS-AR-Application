# Phase 18.2 - API Gateway Nginx Setup

Guide complet pour configurer Nginx en tant qu'API Gateway avec reverse proxy, SSL, rate limiting, CORS.

## Étape 1: Installation Nginx

### 1.1. Installer Nginx

```bash
sudo apt update
sudo apt install -y nginx

# Vérifier version
nginx -v
```

### 1.2. Configuration initiale

```bash
# Vérifier status
sudo systemctl status nginx

# Démarrer et activer au boot
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Étape 2: Configuration Nginx

### 2.1. Copier configuration

```bash
cd backend/config
sudo cp nginx.conf /etc/nginx/sites-available/ar-code-api
sudo ln -sf /etc/nginx/sites-available/ar-code-api /etc/nginx/sites-enabled/

# Supprimer default
sudo rm -f /etc/nginx/sites-enabled/default
```

### 2.2. Tester configuration

```bash
sudo nginx -t
```

### 2.3. Redémarrer Nginx

```bash
sudo systemctl restart nginx
```

## Étape 3: SSL via Cloudflare

### 3.1. Configuration Cloudflare

1. Dashboard Cloudflare → SSL/TLS
2. Encryption mode: **Full** (ou Full Strict si certificat valide)
3. Always Use HTTPS: ✅

### 3.2. Origin Certificate (Optionnel)

Pour Full Strict:
1. Dashboard → SSL/TLS → Origin Server
2. Create Certificate
3. Download certificate et key
4. Configurer dans Nginx (si nécessaire)

## Étape 4: Rate Limiting

### 4.1. Configuration zones

La configuration Nginx inclut:
- `api_limit`: 100 req/min
- `auth_limit`: 10 req/min

### 4.2. Ajuster limites

Éditer `/etc/nginx/sites-available/ar-code-api`:

```nginx
# Pour API générale
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;

# Pour authentification (stricter)
limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=10r/m;
```

## Étape 5: CORS Configuration

### 5.1. Headers CORS

Configuration dans `nginx.conf`:
- Access-Control-Allow-Origin: depuis `$http_origin`
- Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
- Access-Control-Allow-Headers: Authorization, Content-Type
- Access-Control-Max-Age: 86400

### 5.2. Preflight OPTIONS

Géré automatiquement par configuration Nginx.

## Étape 6: Logging

### 6.1. Logs access

```bash
# Voir logs en temps réel
sudo tail -f /var/log/nginx/api_access.log

# Format personnalisé avec timing
# Voir api_log dans nginx.conf
```

### 6.2. Logs errors

```bash
# Voir erreurs
sudo tail -f /var/log/nginx/api_error.log

# Logs niveau warn et supérieur
```

### 6.3. Rotation logs

Configuration automatique via `logrotate`:

```bash
sudo nano /etc/logrotate.d/nginx

# Configuration standard Ubuntu
```

## Étape 7: Monitoring

### 7.1. Status Nginx

```bash
# Status
sudo systemctl status nginx

# Vérifier processus
ps aux | grep nginx

# Tester endpoint
curl http://localhost/health
```

### 7.2. Métriques

```bash
# Active connections
sudo netstat -an | grep :80 | wc -l

# Requests per second (via logs)
sudo tail -f /var/log/nginx/api_access.log | pv -l > /dev/null
```

## Étape 8: Security Headers

Configuration dans `nginx.conf`:
- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- X-XSS-Protection: 1; mode=block
- Referrer-Policy: strict-origin-when-cross-origin

## Checklist

- [ ] Nginx installé
- [ ] Configuration copiée
- [ ] SSL Cloudflare configuré
- [ ] Rate limiting activé
- [ ] CORS configuré
- [ ] Logging activé
- [ ] Security headers ajoutés
- [ ] Health check endpoint testé
- [ ] Monitoring basique activé

## Prochaines étapes

Voir `PHASE_18_SUPABASE_AUTH.md` pour intégration authentification.









