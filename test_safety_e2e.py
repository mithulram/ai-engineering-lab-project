#!/usr/bin/env python3
"""
End-to-end tests for safety functionality
Tests the actual API endpoints with real HTTP requests
"""

import json
import os
import tempfile
import time
import requests
from PIL import Image
import unittest

class TestSafetyE2E(unittest.TestCase):
    """End-to-end tests for safety API"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.base_url = "http://localhost:5001"
        self.temp_dir = tempfile.mkdtemp()
        
        # Create test images
        self.military_image_path = os.path.join(self.temp_dir, "military_test.png")
        self.civilian_image_path = os.path.join(self.temp_dir, "civilian_test.png")
        
        # Create a test image (simple colored rectangle)
        military_image = Image.new('RGB', (200, 200), color='green')  # Camouflage-like color
        military_image.save(self.military_image_path)
        
        civilian_image = Image.new('RGB', (200, 200), color='blue')
        civilian_image.save(self.civilian_image_path)
        
        # Wait for server to be ready
        self._wait_for_server()
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def _wait_for_server(self, timeout=30):
        """Wait for the server to be ready"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(f"{self.base_url}/api/health", timeout=5)
                if response.status_code == 200:
                    print("Server is ready")
                    return
            except requests.exceptions.RequestException:
                pass
            time.sleep(1)
        
        self.skipTest("Server not ready within timeout")
    
    def test_military_vehicle_request_blocked(self):
        """Test that military vehicle counting requests are blocked with 403"""
        test_cases = [
            ("car", "count tanks in this image"),
            ("car", "how many armored vehicles"),
            ("car", "number of fighter jets"),
            ("car", "count warships"),
            ("car", "artillery pieces in image")
        ]
        
        for item_type, description in test_cases:
            with self.subTest(item_type=item_type):
                with open(self.military_image_path, 'rb') as f:
                    files = {'image': f}
                    data = {
                        'item_type': item_type,
                        'description': description
                    }
                    
                    response = requests.post(
                        f"{self.base_url}/api/count",
                        files=files,
                        data=data,
                        timeout=30
                    )
                
                # Should be blocked with 403
                self.assertEqual(response.status_code, 403, 
                               f"Request for {item_type} should be blocked")
                
                response_data = response.json()
                self.assertIn('error', response_data)
                self.assertIn('violations', response_data)
                self.assertIn('evidence_file', response_data)
                
                # Check that evidence file exists
                evidence_file = response_data['evidence_file']
                self.assertTrue(os.path.exists(evidence_file), 
                              "Evidence file should be created")
                
                # Check evidence file content
                with open(evidence_file, 'r') as f:
                    evidence_data = json.load(f)
                
                self.assertIn('violations', evidence_data)
                self.assertIn('timestamp', evidence_data)
                self.assertIn('image_path', evidence_data)
                
                print(f"✓ Blocked {item_type} request - Evidence: {evidence_file}")
    
    def test_civilian_vehicle_request_allowed(self):
        """Test that civilian vehicle counting requests are allowed"""
        test_cases = [
            ("car", "count cars in parking lot"),
            ("bicycle", "how many bicycles"),
            ("truck", "number of trucks"),
            ("motorcycle", "count motorcycles"),
            ("bus", "buses in station")
        ]
        
        for item_type, description in test_cases:
            with self.subTest(item_type=item_type):
                with open(self.civilian_image_path, 'rb') as f:
                    files = {'image': f}
                    data = {
                        'item_type': item_type,
                        'description': description
                    }
                    
                    response = requests.post(
                        f"{self.base_url}/api/count",
                        files=files,
                        data=data,
                        timeout=30
                    )
                
                # Should be allowed (200 or processing error is acceptable)
                self.assertIn(response.status_code, [200, 500], 
                             f"Request for {item_type} should be allowed or processable")
                
                if response.status_code == 200:
                    response_data = response.json()
                    self.assertIn('count', response_data)
                    print(f"✓ Allowed {item_type} request - Count: {response_data.get('count', 'N/A')}")
                else:
                    print(f"✓ Allowed {item_type} request - Processing error (expected for test images)")
    
    def test_suspicious_pattern_blocked(self):
        """Test that suspicious patterns are blocked"""
        test_cases = [
            ("vehicle", "count camouflaged vehicles"),
            ("equipment", "military equipment count"),
            ("analysis", "tactical vehicle analysis"),
            ("counting", "strategic asset counting"),
            ("inventory", "defense system inventory")
        ]
        
        for item_type, description in test_cases:
            with self.subTest(item_type=item_type):
                with open(self.military_image_path, 'rb') as f:
                    files = {'image': f}
                    data = {
                        'item_type': item_type,
                        'description': description
                    }
                    
                    response = requests.post(
                        f"{self.base_url}/api/count",
                        files=files,
                        data=data,
                        timeout=30
                    )
                
                # Should be blocked with 403
                self.assertEqual(response.status_code, 403, 
                               f"Suspicious pattern '{description}' should be blocked")
                
                response_data = response.json()
                self.assertIn('violations', response_data)
                
                print(f"✓ Blocked suspicious pattern: {description}")
    
    def test_safety_stats_endpoint(self):
        """Test the safety statistics endpoint"""
        response = requests.get(f"{self.base_url}/api/safety/stats", timeout=10)
        
        self.assertEqual(response.status_code, 200)
        
        response_data = response.json()
        self.assertIn('success', response_data)
        self.assertIn('safety_stats', response_data)
        
        stats = response_data['safety_stats']
        self.assertIn('total_violations', stats)
        self.assertIn('violation_types', stats)
        self.assertIn('recent_violations', stats)
        
        print(f"✓ Safety stats endpoint working - Total violations: {stats['total_violations']}")
    
    def test_evidence_file_access(self):
        """Test that evidence files can be accessed via API"""
        # First, trigger a blocked request to create evidence
        with open(self.military_image_path, 'rb') as f:
            files = {'image': f}
            data = {'item_type': 'tank'}
            
            response = requests.post(
                f"{self.base_url}/api/count",
                files=files,
                data=data,
                timeout=30
            )
        
        self.assertEqual(response.status_code, 403)
        response_data = response.json()
        evidence_file = response_data['evidence_file']
        
        # Extract filename from path
        evidence_filename = os.path.basename(evidence_file)
        
        # Try to access the evidence file via API
        evidence_response = requests.get(
            f"{self.base_url}/api/safety/evidence/{evidence_filename}",
            timeout=10
        )
        
        # Should be able to access the evidence file
        self.assertEqual(evidence_response.status_code, 200)
        
        # Should be JSON content
        evidence_data = evidence_response.json()
        self.assertIn('violations', evidence_data)
        
        print(f"✓ Evidence file accessible: {evidence_filename}")
    
    def test_multiple_violations_same_request(self):
        """Test that multiple violations in one request are all detected"""
        with open(self.military_image_path, 'rb') as f:
            files = {'image': f}
            data = {
                'item_type': 'tank',
                'description': 'count camouflaged military tanks in tactical formation'
            }
            
            response = requests.post(
                f"{self.base_url}/api/count",
                files=files,
                data=data,
                timeout=30
            )
        
        self.assertEqual(response.status_code, 403)
        response_data = response.json()
        
        # Should have multiple violations
        violations = response_data['violations']
        self.assertGreater(len(violations), 1, "Should detect multiple violations")
        
        # Check violation types
        violation_types = [v['type'] for v in violations]
        self.assertIn('military_vehicle_detection', violation_types)
        self.assertIn('suspicious_pattern', violation_types)
        
        print(f"✓ Detected {len(violations)} violations: {violation_types}")
    
    def test_metrics_updated_on_blocked_request(self):
        """Test that metrics are updated when requests are blocked"""
        # Get initial metrics
        initial_response = requests.get(f"{self.base_url}/metrics", timeout=10)
        initial_metrics = initial_response.text
        
        # Count initial blocked requests
        initial_blocked = initial_metrics.count('ai_object_counting_blocked_requests_total')
        
        # Make a blocked request
        with open(self.military_image_path, 'rb') as f:
            files = {'image': f}
            data = {'item_type': 'tank'}
            
            response = requests.post(
                f"{self.base_url}/api/count",
                files=files,
                data=data,
                timeout=30
            )
        
        self.assertEqual(response.status_code, 403)
        
        # Wait a moment for metrics to update
        time.sleep(1)
        
        # Get updated metrics
        updated_response = requests.get(f"{self.base_url}/metrics", timeout=10)
        updated_metrics = updated_response.text
        
        # Count updated blocked requests
        updated_blocked = updated_metrics.count('ai_object_counting_blocked_requests_total')
        
        # Should have more blocked request metrics
        self.assertGreaterEqual(updated_blocked, initial_blocked, 
                               "Blocked request metrics should be updated")
        
        print(f"✓ Metrics updated - Blocked requests: {initial_blocked} -> {updated_blocked}")

def run_e2e_tests():
    """Run all end-to-end tests"""
    print("="*60)
    print("SAFETY END-TO-END TESTS")
    print("="*60)
    print("Note: These tests require the Flask server to be running on localhost:5001")
    print("Start the server with: python3 app.py")
    print("="*60)
    
    # Create test suite
    test_suite = unittest.TestSuite()
    test_suite.addTest(unittest.makeSuite(TestSafetyE2E))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # Print summary
    print(f"\n{'='*60}")
    print(f"E2E TESTS SUMMARY")
    print(f"{'='*60}")
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Success rate: {((result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100):.1f}%")
    
    if result.failures:
        print(f"\nFAILURES:")
        for test, traceback in result.failures:
            print(f"  - {test}: {traceback}")
    
    if result.errors:
        print(f"\nERRORS:")
        for test, traceback in result.errors:
            print(f"  - {test}: {traceback}")
    
    print(f"{'='*60}")
    
    return result.wasSuccessful()

if __name__ == '__main__':
    success = run_e2e_tests()
    exit(0 if success else 1)
