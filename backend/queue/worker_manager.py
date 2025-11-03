#!/usr/bin/env python3
"""
Worker Manager
Start RQ workers pour différents types de jobs
"""

import os
import sys
from pathlib import Path
import subprocess

def start_worker(queue_name: str, worker_name: str, num_workers: int = 1):
    """
    Start RQ worker
    
    Args:
        queue_name: Queue name (high, default, low)
        worker_name: Worker name
        num_workers: Number of concurrent workers
    """
    from rq import Worker, Queue, Connection
    from rq_config import redis_conn, get_queue
    
    queue = get_queue(queue_name)
    
    worker = Worker(
        [queue],
        connection=redis_conn,
        name=worker_name
    )
    
    worker.work(with_scheduler=True)

if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Start RQ worker')
    parser.add_argument('queue', choices=['high', 'default', 'low'], help='Queue name')
    parser.add_argument('--name', default=None, help='Worker name')
    parser.add_argument('--workers', type=int, default=1, help='Number of workers')
    
    args = parser.parse_args()
    
    worker_name = args.name or f"worker-{args.queue}"
    
    print(f"Starting {worker_name} on {args.queue} queue...")
    start_worker(args.queue, worker_name, args.workers)









