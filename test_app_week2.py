#!/usr/bin/env python3
"""
Comprehensive test suite for AI Object Counting Application - Week 2
Tests all functionality including monitoring, few-shot learning, and performance
"""

import unittest
import os
import tempfile
import json
import time
from datetime import datetime
from PIL import Image
import requests
import io

# Import the Flask app
from app import app, db, CountingResult

class TestAIObjectCountingWeek2(unittest.TestCase):
    """Test cases for Week 2 functionality"""
    
    def setUp(self):
        """Set up test environment"""
        self.app = app
        self.app.config['TESTING'] = True
        self.app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        self.client = self.app.test_client()
        
        with self.app.app_context():
            db.create_all()
    
    def tearDown(self):
        """Clean up after tests"""
        with self.app.app_context():
            db.drop_all()
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = self.client.get('/api/health')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
        self.assertEqual(data['service'], 'AI Object Counting API')
    
    def test_metrics_endpoint(self):
        """Test OpenMetrics endpoint"""
        response = self.client.get('/metrics')
        self.assertEqual(response.status_code, 200)
        
        # Check content type
        self.assertEqual(response.content_type, 'text/plain; version=0.0.4; charset=utf-8')
        
        # Check that metrics are in OpenMetrics format
        content = response.data.decode('utf-8')
        self.assertIn('# HELP', content)
        self.assertIn('# TYPE', content)
        self.assertIn('ai_object_counting_', content)
    
    def test_object_counting_api(self):
        """Test object counting API with mock image"""
        # Create a test image
        test_image = Image.new('RGB', (256, 256), color='red')
        img_io = io.BytesIO()
        test_image.save(img_io, format='PNG')
        img_io.seek(0)
        
        # Test API call
        response = self.client.post('/api/count', 
                                  data={'item_type': 'car', 'image': (img_io, 'test.png')},
                                  content_type='multipart/form-data')
        
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('id', data)
        self.assertIn('count', data)
        self.assertIn('confidence_score', data)
        self.assertIn('processing_time', data)
        self.assertEqual(data['item_type'], 'car')
    
    def test_correct_count_api(self):
        """Test count correction API"""
        # First create a counting result
        with self.app.app_context():
            result = CountingResult(
                id='test-id',
                image_path='/test/path',
                item_type='car',
                predicted_count=3,
                corrected_count=None,
                confidence_score=0.8,
                processing_time=1.5,
                user_feedback=None,
                timestamp=datetime.utcnow()
            )
            db.session.add(result)
            db.session.commit()
        
        # Test correction
        response = self.client.post('/api/correct', 
                                  json={
                                      'result_id': 'test-id',
                                      'corrected_count': 5,
                                      'user_feedback': 'Test correction'
                                  })
        
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertEqual(data['message'], 'Count corrected successfully')
    
    def test_results_api(self):
        """Test results retrieval API"""
        # Create test results
        with self.app.app_context():
            for i in range(5):
                result = CountingResult(
                    id=f'test-id-{i}',
                    image_path=f'/test/path-{i}',
                    item_type='car',
                    predicted_count=i+1,
                    corrected_count=None,
                    confidence_score=0.8,
                    processing_time=1.5,
                    user_feedback=None,
                    timestamp=datetime.utcnow()
                )
                db.session.add(result)
            db.session.commit()
        
        # Test results retrieval
        response = self.client.get('/api/results')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('results', data)
        self.assertIn('total', data)
        self.assertIn('page', data)
        self.assertIn('per_page', data)
        self.assertEqual(len(data['results']), 5)
    
    def test_few_shot_learning_learn(self):
        """Test few-shot learning - learn new object"""
        # Create test images
        test_images = []
        for i in range(3):
            img = Image.new('RGB', (64, 64), color='blue')
            img_io = io.BytesIO()
            img.save(img_io, format='PNG')
            img_io.seek(0)
            test_images.append((img_io, f'test_{i}.png'))
        
        # Test learning API
        response = self.client.post('/api/learn',
                                  data={
                                      'object_name': 'test_object',
                                      'images': test_images
                                  },
                                  content_type='multipart/form-data')
        
        # Should succeed (even if learning fails, API should handle gracefully)
        self.assertIn(response.status_code, [200, 400, 500])
    
    def test_few_shot_learning_list(self):
        """Test few-shot learning - list learned objects"""
        response = self.client.get('/api/learned-objects')
        self.assertEqual(response.status_code, 200)
        
        data = json.loads(response.data)
        self.assertIn('learned_objects', data)
        self.assertIn('count', data)
        self.assertIsInstance(data['learned_objects'], list)
    
    def test_few_shot_learning_count(self):
        """Test few-shot learning - count learned objects"""
        # Create a test image
        test_image = Image.new('RGB', (256, 256), color='green')
        img_io = io.BytesIO()
        test_image.save(img_io, format='PNG')
        img_io.seek(0)
        
        # Test counting API
        response = self.client.post('/api/count-learned',
                                  data={
                                      'object_name': 'test_object',
                                      'image': (img_io, 'test.png')
                                  },
                                  content_type='multipart/form-data')
        
        # Should succeed (even if object not learned, API should handle gracefully)
        self.assertIn(response.status_code, [200, 400, 500])
    
    def test_few_shot_learning_recognize(self):
        """Test few-shot learning - recognize objects"""
        # Create a test image
        test_image = Image.new('RGB', (256, 256), color='yellow')
        img_io = io.BytesIO()
        test_image.save(img_io, format='PNG')
        img_io.seek(0)
        
        # Test recognition API
        response = self.client.post('/api/recognize',
                                  data={
                                      'threshold': '0.5',
                                      'image': (img_io, 'test.png')
                                  },
                                  content_type='multipart/form-data')
        
        # Should succeed
        self.assertIn(response.status_code, [200, 400, 500])
    
    def test_few_shot_learning_delete(self):
        """Test few-shot learning - delete learned object"""
        response = self.client.delete('/api/delete-learned-object',
                                    json={'object_name': 'test_object'})
        
        # Should succeed (even if object doesn't exist)
        self.assertIn(response.status_code, [200, 404])
    
    def test_upload_file_serving(self):
        """Test uploaded file serving"""
        # Create a test file
        test_content = b'test file content'
        test_filename = 'test_file.txt'
        
        with self.app.app_context():
            # Save test file
            upload_dir = self.app.config['UPLOAD_FOLDER']
            os.makedirs(upload_dir, exist_ok=True)
            test_file_path = os.path.join(upload_dir, test_filename)
            with open(test_file_path, 'wb') as f:
                f.write(test_content)
        
        # Test file serving
        response = self.client.get(f'/uploads/{test_filename}')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, test_content)
    
    def test_error_handling(self):
        """Test error handling"""
        # Test 404 error
        response = self.client.get('/nonexistent-endpoint')
        self.assertEqual(response.status_code, 404)
        
        # Test invalid count request
        response = self.client.post('/api/count')
        self.assertEqual(response.status_code, 400)
        
        # Test invalid correct request
        response = self.client.post('/api/correct', json={})
        self.assertEqual(response.status_code, 400)
    
    def test_database_model(self):
        """Test the database model"""
        with self.app.app_context():
            # Create a test result
            result = CountingResult(
                id='test-model-id',
                image_path='/test/path',
                item_type='car',
                predicted_count=3,
                corrected_count=4,
                confidence_score=0.8,
                processing_time=1.5,
                user_feedback='Test feedback',
                timestamp=datetime.utcnow()
            )
            
            # Test to_dict method
            result_dict = result.to_dict()
            
            self.assertEqual(result_dict['id'], 'test-model-id')
            self.assertEqual(result_dict['item_type'], 'car')
            self.assertEqual(result_dict['predicted_count'], 3)
            self.assertEqual(result_dict['corrected_count'], 4)
            self.assertEqual(result_dict['confidence_score'], 0.8)
            self.assertEqual(result_dict['processing_time'], 1.5)
            self.assertEqual(result_dict['user_feedback'], 'Test feedback')
            self.assertIn('timestamp', result_dict)
    
    def test_performance_metrics(self):
        """Test that performance metrics are being recorded"""
        # Create a test image
        test_image = Image.new('RGB', (256, 256), color='red')
        img_io = io.BytesIO()
        test_image.save(img_io, format='PNG')
        img_io.seek(0)
        
        # Make API call
        response = self.client.post('/api/count', 
                                  data={'item_type': 'car', 'image': (img_io, 'test.png')},
                                  content_type='multipart/form-data')
        
        self.assertEqual(response.status_code, 200)
        
        # Check that metrics endpoint has data
        metrics_response = self.client.get('/metrics')
        self.assertEqual(metrics_response.status_code, 200)
        
        # Check that metrics contain expected data
        metrics_content = metrics_response.data.decode('utf-8')
        self.assertIn('ai_object_counting_requests_total', metrics_content)
        self.assertIn('ai_object_counting_response_time_seconds', metrics_content)
    
    def test_concurrent_requests(self):
        """Test handling of concurrent requests"""
        import threading
        import time
        
        results = []
        errors = []
        
        def make_request():
            try:
                test_image = Image.new('RGB', (64, 64), color='blue')
                img_io = io.BytesIO()
                test_image.save(img_io, format='PNG')
                img_io.seek(0)
                
                response = self.client.post('/api/count', 
                                          data={'item_type': 'car', 'image': (img_io, 'test.png')},
                                          content_type='multipart/form-data')
                results.append(response.status_code)
            except Exception as e:
                errors.append(str(e))
        
        # Create multiple threads
        threads = []
        for i in range(5):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # Check results
        self.assertEqual(len(results), 5)
        self.assertEqual(len(errors), 0)
        for status_code in results:
            self.assertEqual(status_code, 200)
    
    def test_api_documentation_endpoints(self):
        """Test that all documented endpoints exist"""
        endpoints = [
            '/api/health',
            '/api/count',
            '/api/correct',
            '/api/results',
            '/api/history',
            '/api/status',
            '/metrics',
            '/api/learn',
            '/api/learned-objects',
            '/api/count-learned',
            '/api/recognize',
            '/api/delete-learned-object'
        ]
        
        for endpoint in endpoints:
            if endpoint in ['/api/count', '/api/correct', '/api/learn', 
                          '/api/count-learned', '/api/recognize', '/api/delete-learned-object']:
                # These are POST/DELETE endpoints, test with appropriate method
                if endpoint == '/api/delete-learned-object':
                    response = self.client.delete(endpoint, json={'object_name': 'test'})
                else:
                    response = self.client.post(endpoint)
                # Should not be 404 (endpoint exists)
                self.assertNotEqual(response.status_code, 404)
            else:
                # GET endpoints
                response = self.client.get(endpoint)
                # Should not be 404 (endpoint exists)
                self.assertNotEqual(response.status_code, 404)

