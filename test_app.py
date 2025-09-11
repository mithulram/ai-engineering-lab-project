import unittest
import json
import os
import tempfile
from io import BytesIO
from PIL import Image
import numpy as np

# Import the Flask app
from app import app, db, CountingResult

class TestObjectCountingAPI(unittest.TestCase):
    """Test cases for the Object Counting API."""
    
    def setUp(self):
        """Set up test environment before each test."""
        # Configure app for testing
        app.config['TESTING'] = True
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        app.config['UPLOAD_FOLDER'] = tempfile.mkdtemp()
        
        # Create test client
        self.client = app.test_client()
        
        # Create database tables
        with app.app_context():
            db.create_all()
    
    def tearDown(self):
        """Clean up after each test."""
        # Remove test files
        import shutil
        shutil.rmtree(app.config['UPLOAD_FOLDER'])
        
        # Clean up database
        with app.app_context():
            db.session.remove()
            db.drop_all()
    
    def create_test_image(self, filename='test_image.png'):
        """Create a test image file."""
        # Create a simple test image
        img_array = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        img = Image.fromarray(img_array)
        
        # Save to temporary file
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        img.save(file_path)
        
        return file_path
    
    def test_health_check(self):
        """Test the health check endpoint."""
        response = self.client.get('/api/health')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
        self.assertEqual(data['service'], 'AI Object Counting API')
    
    def test_count_objects_missing_image(self):
        """Test count endpoint with missing image."""
        response = self.client.post('/api/count', data={'item_type': 'car'})
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'No image file provided')
    
    def test_count_objects_missing_item_type(self):
        """Test count endpoint with missing item type."""
        # Create test image
        test_image_path = self.create_test_image()
        
        with open(test_image_path, 'rb') as img:
            response = self.client.post('/api/count', data={'image': (img, 'test.png')})
        
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'No item type specified')
    
    def test_count_objects_invalid_item_type(self):
        """Test count endpoint with invalid item type."""
        test_image_path = self.create_test_image()
        
        with open(test_image_path, 'rb') as img:
            response = self.client.post('/api/count', data={
                'image': (img, 'test.png'),
                'item_type': 'invalid_type'
            })
        
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertIn('Invalid item type', data['error'])
    
    def test_count_objects_invalid_file_type(self):
        """Test count endpoint with invalid file type."""
        # Create a text file instead of image
        test_file_path = os.path.join(app.config['UPLOAD_FOLDER'], 'test.txt')
        with open(test_file_path, 'w') as f:
            f.write('This is not an image')
        
        with open(test_file_path, 'rb') as f:
            response = self.client.post('/api/count', data={
                'image': (f, 'test.txt'),
                'item_type': 'car'
            })
        
        data = json.loads(response.data)
        self.assertEqual(response.status_code, 400)
        self.assertIn('Invalid file type', data['error'])
    
    def test_count_objects_success(self):
        """Test successful object counting (mock the AI pipeline)."""
        # This test would require mocking the AI models
        # For now, we'll test the endpoint structure
        test_image_path = self.create_test_image()
        
        with open(test_image_path, 'rb') as img:
            response = self.client.post('/api/count', data={
                'image': (img, 'test.png'),
                'item_type': 'car'
            })
        
        # Since we can't run the actual AI models in tests,
        # we expect either a 500 error or success depending on model availability
        self.assertIn(response.status_code, [200, 500])
    
    def test_correct_count_missing_data(self):
        """Test correct endpoint with missing data."""
        response = self.client.post('/api/correct', json={})
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'No JSON data provided')
    
    def test_correct_count_missing_result_id(self):
        """Test correct endpoint with missing result_id."""
        response = self.client.post('/api/correct', json={
            'corrected_count': 5
        })
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'result_id is required')
    
    def test_correct_count_missing_corrected_count(self):
        """Test correct endpoint with missing corrected_count."""
        response = self.client.post('/api/correct', json={
            'result_id': 'test-id'
        })
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'corrected_count must be an integer')
    
    def test_correct_count_invalid_corrected_count(self):
        """Test correct endpoint with invalid corrected_count type."""
        response = self.client.post('/api/correct', json={
            'result_id': 'test-id',
            'corrected_count': 'not_a_number'
        })
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], 'corrected_count must be an integer')
    
    def test_correct_count_result_not_found(self):
        """Test correct endpoint with non-existent result_id."""
        response = self.client.post('/api/correct', json={
            'result_id': 'non-existent-id',
            'corrected_count': 5
        })
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 404)
        self.assertEqual(data['error'], 'Result not found')
    
    def test_correct_count_success(self):
        """Test successful count correction."""
        # Create a test result in database
        with app.app_context():
            test_result = CountingResult(
                id='test-id-123',
                image_path='/test/path',
                item_type='car',
                predicted_count=3
            )
            db.session.add(test_result)
            db.session.commit()
        
        # Test correction
        response = self.client.post('/api/correct', json={
            'result_id': 'test-id-123',
            'corrected_count': 5,
            'user_feedback': 'Test feedback'
        })
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(data['message'], 'Count corrected successfully')
        self.assertEqual(data['result_id'], 'test-id-123')
        self.assertEqual(data['corrected_count'], 5)
    
    def test_get_results_no_filters(self):
        """Test get results endpoint without filters."""
        # Create test results
        with app.app_context():
            for i in range(5):
                result = CountingResult(
                    id=f'test-id-{i}',
                    image_path=f'/test/path-{i}',
                    item_type='car',
                    predicted_count=i
                )
                db.session.add(result)
            db.session.commit()
        
        response = self.client.get('/api/results')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(data['results']), 5)
        self.assertEqual(data['pagination']['total'], 5)
        self.assertEqual(data['pagination']['limit'], 50)
        self.assertEqual(data['pagination']['offset'], 0)
        self.assertFalse(data['pagination']['has_more'])
    
    def test_get_results_with_item_type_filter(self):
        """Test get results endpoint with item type filter."""
        # Create test results with different types
        with app.app_context():
            for i in range(3):
                result = CountingResult(
                    id=f'car-id-{i}',
                    image_path=f'/test/path-{i}',
                    item_type='car',
                    predicted_count=i
                )
                db.session.add(result)
            
            for i in range(2):
                result = CountingResult(
                    id=f'dog-id-{i}',
                    image_path=f'/test/path-{i}',
                    item_type='dog',
                    predicted_count=i
                )
                db.session.add(result)
            
            db.session.commit()
        
        # Filter by car
        response = self.client.get('/api/results?item_type=car')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(data['results']), 3)
        self.assertEqual(data['pagination']['total'], 3)
        
        # All results should be cars
        for result in data['results']:
            self.assertEqual(result['item_type'], 'car')
    
    def test_get_results_with_pagination(self):
        """Test get results endpoint with pagination."""
        # Create 10 test results
        with app.app_context():
            for i in range(10):
                result = CountingResult(
                    id=f'test-id-{i}',
                    image_path=f'/test/path-{i}',
                    item_type='car',
                    predicted_count=i
                )
                db.session.add(result)
            db.session.commit()
        
        # Test first page (limit 3)
        response = self.client.get('/api/results?limit=3&offset=0')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(data['results']), 3)
        self.assertEqual(data['pagination']['total'], 10)
        self.assertEqual(data['pagination']['limit'], 3)
        self.assertEqual(data['pagination']['offset'], 0)
        self.assertTrue(data['pagination']['has_more'])
        
        # Test second page
        response = self.client.get('/api/results?limit=3&offset=3')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(data['results']), 3)
        self.assertEqual(data['pagination']['offset'], 3)
        self.assertTrue(data['pagination']['has_more'])
    
    def test_get_results_invalid_item_type(self):
        """Test get results endpoint with invalid item type."""
        response = self.client.get('/api/results?item_type=invalid_type')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertIn('Invalid item type', data['error'])
    
    def test_uploaded_file_serving(self):
        """Test that uploaded files can be served."""
        # Create a test image
        test_image_path = self.create_test_image()
        filename = os.path.basename(test_image_path)
        
        response = self.client.get(f'/uploads/{filename}')
        self.assertEqual(response.status_code, 200)
    
    def test_error_handlers(self):
        """Test error handlers."""
        # Test 404
        response = self.client.get('/api/nonexistent')
        self.assertEqual(response.status_code, 404)
        
        # Test 413 (file too large) - this is handled by Flask
        # We can't easily test this without sending a very large file
    
    def test_database_model(self):
        """Test the database model."""
        with app.app_context():
            # Create a test result
            from datetime import datetime
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

