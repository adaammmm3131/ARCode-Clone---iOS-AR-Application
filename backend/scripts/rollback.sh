#!/bin/bash
# Rollback Script
# Usage: ./rollback.sh [backup_timestamp]

set -e

if [ -z "$1" ]; then
  echo "Usage: ./rollback.sh [backup_timestamp]"
  echo "Available backups:"
  ls -1 /opt/arcode/backups/backend_*.tar.gz | sed 's/.*backend_//;s/.tar.gz//'
  exit 1
fi

BACKUP_TIMESTAMP=$1
BACKUP_FILE="/opt/arcode/backups/backend_${BACKUP_TIMESTAMP}.tar.gz"
DEPLOY_DIR="/opt/arcode/backend"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "🔄 Rolling back to backup: $BACKUP_TIMESTAMP"

# Create current state backup
CURRENT_BACKUP="/opt/arcode/backups/pre_rollback_$(date +%Y%m%d_%H%M%S).tar.gz"
sudo tar -czf $CURRENT_BACKUP -C $DEPLOY_DIR .
echo "📦 Current state backed up to: $CURRENT_BACKUP"

# Restore backup
echo "📥 Restoring backup..."
sudo tar -xzf $BACKUP_FILE -C $DEPLOY_DIR

# Restart services
echo "🔄 Restarting services..."
sudo systemctl restart arcode-api
sudo systemctl restart rq-worker
sudo systemctl restart nginx

# Health check
echo "🏥 Performing health check..."
sleep 5
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Rollback successful!"
else
  echo "❌ Health check failed after rollback ($HTTP_CODE)"
  exit 1
fi







