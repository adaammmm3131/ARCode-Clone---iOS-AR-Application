#!/usr/bin/env python3
"""
Weekly Stats Email Cron Job
Run every Monday at 9:00 AM
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from email.notification_service import send_weekly_stats_to_users
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    """Send weekly stats to all opted-in users"""
    logger.info("Starting weekly stats email batch...")
    
    sent_count = send_weekly_stats_to_users()
    
    logger.info(f"Weekly stats emails sent: {sent_count}")
    
    return sent_count

if __name__ == '__main__':
    main()







