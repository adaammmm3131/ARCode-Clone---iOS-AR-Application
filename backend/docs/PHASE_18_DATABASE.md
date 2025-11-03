# Phase 18.4 - PostgreSQL Database Setup

Guide complet pour installer PostgreSQL et créer le schéma de base de données.

## Étape 1: Installation PostgreSQL

### 1.1. Installer PostgreSQL

```bash
# Ubuntu 22.04
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Vérifier version
sudo -u postgres psql -c "SELECT version();"
```

### 1.2. Configuration PostgreSQL

```bash
# Éditer configuration
sudo nano /etc/postgresql/14/main/postgresql.conf

# Modifications recommandées:
# - shared_buffers = 256MB (25% RAM pour 24GB)
# - effective_cache_size = 768MB
# - maintenance_work_mem = 64MB
# - checkpoint_completion_target = 0.9
# - wal_buffers = 16MB
# - default_statistics_target = 100
# - random_page_cost = 1.1
# - effective_io_concurrency = 200
# - work_mem = 4MB
# - min_wal_size = 1GB
# - max_wal_size = 4GB
# - max_connections = 100
```

### 1.3. Configuration authentification

```bash
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Autoriser connexions locales
local   all             all                                     peer
host    all             all             127.0.0.1/32            md5
```

### 1.4. Redémarrer PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
```

## Étape 2: Créer Database et Utilisateur

### 2.1. Créer utilisateur

```bash
sudo -u postgres psql

CREATE USER arcode_user WITH PASSWORD 'strong_password_here';
ALTER USER arcode_user CREATEDB;

\q
```

### 2.2. Créer database

```bash
sudo -u postgres psql

CREATE DATABASE arcode_db OWNER arcode_user;
GRANT ALL PRIVILEGES ON DATABASE arcode_db TO arcode_user;

\q
```

## Étape 3: Schéma Database

### 3.1. Structure tables

Voir `backend/database/schema.sql`

### 3.2. Créer schéma

```bash
psql -U arcode_user -d arcode_db -f backend/database/schema.sql
```

## Étape 4: Migrations

### 4.1. Installer Alembic

```bash
pip install alembic sqlalchemy
```

### 4.2. Initialiser Alembic

```bash
cd backend
alembic init migrations
```

### 4.3. Configuration Alembic

Éditer `migrations/alembic.ini`:

```ini
sqlalchemy.url = postgresql://arcode_user:password@localhost/arcode_db
```

Éditer `migrations/env.py` pour pointer vers models.

### 4.4. Créer première migration

```bash
alembic revision --autogenerate -m "Initial schema"
alembic upgrade head
```

## Étape 5: Indexes Optimization

### 5.1. Indexes essentiels

Voir `backend/database/indexes.sql`

### 5.2. Appliquer indexes

```bash
psql -U arcode_user -d arcode_db -f backend/database/indexes.sql
```

### 5.3. Analyser performance

```bash
psql -U arcode_user -d arcode_db

# Analyser tables
ANALYZE;

# Vérifier query plans
EXPLAIN ANALYZE SELECT * FROM ar_codes WHERE user_id = 'xxx';
```

## Étape 6: Backup Strategy

### 6.1. Script backup automatique

Créer `backend/scripts/backup_db.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/postgresql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="arcode_db"

mkdir -p $BACKUP_DIR

# Backup
pg_dump -U arcode_user -d $DB_NAME | gzip > $BACKUP_DIR/$DB_NAME_$DATE.sql.gz

# Garder seulement 7 derniers backups
ls -t $BACKUP_DIR/$DB_NAME_*.sql.gz | tail -n +8 | xargs rm -f
```

### 6.2. Cron job quotidien

```bash
crontab -e

# Backup quotidien à 2h du matin
0 2 * * * /path/to/backup_db.sh
```

### 6.3. Restore

```bash
gunzip < backup.sql.gz | psql -U arcode_user -d arcode_db
```

## Étape 7: Monitoring

### 7.1. pg_stat_statements

```bash
# Installer extension
sudo -u postgres psql -d arcode_db
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

# Configuration
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
sudo systemctl restart postgresql
```

### 7.2. Queries lentes

```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## Checklist

- [ ] PostgreSQL installé
- [ ] Configuration optimisée
- [ ] Utilisateur créé
- [ ] Database créée
- [ ] Schéma appliqué
- [ ] Migrations configurées
- [ ] Indexes créés
- [ ] Backup automatique configuré
- [ ] Monitoring activé

## Prochaines étapes

Voir `PHASE_18_REDIS.md` pour configuration Redis.









