#!/usr/bin/env python3
"""
Load Testing with Locust
Simulates 1M users, stress testing 100K simultaneous
"""

from locust import HttpUser, task, between
import random
import string

class ARCodeUser(HttpUser):
    """Simulate AR Code user behavior"""
    wait_time = between(1, 3)  # Wait 1-3 seconds between requests
    
    def on_start(self):
        """User login/initialization"""
        # Simulate authentication
        self.client.get("/api/v1/auth/login")
        self.user_id = self.generate_user_id()
    
    @task(3)
    def scan_qr_code(self):
        """Scan QR code (most common action)"""
        qr_id = self.generate_random_id()
        self.client.get(f"/api/v1/qr/{qr_id}")
    
    @task(2)
    def view_ar_code(self):
        """View AR Code"""
        ar_code_id = self.generate_random_id()
        self.client.get(f"/api/v1/ar-codes/{ar_code_id}")
    
    @task(1)
    def create_ar_code(self):
        """Create new AR Code"""
        payload = {
            "title": f"Test AR Code {random.randint(1, 1000)}",
            "type": "object_capture",
            "is_public": True
        }
        self.client.post("/api/v1/ar-codes", json=payload)
    
    @task(1)
    def upload_asset(self):
        """Upload asset"""
        # Simulate file upload
        files = {"file": ("test.usdz", b"fake file content", "application/octet-stream")}
        self.client.post("/api/v1/assets/upload", files=files)
    
    @task(1)
    def get_analytics(self):
        """Get analytics data"""
        self.client.get("/api/v1/analytics/stats")
    
    def generate_user_id(self):
        """Generate random user ID"""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=8))
    
    def generate_random_id(self):
        """Generate random ID"""
        return ''.join(random.choices(string.ascii_lowercase + string.digits, k=12))

class HighLoadUser(HttpUser):
    """High load user for stress testing"""
    wait_time = between(0.1, 0.5)  # Very frequent requests
    
    @task
    def health_check(self):
        """Constant health checks"""
        self.client.get("/health")
    
    @task
    def api_ping(self):
        """API ping"""
        self.client.get("/api/v1/ping")

# Usage:
# locust -f locustfile.py --host=https://ar-code.com --users 100000 --spawn-rate 1000