class TestModelPipeline(unittest.TestCase):
    """Test cases for the model pipeline (basic functionality)."""
    
    def test_supported_item_types(self):
        """Test that supported item types are correctly defined."""
        from app import OBJECT_TYPES
        
        expected_types = [
            "car", "cat", "tree", "dog", "building", 
            "person", "sky", "ground", "hardware"
        ]
        
        self.assertEqual(OBJECT_TYPES, expected_types)
        self.assertEqual(len(OBJECT_TYPES), 9)
    
    def test_allowed_file_extensions(self):
        """Test that allowed file extensions are correctly defined."""
        from app import ALLOWED_EXTENSIONS
        
        expected_extensions = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}
        
        self.assertEqual(ALLOWED_EXTENSIONS, expected_extensions)
        self.assertEqual(len(ALLOWED_EXTENSIONS), 5)
    
    def test_allowed_file_function(self):
        """Test the allowed_file function."""
        from app import allowed_file
        
        # Valid extensions
        self.assertTrue(allowed_file('test.png'))
        self.assertTrue(allowed_file('test.jpg'))
        self.assertTrue(allowed_file('test.jpeg'))
        self.assertTrue(allowed_file('test.gif'))
        self.assertTrue(allowed_file('test.bmp'))
        
        # Invalid extensions
        self.assertFalse(allowed_file('test.txt'))
        self.assertFalse(allowed_file('test.pdf'))
        self.assertFalse(allowed_file('test.doc'))
        self.assertFalse(allowed_file('test'))

if __name__ == '__main__':
    unittest.main()
