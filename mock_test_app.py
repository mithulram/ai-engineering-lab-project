#!/usr/bin/env python3
"""
Mock test file for GitLab CI that tests the mock Flask app
without requiring heavy AI dependencies like torch, SAM, etc.
"""

import unittest
import json
import os
import tempfile

from PIL import Image
import numpy as np

# Import the mock Flask app
from mock_app import app, db, CountingResult


class TestMockObjectCountingAPI(unittest.TestCase):
    """Test cases for the Mock Object Counting API."""

    def setUp(self):
        """Set up test environment before each test."""
        # Configure app for testing
        app.config["TESTING"] = True
        app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
        app.config["UPLOAD_FOLDER"] = tempfile.mkdtemp()

        # Create test client
        self.client = app.test_client()

        # Create database tables
        with app.app_context():
            db.create_all()

    def tearDown(self):
        """Clean up after each test."""
        # Remove test files
        import shutil

        shutil.rmtree(app.config["UPLOAD_FOLDER"])

        # Clean up database
        with app.app_context():
            db.session.remove()
            db.drop_all()

    def create_test_image(self, filename="test_image.png"):
        """Create a test image file."""
        # Create a simple test image
        img_array = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        img = Image.fromarray(img_array)

        # Save to temporary file
        file_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
        img.save(file_path)

        return file_path

    def test_health_check(self):
        """Test the health check endpoint."""
        response = self.client.get("/api/health")
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(data["status"], "healthy")
        self.assertIn("timestamp", data)
        self.assertEqual(data["service"], "AI Object Counting API (Mock)")

    def test_count_objects_missing_image(self):
        """Test count endpoint with missing image."""
        response = self.client.post("/api/count", data={"item_type": "car"})
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "No image file provided")

    def test_count_objects_missing_item_type(self):
        """Test count endpoint with missing item type."""
        # Create test image
        test_image_path = self.create_test_image()

        with open(test_image_path, "rb") as img:
            response = self.client.post("/api/count", data={"image": (img, "test.png")})

        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "No item type specified")

    def test_count_objects_invalid_item_type(self):
        """Test count endpoint with invalid item type."""
        test_image_path = self.create_test_image()

        with open(test_image_path, "rb") as img:
            response = self.client.post(
                "/api/count",
                data={"image": (img, "test.png"), "item_type": "invalid_type"},
            )

        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid item type", data["error"])

    def test_count_objects_success(self):
        """Test successful object counting."""
        test_image_path = self.create_test_image()

        with open(test_image_path, "rb") as img:
            response = self.client.post(
                "/api/count", data={"image": (img, "test.png"), "item_type": "car"}
            )

        data = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertIn("id", data)
        self.assertEqual(data["count"], 3)
        self.assertEqual(data["item_type"], "car")
        self.assertIn("confidence_score", data)
        self.assertIn("processing_time", data)

    def test_correct_count_missing_data(self):
        """Test correct endpoint with missing data."""
        response = self.client.post("/api/correct", json={})
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "No data provided")

    def test_correct_count_missing_result_id(self):
        """Test correct endpoint with missing result ID."""
        response = self.client.post("/api/correct", json={"corrected_count": 5})
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "No result ID provided")

    def test_correct_count_missing_corrected_count(self):
        """Test correct endpoint with missing corrected count."""
        response = self.client.post("/api/correct", json={"result_id": "test-id"})
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(data["error"], "No corrected count provided")

    def test_correct_count_success(self):
        """Test successful count correction."""
        response = self.client.post(
            "/api/correct",
            json={
                "result_id": "test-id-123",
                "corrected_count": 5,
                "user_feedback": "Test feedback",
            },
        )

        data = json.loads(response.data)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data["message"], "Count corrected successfully")
        self.assertEqual(data["result_id"], "test-id-123")
        self.assertEqual(data["corrected_count"], 5)
        self.assertEqual(data["user_feedback"], "Test feedback")

    def test_get_results(self):
        """Test getting results endpoint."""
        response = self.client.get("/api/results")
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(data["total"], 0)
        self.assertEqual(data["message"], "No results available in mock mode")

    def test_database_model(self):
        """Test the database model."""
        with app.app_context():
            # Create a test record
            from datetime import datetime

            test_result = CountingResult(
                id="test-id",
                timestamp=datetime.utcnow(),
                image_path="test.jpg",
                item_type="car",
                predicted_count=3,
                confidence_score=0.85,
                processing_time=1.5,
            )

            # Test the to_dict method
            result_dict = test_result.to_dict()
            self.assertEqual(result_dict["id"], "test-id")
            self.assertEqual(result_dict["item_type"], "car")
            self.assertEqual(result_dict["predicted_count"], 3)
            self.assertEqual(result_dict["confidence_score"], 0.85)


if __name__ == "__main__":
    # Run the tests
    unittest.main(verbosity=2)