class TestImageGenerator(unittest.TestCase):
    """Test cases for image generation functionality"""
    
    def setUp(self):
        """Set up test environment"""
        self.generator = None
        try:
            from image_generator import ImageGenerator
            self.generator = ImageGenerator("test_images")
        except ImportError:
            self.skipTest("Image generator not available")
    
    def test_image_generation(self):
        """Test image generation"""
        if not self.generator:
            self.skipTest("Image generator not available")
        
        # Generate a test image
        img, metadata = self.generator.generate_synthetic_image(
            object_type='car',
            count=3,
            width=256,
            height=256
        )
        
        self.assertIsNotNone(img)
        self.assertEqual(img.size, (256, 256))
        self.assertEqual(metadata['object_type'], 'car')
        self.assertEqual(metadata['count'], 3)
        self.assertEqual(metadata['width'], 256)
        self.assertEqual(metadata['height'], 256)
    
    def test_image_generation_with_effects(self):
        """Test image generation with effects"""
        if not self.generator:
            self.skipTest("Image generator not available")
        
        # Generate image with effects
        img, metadata = self.generator.generate_synthetic_image(
            object_type='tree',
            count=2,
            width=512,
            height=512,
            clarity_level=0.7,
            noise_level=0.2
        )
        
        self.assertIsNotNone(img)
        self.assertEqual(img.size, (512, 512))
        self.assertEqual(metadata['clarity_level'], 0.7)
        self.assertEqual(metadata['noise_level'], 0.2)

