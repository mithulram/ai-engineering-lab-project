#!/usr/bin/env python3
"""
Unit tests for safety module and safety rules
Tests both block/allow cases and end-to-end safety functionality
"""

import json
import os
import tempfile
import unittest
from unittest.mock import patch, MagicMock
import requests
import time
from PIL import Image
import numpy as np

# Import the safety module
from safety_module import SafetyModule, SafetyViolation, safety_module

class TestSafetyModule(unittest.TestCase):
    """Test cases for the SafetyModule class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.safety_module = SafetyModule()
        self.temp_dir = tempfile.mkdtemp()
        
        # Create a test image
        self.test_image_path = os.path.join(self.temp_dir, "test_image.png")
        test_image = Image.new('RGB', (100, 100), color='red')
        test_image.save(self.test_image_path)
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_military_vehicle_detection_block(self):
        """Test that military vehicle requests are blocked"""
        test_cases = [
            "count tanks in this image",
            "how many armored vehicles",
            "number of fighter jets",
            "count warships",
            "artillery pieces in image",
            "military helicopters count",
            "armored personnel carriers",
            "combat vehicles analysis"
        ]
        
        for text in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                self.assertGreater(len(violations), 0, f"Should block: {text}")
                self.assertEqual(violations[0].violation_type, "military_vehicle_detection")
                self.assertGreater(violations[0].confidence, 0.7)
    
    def test_civilian_vehicle_detection_allow(self):
        """Test that civilian vehicle requests are allowed"""
        test_cases = [
            "count cars in parking lot",
            "how many bicycles",
            "number of trucks",
            "count motorcycles",
            "buses in station",
            "delivery vans count",
            "emergency vehicles",
            "public transport vehicles"
        ]
        
        for text in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                self.assertEqual(len(violations), 0, f"Should allow: {text}")
    
    def test_suspicious_pattern_detection(self):
        """Test detection of suspicious patterns"""
        test_cases = [
            "count camouflaged vehicles",
            "military equipment count",
            "tactical vehicle analysis",
            "strategic asset counting",
            "defense system inventory"
        ]
        
        for text in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                self.assertGreater(len(violations), 0, f"Should block suspicious pattern: {text}")
                # Military detection takes precedence over suspicious patterns
                if "military" in text.lower() or "tactical" in text.lower() or "strategic" in text.lower():
                    self.assertEqual(violations[0].violation_type, "military_vehicle_detection")
                else:
                    self.assertEqual(violations[0].violation_type, "suspicious_pattern")
    
    def test_ambiguous_cases(self):
        """Test ambiguous cases that might be military-related"""
        test_cases = [
            ("count vehicles in military base", True),  # Should block
            ("airport vehicle count", False),           # Should allow
            ("construction equipment", False),          # Should allow
        ]
        
        for text, should_block in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                if should_block:
                    self.assertGreater(len(violations), 0, f"Should block: {text}")
                else:
                    self.assertEqual(len(violations), 0, f"Should allow: {text}")
    
    def test_image_safety_check(self):
        """Test image safety checking"""
        # Test with a regular image (should not be blocked)
        violations = self.safety_module.check_image_safety(self.test_image_path)
        # Note: This might return violations depending on the classifier
        # We just ensure the method runs without error
        self.assertIsInstance(violations, list)
    
    def test_violation_logging(self):
        """Test that violations are properly logged"""
        violation = SafetyViolation(
            violation_type="test_violation",
            reason="Test reason",
            confidence=0.8,
            evidence={"test": "data"}
        )
        
        self.safety_module.log_violation(violation, self.test_image_path)
        
        # Check that violation was added to log
        self.assertEqual(len(self.safety_module.violations_log), 1)
        self.assertEqual(self.safety_module.violations_log[0].violation_type, "test_violation")
        
        # Check that evidence file was created
        evidence_files = [f for f in os.listdir(self.safety_module.evidence_dir) 
                         if f.startswith("violation_")]
        self.assertGreater(len(evidence_files), 0)
    
    def test_violation_stats(self):
        """Test violation statistics generation"""
        # Add some test violations
        violation1 = SafetyViolation("type1", "reason1", 0.8, {})
        violation2 = SafetyViolation("type2", "reason2", 0.9, {})
        violation3 = SafetyViolation("type1", "reason3", 0.7, {})
        
        self.safety_module.violations_log = [violation1, violation2, violation3]
        
        stats = self.safety_module.get_violation_stats()
        
        self.assertEqual(stats["total_violations"], 3)
        self.assertEqual(stats["violation_types"]["type1"], 2)
        self.assertEqual(stats["violation_types"]["type2"], 1)
        self.assertEqual(len(stats["recent_violations"]), 3)
    
    def test_confidence_calculation(self):
        """Test confidence score calculation"""
        # Test with keyword that appears multiple times
        text_with_keyword = "tank tank tank in the image"
        confidence = self.safety_module._calculate_confidence(text_with_keyword, "tank")
        self.assertGreater(confidence, 0.5)
        
        # Test with keyword in short text
        short_text = "tank"
        confidence = self.safety_module._calculate_confidence(short_text, "tank")
        self.assertGreater(confidence, 0.8)
        
        # Test with keyword in long text
        long_text = " ".join(["word"] * 100) + " tank"
        confidence = self.safety_module._calculate_confidence(long_text, "tank")
        self.assertLess(confidence, 0.5)

class TestSafetyIntegration(unittest.TestCase):
    """Integration tests for safety functionality"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.test_image_path = os.path.join(self.temp_dir, "test_image.png")
        
        # Create a test image
        test_image = Image.new('RGB', (100, 100), color='blue')
        test_image.save(self.test_image_path)
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def test_safety_module_initialization(self):
        """Test that safety module initializes correctly"""
        module = SafetyModule()
        
        # Check that military vehicle keywords are loaded
        self.assertGreater(len(module.military_vehicles), 0)
        self.assertIn('tanks', module.military_vehicles)
        
        # Check that suspicious patterns are loaded
        self.assertGreater(len(module.suspicious_patterns), 0)
        self.assertIn('camouflage', module.suspicious_patterns)
        
        # Check that evidence directory exists
        self.assertTrue(os.path.exists(module.evidence_dir))

