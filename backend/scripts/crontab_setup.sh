#!/bin/bash
# Setup cron jobs for AR Code backend

# Weekly stats email (every Monday at 9:00 AM)
(crontab -l 2>/dev/null; echo "0 9 * * 1 cd /path/to/backend && /usr/bin/python3 scripts/cron_weekly_stats.py >> /var/log/arcode_weekly_stats.log 2>&1") | crontab -

echo "Cron jobs configured successfully"











