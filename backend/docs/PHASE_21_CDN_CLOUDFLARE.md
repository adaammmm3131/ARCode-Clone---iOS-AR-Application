# Phase 21.1 - CDN Cloudflare Setup

Guide complet pour configurer Cloudflare Free plan avec DNS, SSL, cache rules.

## Étape 1: Créer Compte Cloudflare

1. Aller sur [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Créer compte (free tier disponible)
3. Ajouter domaine `ar-code.com`

## Étape 2: Configuration DNS

### 2.1. Enregistrements DNS Essentiels

Dans Cloudflare Dashboard → DNS → Records:

**A Records:**
```
Type: A
Name: @
IPv4: <IP_PUBLIQUE_ORACLE_VM>
Proxy: Proxied (orange cloud)
TTL: Auto
```

```
Type: A
Name: api
IPv4: <IP_PUBLIQUE_ORACLE_VM>
Proxy: Proxied
TTL: Auto
```

**CNAME Records:**
```
Type: CNAME
Name: www
Target: @
Proxy: Proxied
TTL: Auto
```

```
Type: CNAME
Name: assets
Target: <r2-custom-domain> (si configuré)
Proxy: Proxied
TTL: Auto
```

### 2.2. Mettre à jour Nameservers

1. Cloudflare Dashboard → Overview
2. Noter les nameservers fournis (ex: `brad.ns.cloudflare.com`)
3. Mettre à jour chez le registrar de domaine
4. Attendre propagation DNS (jusqu'à 24h)

## Étape 3: SSL/TLS Configuration

### 3.1. SSL Mode

Cloudflare Dashboard → SSL/TLS:

**Encryption mode:** Full (ou Full Strict si certificat valide)
- Full: SSL entre client ↔ Cloudflare et Cloudflare ↔ Origin
- Full Strict: SSL + certificat valide requis

**Always Use HTTPS:** ✅ Activé
**Automatic HTTPS Rewrites:** ✅ Activé

### 3.2. Origin Certificate (Optionnel pour Full Strict)

1. SSL/TLS → Origin Server → Create Certificate
2. Download certificate (.pem) et private key
3. Configurer sur serveur Nginx (si nécessaire)

## Étape 4: Cache Rules

### 4.1. Cache Level

Cloudflare Dashboard → Caching → Configuration:

**Cache Level:** Standard

### 4.2. Browser Cache TTL

**Browser Cache TTL:** Respect Existing Headers (ou 1 month pour assets statiques)

### 4.3. Cache Rules (Transform Rules)

Dashboard → Rules → Cache Rules → Create rule:

**Rule 1: Static Assets (1 month cache)**
```
URL matches: *.ar-code.com/assets/* OR *.ar-code.com/models/* OR *.ar-code.com/videos/* OR *.ar-code.com/images/*
Cache Status: Cache Everything
Edge Cache TTL: 1 month
Browser Cache TTL: 1 month
```

**Rule 2: API (No Cache)**
```
URL matches: *.ar-code.com/api/*
Cache Status: Bypass
```

**Rule 3: HTML Pages (Short Cache)**
```
URL matches: *.ar-code.com/*.html OR *.ar-code.com/
Cache Status: Standard
Edge Cache TTL: 4 hours
Browser Cache TTL: 1 hour
```

## Étape 5: Page Rules (Free: 3 rules max)

### 5.1. Rule 1: Static Assets

**URL Pattern:** `*ar-code.com/assets/*`
**Settings:**
- Cache Level: Cache Everything
- Edge Cache TTL: 1 month
- Browser Cache TTL: 1 month

### 5.2. Rule 2: API Bypass

**URL Pattern:** `*ar-code.com/api/*`
**Settings:**
- Cache Level: Bypass

### 5.3. Rule 3: WebAR Pages

**URL Pattern:** `*ar-code.com/a/*`
**Settings:**
- Cache Level: Standard
- Edge Cache TTL: 1 hour
- Browser Cache TTL: 30 minutes

## Étape 6: Auto Minify

Dashboard → Speed → Optimization:

**Auto Minify:**
- ✅ JavaScript
- ✅ CSS
- ✅ HTML

## Étape 7: Compression

**Brotli:** ✅ Enabled (automatic pour tous browsers supportant)
**Gzip:** ✅ Enabled (fallback pour anciens browsers)

## Étape 8: HTTP/2 et HTTP/3

**HTTP/2:** ✅ Enabled (automatic)
**HTTP/3 (QUIC):** ✅ Enabled (si disponible dans Free plan)

## Étape 9: Always Online

**Always Online:** ✅ Enabled
- Permet de servir pages en cache même si origin offline

## Étape 10: Development Mode (Optionnel)

Pour désactiver cache pendant développement:
- Dashboard → Caching → Configuration → Purge Cache
- Ou Development Mode (3h max, réactivation auto)

## Étape 11: Cache Purge

### 11.1. Purge All

Dashboard → Caching → Configuration → Purge Everything

### 11.2. Purge by URL

Dashboard → Caching → Configuration → Custom Purge:
- Entrer URLs spécifiques à purger

### 11.3. API Purge

```python
import requests

def purge_cache(urls: list):
    response = requests.post(
        'https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache',
        headers={
            'Authorization': 'Bearer {api_token}',
            'Content-Type': 'application/json'
        },
        json={'files': urls}
    )
    return response.json()
```

## Checklist

- [ ] Compte Cloudflare créé
- [ ] Domaine ajouté
- [ ] DNS records configurés
- [ ] Nameservers mis à jour
- [ ] SSL/TLS configuré (Full)
- [ ] Always Use HTTPS activé
- [ ] Cache Rules créées (assets 1 month)
- [ ] Page Rules configurées (3 max free)
- [ ] Auto Minify activé
- [ ] Compression (Brotli/Gzip) activée
- [ ] HTTP/3 activé (si disponible)
- [ ] Always Online activé
- [ ] Cache purge testé

## Prochaines étapes

Voir `PHASE_21_CDN_OPTIMIZATION.md` pour optimisation avancée.







