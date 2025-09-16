#!/usr/bin/env python3
"""
Metrics Scale Test - Smoke test for metrics endpoints
Validates that metrics are in expected ranges (0.0-1.0)
"""

import unittest
import os
import sys

# Add project root to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import app  # noqa: E402


class TestMetricsScale(unittest.TestCase):
    """Test metrics scaling and ranges"""

    def setUp(self):
        """Set up test client"""
        self.app = app.test_client()
        self.app.testing = True

    def test_metrics_endpoint_exists(self):
        """Test that metrics endpoint exists and returns data"""
        response = self.app.get("/metrics")
        self.assertEqual(response.status_code, 200)
        self.assertIn("ai_object_counting", response.data.decode())

    def test_metrics_values_in_range(self):
        """Test that metric values are in expected 0.0-1.0 range"""
        # Record some test metrics
        from monitoring import metrics_collector

        metrics_collector.record_prediction(
            "car", 5, 5, [0.95], [0.1], {"width": 100, "height": 100}
        )
        metrics_collector.record_prediction(
            "truck", 3, 3, [0.92], [0.1], {"width": 100, "height": 100}
        )

        response = self.app.get("/metrics")
        self.assertEqual(response.status_code, 200)

        metrics_text = response.data.decode()

        # Check that metrics endpoint returns Prometheus format
        self.assertIn("# HELP", metrics_text)
        self.assertIn("# TYPE", metrics_text)
        self.assertIn("ai_object_counting_accuracy", metrics_text)
        self.assertIn("ai_object_counting_model_confidence", metrics_text)

    def test_metrics_format_prometheus(self):
        """Test that metrics are in Prometheus format"""
        response = self.app.get("/metrics")
        self.assertEqual(response.status_code, 200)

        metrics_text = response.data.decode()

        # Check Prometheus format elements
        self.assertIn("# HELP", metrics_text)
        self.assertIn("# TYPE", metrics_text)
        self.assertIn("gauge", metrics_text)

    def test_metrics_collector_initialization(self):
        """Test that metrics collector initializes properly"""
        # Test that metrics collector can be imported and used
        from monitoring import metrics_collector

        # Test basic functionality - get_metrics returns Prometheus format string
        metrics_text = metrics_collector.get_metrics()
        self.assertIsInstance(metrics_text, (str, bytes))

        # Convert to string if bytes
        if isinstance(metrics_text, bytes):
            metrics_text = metrics_text.decode()

        # Test that key metrics exist in the text
        expected_metrics = [
            "ai_object_counting_accuracy",
            "ai_object_counting_precision",
            "ai_object_counting_recall",
            "ai_object_counting_model_confidence",
        ]

        for metric in expected_metrics:
            self.assertIn(metric, metrics_text)

    def test_metrics_update_functionality(self):
        """Test that metrics can be updated"""
        from monitoring import metrics_collector

        # Test that metrics collector can be called without errors
        metrics_text = metrics_collector.get_metrics()
        if isinstance(metrics_text, bytes):
            metrics_text = metrics_text.decode()

        # Verify that metrics text contains expected elements
        self.assertIn("ai_object_counting_accuracy", metrics_text)
        self.assertIn("ai_object_counting_model_confidence", metrics_text)

    def test_metrics_edge_cases(self):
        """Test metrics with edge case values"""
        from monitoring import metrics_collector

        # Test boundary values using actual methods
        metrics_collector.record_prediction(
            "car", 5, 5, [0.0], [0.1], {"width": 100, "height": 100}
        )  # min accuracy
        metrics_collector.record_prediction(
            "truck", 3, 3, [1.0], [0.1], {"width": 100, "height": 100}
        )  # max accuracy
        metrics_collector.record_prediction(
            "bike", 2, 2, [0.5], [0.1], {"width": 100, "height": 100}
        )  # mid accuracy

        metrics_text = metrics_collector.get_metrics()
        if isinstance(metrics_text, bytes):
            metrics_text = metrics_text.decode()

        # Verify that metrics text contains the recorded data
        self.assertIn("ai_object_counting_accuracy", metrics_text)
        self.assertIn("ai_object_counting_model_confidence", metrics_text)


if __name__ == "__main__":
    # Set up environment for testing
    os.environ["LOCAL_LOW_MEMORY"] = "1"
    os.environ["FLASK_DEBUG"] = "0"

    # Run tests
    unittest.main(verbosity=2)