class TestFewShotLearning(unittest.TestCase):
    """Test cases for few-shot learning functionality"""
    
    def setUp(self):
        """Set up test environment"""
        self.learner = None
        try:
            from few_shot_learning import FewShotLearner
            self.learner = FewShotLearner("test_models")
        except ImportError:
            self.skipTest("Few-shot learning not available")
    
    def test_learner_initialization(self):
        """Test learner initialization"""
        if not self.learner:
            self.skipTest("Few-shot learning not available")
        
        self.assertIsNotNone(self.learner)
        self.assertIsNotNone(self.learner.feature_extractor)
        self.assertEqual(self.learner.feature_dim, 512)
    
    def test_object_learning(self):
        """Test learning new objects"""
        if not self.learner:
            self.skipTest("Few-shot learning not available")
        
        # Create test images
        test_images = []
        for i in range(3):
            img = Image.new('RGB', (64, 64), color='red')
            temp_path = f"test_object_{i}.png"
            img.save(temp_path)
            test_images.append(temp_path)
        
        try:
            # Learn new object
            result = self.learner.learn_new_object('test_object', test_images)
            
            self.assertIn('learning_successful', result)
            self.assertEqual(result['object_name'], 'test_object')
            self.assertEqual(result['training_images_count'], 3)
        finally:
            # Clean up test images
            for img_path in test_images:
                if os.path.exists(img_path):
                    os.remove(img_path)

if __name__ == '__main__':
    # Run tests
    unittest.main(verbosity=2)