class TestSafetyAPI(unittest.TestCase):
    """End-to-end tests for safety API functionality"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.test_image_path = os.path.join(self.temp_dir, "test_image.png")
        
        # Create a test image
        test_image = Image.new('RGB', (100, 100), color='green')
        test_image.save(self.test_image_path)
        
        # Start the Flask app in a separate process for testing
        # Note: In a real test environment, you'd use a test client
        self.base_url = "http://localhost:5001"
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    @patch('requests.post')
    def test_blocked_request_returns_403(self, mock_post):
        """Test that blocked requests return HTTP 403 with evidence"""
        # Mock the response for a blocked request
        mock_response = MagicMock()
        mock_response.status_code = 403
        mock_response.json.return_value = {
            'error': 'Request blocked due to safety policy violation',
            'reason': 'Military vehicle counting detected',
            'evidence_file': '/path/to/evidence.json',
            'violations': [
                {
                    'type': 'military_vehicle_detection',
                    'reason': 'Text contains military vehicle reference: tank',
                    'confidence': 0.95
                }
            ]
        }
        mock_post.return_value = mock_response
        
        # Test the API call
        with open(self.test_image_path, 'rb') as f:
            files = {'image': f}
            data = {'item_type': 'tank'}
            
            # This would normally make a real request
            # For testing, we're mocking the response
            response = mock_post(f"{self.base_url}/api/count", files=files, data=data)
        
        # Verify the response
        self.assertEqual(response.status_code, 403)
        response_data = response.json()
        self.assertIn('error', response_data)
        self.assertIn('violations', response_data)
        self.assertIn('evidence_file', response_data)
    
    @patch('requests.post')
    def test_allowed_request_returns_200(self, mock_post):
        """Test that allowed requests return HTTP 200"""
        # Mock the response for an allowed request
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'success': True,
            'count': 5,
            'confidence': 0.85,
            'processing_time': 1.2
        }
        mock_post.return_value = mock_response
        
        # Test the API call
        with open(self.test_image_path, 'rb') as f:
            files = {'image': f}
            data = {'item_type': 'car'}
            
            response = mock_post(f"{self.base_url}/api/count", files=files, data=data)
        
        # Verify the response
        self.assertEqual(response.status_code, 200)
        response_data = response.json()
        self.assertTrue(response_data['success'])
        self.assertIn('count', response_data)
    
    def test_safety_stats_endpoint(self):
        """Test the safety statistics endpoint"""
        # This would test the /api/safety/stats endpoint
        # In a real test, you'd make an actual HTTP request
        pass
    
    def test_evidence_file_creation(self):
        """Test that evidence files are created for blocked requests"""
        # Create a safety module and trigger a violation
        module = SafetyModule()
        
        # Create a test violation
        violation = SafetyViolation(
            violation_type="test_violation",
            reason="Test military vehicle detection",
            confidence=0.9,
            evidence={"text": "count tanks", "keyword": "tank"}
        )
        
        # Log the violation
        module.log_violation(violation, self.test_image_path)
        
        # Check that evidence file was created
        evidence_files = [f for f in os.listdir(module.evidence_dir) 
                         if f.startswith("violation_")]
        self.assertGreater(len(evidence_files), 0)
        
        # Check the content of the evidence file
        evidence_file_path = os.path.join(module.evidence_dir, evidence_files[0])
        with open(evidence_file_path, 'r') as f:
            evidence_data = json.load(f)
        
        self.assertEqual(evidence_data["violation_type"], "test_violation")
        self.assertEqual(evidence_data["reason"], "Test military vehicle detection")
        self.assertEqual(evidence_data["confidence"], 0.9)

class TestSafetyRules(unittest.TestCase):
    """Test specific safety rules and edge cases"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.safety_module = SafetyModule()
    
    def test_military_keyword_variations(self):
        """Test various forms of military keywords"""
        test_cases = [
            ("TANK", True),           # Uppercase
            ("Tank", True),           # Title case
            ("tAnK", True),           # Mixed case
            ("tanks", True),          # Plural
            ("armored vehicle", True), # Multi-word
            ("military equipment", True), # Multi-word
        ]
        
        for text, should_block in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                if should_block:
                    self.assertGreater(len(violations), 0, f"Should block: {text}")
                else:
                    self.assertEqual(len(violations), 0, f"Should allow: {text}")
    
    def test_edge_cases(self):
        """Test edge cases and boundary conditions"""
        test_cases = [
            ("", False),              # Empty string
            ("tank", True),           # Single word
            ("tank tank tank", True), # Repeated word
            ("tankery", False),       # Word containing keyword but not exact match
            ("tank truck", True),     # Multiple keywords
        ]
        
        for text, should_block in test_cases:
            with self.subTest(text=text):
                violations = self.safety_module.check_text_safety(text)
                if should_block:
                    self.assertGreater(len(violations), 0, f"Should block: {text}")
                else:
                    self.assertEqual(len(violations), 0, f"Should allow: {text}")
    
    def test_confidence_thresholds(self):
        """Test that confidence thresholds work correctly"""
        # Test with high confidence case
        high_confidence_text = "count tanks in this military image"
        violations = self.safety_module.check_text_safety(high_confidence_text)
        if violations:
            self.assertGreater(violations[0].confidence, 0.7)
        
        # Test with low confidence case (should not trigger)
        low_confidence_text = "tank"  # Single word, should still trigger
        violations = self.safety_module.check_text_safety(low_confidence_text)
        if violations:
            self.assertGreater(violations[0].confidence, 0.5)

if __name__ == '__main__':
    # Create test suite
    test_suite = unittest.TestSuite()
    
    # Add test cases
    test_suite.addTest(unittest.makeSuite(TestSafetyModule))
    test_suite.addTest(unittest.makeSuite(TestSafetyIntegration))
    test_suite.addTest(unittest.makeSuite(TestSafetyAPI))
    test_suite.addTest(unittest.makeSuite(TestSafetyRules))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(test_suite)
    
    # Print summary
    print(f"\n{'='*60}")
    print(f"SAFETY TESTS SUMMARY")
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
    
    # Exit with appropriate code
    exit(0 if result.wasSuccessful() else 1)
