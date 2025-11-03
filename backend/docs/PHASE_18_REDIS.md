# Phase 18.5 - Redis Setup

Guide pour installer Redis et configurer cache, sessions, rate limiting.

## Étape 1: Installation Redis

### Option A: Redis Local (Oracle VM)

```bash
# Ubuntu 22.04
sudo apt update
sudo apt install -y redis-server

# Configuration
sudo nano /etc/redis/redis.conf

# Modifications:
# - maxmemory 2gb (sur 24GB RAM)
# - maxmemory-policy allkeys-lru
# - bind 127.0.0.1 (seulement local)
# - protected-mode yes
# - requirepass <strong_password>

# Redémarrer
sudo systemctl restart redis-server
sudo systemctl enable redis-server

# Test
redis-cli ping
```

### Option B: Redis Cloud Free (Alternative)

1. Créer compte [Redis Cloud](https://redis.com/try-free/)
2. Créer database:
   - Plan: Free
   - Memory: 30MB
   - Replication: Disabled (pour free tier)
3. Récupérer endpoint et password

## Étape 2: Configuration Redis

### 2.1. Configuration locale

```bash
# Éditer config
sudo nano /etc/redis/redis.conf

# Paramètres recommandés:
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
tcp-keepalive 300
```

### 2.2. Sécurité

```bash
# Changer bind pour localhost uniquement
bind 127.0.0.1

# Activer protected mode
protected-mode yes

# Définir mot de passe
requirepass your_strong_password_here
```

### 2.3. Redémarrer

```bash
sudo systemctl restart redis-server
sudo systemctl status redis-server
```

## Étape 3: Test Connexion

### 3.1. CLI

```bash
# Connexion avec password
redis-cli -a your_strong_password_here

# Test
127.0.0.1:6379> PING
PONG

# Info
127.0.0.1:6379> INFO memory
```

### 3.2. Python test

```python
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='your_strong_password_here',
    decode_responses=True
)

r.set('test', 'value')
print(r.get('test'))
```

## Étape 4: Utilisation dans Flask

### 4.1. Installer dépendances

```bash
pip install redis flask-redis
```

### 4.2. Configuration

Créer `backend/api/redis_config.py`:

```python
import redis
import os

redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'localhost'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    password=os.getenv('REDIS_PASSWORD'),
    decode_responses=True,
    socket_connect_timeout=5,
    socket_keepalive=True
)

def test_redis():
    try:
        redis_client.ping()
        return True
    except Exception as e:
        print(f"Redis connection error: {e}")
        return False
```

### 4.3. Cache Layer

```python
from redis_config import redis_client
import json

def cache_get(key):
    """Récupérer depuis cache"""
    value = redis_client.get(key)
    if value:
        return json.loads(value)
    return None

def cache_set(key, value, ttl=3600):
    """Sauvegarder dans cache"""
    redis_client.setex(
        key,
        ttl,
        json.dumps(value)
    )
```

### 4.4. Rate Limiting

```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import redis

# Utiliser Redis pour rate limiting
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    storage_uri="redis://localhost:6379/0",
    default_limits=["100 per minute"]
)
```

### 4.5. Session Storage

```python
from flask_session import Session
import redis

app.config['SESSION_TYPE'] = 'redis'
app.config['SESSION_REDIS'] = redis_client
Session(app)
```

## Étape 5: Monitoring

### 5.1. Redis CLI monitoring

```bash
# Monitor commands en temps réel
redis-cli -a password MONITOR

# Stats
redis-cli -a password INFO stats

# Memory info
redis-cli -a password INFO memory

# Slow log
redis-cli -a password SLOWLOG GET 10
```

### 5.2. Python monitoring

```python
info = redis_client.info()
print(f"Used memory: {info['used_memory_human']}")
print(f"Connected clients: {info['connected_clients']}")
print(f"Total commands: {info['total_commands_processed']}")
```

## Checklist

- [ ] Redis installé (local ou cloud)
- [ ] Configuration optimisée (maxmemory, policies)
- [ ] Password défini
- [ ] Protected mode activé
- [ ] Test connexion réussi
- [ ] Flask-Redis configuré
- [ ] Cache layer implémenté
- [ ] Rate limiting avec Redis
- [ ] Session storage configuré
- [ ] Monitoring activé

## Prochaines étapes

Voir `PHASE_18_STORAGE.md` pour configuration Cloudflare R2.









