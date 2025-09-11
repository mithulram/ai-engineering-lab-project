# DISABLED - Simple Flask app for testing without heavy AI dependencies.
# This file is disabled in favor of the real AI pipeline in app.py.
# 
# DO NOT USE THIS FILE - Use app.py instead for the real AI implementation.

'''
# ENTIRE FILE COMMENTED OUT - SIMPLE API DISABLED

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import uuid
from datetime import datetime
import logging
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-here'
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Initialize extensions
CORS(app)

# In-memory storage for demo (replace with database in production)
results_storage = {}

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Predefined object types (as specified in requirements)
OBJECT_TYPES = [
    "car", "cat", "tree", "dog", "building", 
    "person", "sky", "ground", "hardware"
]

# Mock AI processing function (replace with real AI pipeline)
def mock_count_objects(image_path, item_type):
    """
    Mock function that simulates AI object counting.
    In production, this would call the real model_pipeline.ObjectCounter
    """
    import random
    import time
    
    # Simulate processing time
    time.sleep(random.uniform(1, 3))
    
    # Generate realistic mock results
    count = random.randint(0, 8)
    confidence = random.uniform(0.6, 0.95)
    
    return {
        'count': count,
        'confidence': confidence,
        'details': {
            'total_segments': random.randint(5, 15),
            'target_type': item_type,
            'processing_method': 'Mock AI Pipeline (SAM + ResNet-50 + DistilBERT)'
        }
    }

@app.route('/api/count', methods=['POST'])
def count_objects():
    """
    API endpoint to upload an image and count objects of a specific type.
    """
    try:
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No image file selected'}), 400
        
        # Check if item_type is provided
        item_type = request.form.get('item_type')
        if not item_type:
            return jsonify({'error': 'No item type specified'}), 400
        
        # Validate item_type
        if item_type not in OBJECT_TYPES:
            return jsonify({
                'error': f'Invalid item type. Must be one of: {OBJECT_TYPES}'
            }), 400
        
        # Validate file type
        if not allowed_file(file.filename):
            return jsonify({
                'error': f'Invalid file type. Allowed types: {list(ALLOWED_EXTENSIONS)}'
            }), 400
        
        # Generate unique filename
        file_extension = file.filename.rsplit('.', 1)[1].lower()
        unique_filename = f"{uuid.uuid4()}.{file_extension}"
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        
        # Save file
        file.save(file_path)
        logger.info(f"Image saved: {file_path}")
        
        # Process image with AI pipeline (mock for now)
        start_time = datetime.now()
        try:
            result = mock_count_objects(file_path, item_type)
            processing_time = (datetime.now() - start_time).total_seconds()
            
            # Create result record
            result_id = str(uuid.uuid4())
            result_data = {
                'id': result_id,
                'timestamp': datetime.utcnow().isoformat(),
                'image_path': file_path,
                'item_type': item_type,
                'predicted_count': result['count'],
                'confidence_score': result.get('confidence', 0.0),
                'processing_time': processing_time,
                'corrected_count': None,
                'user_feedback': None,
                'details': result.get('details', {})
            }
            
            # Store in memory
            results_storage[result_id] = result_data
            
            # Return response
            response = {
                'id': result_id,
                'count': result['count'],
                'confidence_score': result.get('confidence', 0.0),
                'processing_time': processing_time,
                'item_type': item_type,
                'image_path': file_path,
                'details': result.get('details', {})
            }
            
            logger.info(f"Object counting completed: {response}")
            return jsonify(response), 200
            
        except Exception as e:
            logger.error(f"Error processing image: {str(e)}")
            return jsonify({'error': f'Error processing image: {str(e)}'}), 500
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/correct', methods=['POST'])
def correct_count():
    """
    API endpoint to submit corrections for count results.
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        result_id = data.get('result_id')
        corrected_count = data.get('corrected_count')
        user_feedback = data.get('user_feedback', '')
        
        # Validate required fields
        if not result_id:
            return jsonify({'error': 'result_id is required'}), 400
        
        if corrected_count is None or not isinstance(corrected_count, int):
            return jsonify({'error': 'corrected_count must be an integer'}), 400
        
        # Find the result in storage
        if result_id not in results_storage:
            return jsonify({'error': 'Result not found'}), 404
        
        # Update the result
        results_storage[result_id]['corrected_count'] = corrected_count
        results_storage[result_id]['user_feedback'] = user_feedback
        
        logger.info(f"Count corrected: {result_id} -> {corrected_count}")
        
        return jsonify({
            'message': 'Count corrected successfully',
            'result_id': result_id,
            'corrected_count': corrected_count
        }), 200
        
    except Exception as e:
        logger.error(f"Error correcting count: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/results', methods=['GET'])
def get_results():
    """
    API endpoint to retrieve previous counting results.
    """
    try:
        # Get query parameters
        item_type = request.args.get('item_type')
        limit = request.args.get('limit', 50, type=int)
        offset = request.args.get('offset', 0, type=int)
        
        # Filter results
        filtered_results = list(results_storage.values())
        
        if item_type:
            if item_type not in OBJECT_TYPES:
                return jsonify({'error': f'Invalid item type: {item_type}'}), 400
            filtered_results = [r for r in filtered_results if r['item_type'] == item_type]
        
        # Sort by timestamp (newest first)
        filtered_results.sort(key=lambda x: x['timestamp'], reverse=True)
        
        # Apply pagination
        total_count = len(filtered_results)
        paginated_results = filtered_results[offset:offset + limit]
        
        response = {
            'results': paginated_results,
            'pagination': {
                'total': total_count,
                'limit': limit,
                'offset': offset,
                'has_more': offset + limit < total_count
            }
        }
        
        return jsonify(response), 200
        
    except Exception as e:
        logger.error(f"Error retrieving results: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/api/health', methods=['GET'])
def health_check():
    """
    Health check endpoint to verify the service is running.
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'AI Object Counting API (Mock Mode)',
        'note': 'Using mock AI pipeline for demonstration'
    }), 200

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    """
    Serve uploaded files (for development purposes).
    """
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

@app.errorhandler(413)
def too_large(e):
    return jsonify({'error': 'File too large. Maximum size is 16MB'}), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    logger.info("Starting AI Object Counting API in Mock Mode")
    logger.info("Note: Using mock AI pipeline for demonstration purposes")
    
    # Run the application
    app.run(debug=True, host='0.0.0.0', port=5001)

'''
