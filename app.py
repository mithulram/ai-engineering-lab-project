from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from werkzeug.utils import secure_filename
import os
import uuid
from datetime import datetime
import logging
from model_pipeline import ObjectCounter

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-here'
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///object_counting.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Initialize extensions
CORS(app)
db = SQLAlchemy(app)

# Initialize AI model pipeline
object_counter = ObjectCounter()

# Database Models
class CountingResult(db.Model):
    id = db.Column(db.String(36), primary_key=True)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    image_path = db.Column(db.String(255), nullable=False)
    item_type = db.Column(db.String(100), nullable=False)
    predicted_count = db.Column(db.Integer, nullable=False)
    corrected_count = db.Column(db.Integer, nullable=True)
    confidence_score = db.Column(db.Float, nullable=True)
    processing_time = db.Column(db.Float, nullable=True)
    user_feedback = db.Column(db.Text, nullable=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'timestamp': self.timestamp.isoformat(),
            'image_path': self.image_path,
            'item_type': self.item_type,
            'predicted_count': self.predicted_count,
            'corrected_count': self.corrected_count,
            'confidence_score': self.confidence_score,
            'processing_time': self.processing_time,
            'user_feedback': self.user_feedback
        }

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Predefined object types (as specified in requirements)
OBJECT_TYPES = [
    "car", "cat", "tree", "dog", "building", 
    "person", "sky", "ground", "hardware"
]

@app.route('/api/count', methods=['POST'])
def count_objects():
    """
    API endpoint to upload an image and count objects of a specific type.
    
    Expected input:
    - image: image file (multipart/form-data)
    - item_type: string from predefined list
    
    Returns:
    - JSON response with count results
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
        
        # Process image with AI pipeline
        start_time = datetime.now()
        try:
            result = object_counter.count_objects(file_path, item_type)
            processing_time = (datetime.now() - start_time).total_seconds()
            
            # Create database record
            result_id = str(uuid.uuid4())
            db_result = CountingResult(
                id=result_id,
                image_path=file_path,
                item_type=item_type,
                predicted_count=result['count'],
                confidence_score=result.get('confidence', 0.0),
                processing_time=processing_time
            )
            
            db.session.add(db_result)
            db.session.commit()
            
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
    
    Expected input:
    - result_id: string (UUID of the result to correct)
    - corrected_count: integer (the correct count)
    - user_feedback: string (optional feedback)
    
    Returns:
    - JSON response with confirmation
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
        
        # Find the result in database
        db_result = CountingResult.query.get(result_id)
        if not db_result:
            return jsonify({'error': 'Result not found'}), 404
        
        # Update the result
        db_result.corrected_count = corrected_count
        db_result.user_feedback = user_feedback
        db.session.commit()
        
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
    
    Query parameters:
    - item_type: filter by object type (optional)
    - limit: number of results to return (optional, default 50)
    - offset: number of results to skip (optional, default 0)
    
    Returns:
    - JSON response with list of results
    """
    try:
        # Get query parameters
        item_type = request.args.get('item_type')
        limit = request.args.get('limit', 50, type=int)
        offset = request.args.get('offset', 0, type=int)
        
        # Build query
        query = CountingResult.query
        
        if item_type:
            if item_type not in OBJECT_TYPES:
                return jsonify({'error': f'Invalid item type: {item_type}'}), 400
            query = query.filter(CountingResult.item_type == item_type)
        
        # Order by timestamp (newest first) and apply pagination
        results = query.order_by(CountingResult.timestamp.desc()).offset(offset).limit(limit).all()
        
        # Convert to list of dictionaries
        results_list = [result.to_dict() for result in results]
        
        # Get total count for pagination info
        total_count = query.count()
        
        response = {
            'results': results_list,
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
        'service': 'AI Object Counting API'
    }), 200

@app.route('/api/status', methods=['GET'])
def status_check():
    """
    Status check endpoint for Flutter frontend compatibility.
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'AI Object Counting API (Real AI)'
    }), 200

@app.route('/api/history', methods=['GET'])
def get_history():
    """
    Get paginated history of counting results for Flutter frontend.
    """
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        
        # Query database with pagination
        results = CountingResult.query.order_by(CountingResult.timestamp.desc()).paginate(
            page=page,
            per_page=per_page,
            error_out=False
        )
        
        return jsonify({
            'results': [result.to_dict() for result in results.items],
            'page': page,
            'per_page': per_page,
            'total': results.total,
            'has_more': results.has_next
        }), 200
        
    except Exception as e:
        logger.error(f"Error in get_history: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    """
    Serve uploaded files (for development purposes).
    In production, use a proper file server or CDN.
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
    # Create database tables
    with app.app_context():
        db.create_all()
        logger.info("Database tables created")
    
    # Run the application
    app.run(debug=True, host='0.0.0.0', port=5001)
