#!/bin/bash
# Backend Deployment Script
# Usage: ./deploy.sh [staging|production]

set -e

ENVIRONMENT=${1:-staging}
DEPLOY_DIR="/opt/arcode/backend"
BACKUP_DIR="/opt/arcode/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "🚀 Starting deployment to $ENVIRONMENT..."

# Create backup
echo "📦 Creating backup..."
sudo mkdir -p $BACKUP_DIR
sudo tar -czf $BACKUP_DIR/backend_${TIMESTAMP}.tar.gz -C $DEPLOY_DIR .

# Activate virtual environment
source $DEPLOY_DIR/venv/bin/activate

# Run database migrations
echo "🗄️  Running database migrations..."
python -m database.migrate --env $ENVIRONMENT

# Install/update dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
find . -name "requirements.txt" -exec pip install -r {} \;

# Restart services
echo "🔄 Restarting services..."
sudo systemctl restart arcode-api
sudo systemctl restart rq-worker
sudo systemctl restart nginx

# Health check
echo "🏥 Performing health check..."
sleep 5
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "000")
  
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Deployment successful!"
    exit 0
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "⏳ Health check failed ($HTTP_CODE), retrying ($RETRY_COUNT/$MAX_RETRIES)..."
  sleep 5
done

# Rollback on failure
echo "❌ Health check failed, rolling back..."
sudo tar -xzf $BACKUP_DIR/backend_${TIMESTAMP}.tar.gz -C $DEPLOY_DIR
sudo systemctl restart arcode-api
sudo systemctl restart rq-worker

echo "🔄 Rollback completed"
exit 1







