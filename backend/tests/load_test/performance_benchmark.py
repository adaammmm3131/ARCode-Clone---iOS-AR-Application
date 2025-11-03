#!/usr/bin/env python3
"""
Performance Benchmark Script
Measures API response times and throughput
"""

import time
import requests
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict

class PerformanceBenchmark:
    def __init__(self, base_url: str = "https://ar-code.com"):
        self.base_url = base_url
        self.results: List[Dict] = []
    
    def benchmark_endpoint(
        self,
        endpoint: str,
        method: str = "GET",
        num_requests: int = 100,
        concurrent: int = 10
    ) -> Dict:
        """Benchmark an endpoint"""
        times = []
        errors = 0
        
        def make_request():
            start = time.time()
            try:
                if method == "GET":
                    response = requests.get(f"{self.base_url}{endpoint}", timeout=10)
                else:
                    response = requests.post(f"{self.base_url}{endpoint}", timeout=10)
                
                elapsed = (time.time() - start) * 1000  # Convert to ms
                times.append(elapsed)
                
                if response.status_code >= 400:
                    errors += 1
            except Exception as e:
                errors += 1
                times.append(0)
        
        # Execute requests concurrently
        with ThreadPoolExecutor(max_workers=concurrent) as executor:
            futures = [executor.submit(make_request) for _ in range(num_requests)]
            for future in as_completed(futures):
                future.result()
        
        return {
            "endpoint": endpoint,
            "method": method,
            "total_requests": num_requests,
            "concurrent": concurrent,
            "avg_time_ms": statistics.mean(times) if times else 0,
            "median_time_ms": statistics.median(times) if times else 0,
            "p95_time_ms": self.percentile(times, 95) if times else 0,
            "p99_time_ms": self.percentile(times, 99) if times else 0,
            "min_time_ms": min(times) if times else 0,
            "max_time_ms": max(times) if times else 0,
            "errors": errors,
            "success_rate": ((num_requests - errors) / num_requests * 100) if num_requests > 0 else 0
        }
    
    def percentile(self, data: List[float], percentile: int) -> float:
        """Calculate percentile"""
        if not data:
            return 0.0
        sorted_data = sorted(data)
        index = int(len(sorted_data) * percentile / 100)
        return sorted_data[min(index, len(sorted_data) - 1)]
    
    def run_full_benchmark(self):
        """Run benchmark on all major endpoints"""
        endpoints = [
            ("/health", "GET"),
            ("/api/v1/ar-codes", "GET"),
            ("/api/v1/ar-codes", "POST"),
            ("/api/v1/analytics/stats", "GET"),
        ]
        
        print("Running performance benchmark...")
        print("=" * 60)
        
        for endpoint, method in endpoints:
            result = self.benchmark_endpoint(endpoint, method, num_requests=100, concurrent=10)
            self.results.append(result)
            
            print(f"\n{method} {endpoint}")
            print(f"  Avg: {result['avg_time_ms']:.2f}ms")
            print(f"  P95: {result['p95_time_ms']:.2f}ms")
            print(f"  P99: {result['p99_time_ms']:.2f}ms")
            print(f"  Success Rate: {result['success_rate']:.1f}%")
        
        print("\n" + "=" * 60)
        print("Benchmark complete!")

if __name__ == '__main__':
    benchmark = PerformanceBenchmark()
    benchmark.run_full_benchmark()







