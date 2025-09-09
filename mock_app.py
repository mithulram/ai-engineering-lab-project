# #!/usr/bin/env python3
# """
# DISABLED - Mock Flask app for GitLab CI testing without heavy AI dependencies.
# This file is disabled in favor of the real AI pipeline in app.py.
# 
# DO NOT USE THIS FILE - Use app.py instead for the real AI implementation.
# """
# 
# # THIS FILE IS DISABLED - ALL CODE COMMENTED OUT
# # Use app.py for the real AI pipeline implementation
# 
# '''
# # ENTIRE FILE COMMENTED OUT - MOCK API DISABLED
# 
# # from flask import Flask, request, jsonify
# # from flask_cors import CORS  
# # from flask_sqlalchemy import SQLAlchemy
# 
# import os
# import uuid
# from datetime import datetime
# import logging
# 
# # Configure logging
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)
# 
# # Initialize Flask app
# app = Flask(__name__)
# app.config["SECRET_KEY"] = "your-secret-key-here"
# app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
# app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
# app.config["UPLOAD_FOLDER"] = "uploads"
# app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024  # 16MB max file size
# 
# # Ensure upload directory exists
# os.makedirs(app.config["UPLOAD_FOLDER"], exist_ok=True)
# 
# # Initialize extensions
# CORS(app)
# db = SQLAlchemy(app)
# 
# 
# # Mock ObjectCounter class for testing
# class MockObjectCounter:
#     """Mock ObjectCounter that doesn't require heavy AI dependencies."""
# 
#     def __init__(self):
#         self.supported_types = [
#             "car",
#             "cat",
#             "tree",
#             "dog",
#             "building",
#             "person",
#             "sky",
#             "ground",
#             "hardware",
#         ]
# 
#     def count_objects(self, image_path, target_item_type):
#         """Mock object counting that returns a predictable result."""
#         if target_item_type not in self.supported_types:
#             raise ValueError(f"Unsupported item type: {target_item_type}")
# 
#         # Return mock results for testing
#         return {
#             "count": 3,
#             "confidence_score": 0.85,
#             "processing_time": 1.5,
#             "details": {"segments_found": 3, "model_confidence": 0.85},
#         }
# 
# 
# # Initialize mock AI model pipeline
# object_counter = MockObjectCounter()
# 
# 
# # Database Models
# class CountingResult(db.Model):
#     id = db.Column(db.String(36), primary_key=True)
#     timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
#     image_path = db.Column(db.String(255), nullable=False)
#     item_type = db.Column(db.String(100), nullable=False)
#     predicted_count = db.Column(db.Integer, nullable=False)
#     corrected_count = db.Column(db.Integer, nullable=True)
#     confidence_score = db.Column(db.Float, nullable=True)
#     processing_time = db.Column(db.Float, nullable=True)
#     user_feedback = db.Column(db.Text, nullable=True)
# 
#     def to_dict(self):
#         return {
#             "id": self.id,
#             "timestamp": self.timestamp.isoformat() if self.timestamp else None,
#             "image_path": self.image_path,
#             "item_type": self.item_type,
#             "predicted_count": self.predicted_count,
#             "corrected_count": self.corrected_count,
#             "confidence_score": self.confidence_score,
#             "processing_time": self.processing_time,
#             "user_feedback": self.user_feedback,
#         }
# 
# 
# # Allowed file extensions
# ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "gif", "bmp"}
# 
# 
# def allowed_file(filename):
#     return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS
# 
# 
# # Predefined object types (as specified in requirements)
# OBJECT_TYPES = [
#     "car",
#     "cat",
#     "tree",
#     "dog",
#     "building",
#     "person",
#     "sky",
#     "ground",
#     "hardware",
# ]
# 
# 
# @app.route("/api/health", methods=["GET"])
# def health_check():
#     """Health check endpoint."""
#     return jsonify(
#         {
#             "status": "healthy",
#             "service": "AI Object Counting API (Mock)",
#             "timestamp": datetime.utcnow().isoformat(),
#         }
#     )
# 
# 
# @app.route("/api/status", methods=["GET"])
# def status_check():
#     """Status check endpoint for Flutter frontend"""
#     return jsonify(
#         {
#             "status": "healthy",
#             "service": "AI Object Counting API (Mock)",
#             "timestamp": datetime.utcnow().isoformat(),
#         }
#     )
# 
# 
# @app.route("/api/history", methods=["GET"])
# def get_history():
#     """Get history endpoint for Flutter frontend"""
#     try:
#         page = request.args.get('page', 1, type=int)
#         per_page = request.args.get('per_page', 10, type=int)
#         
#         # Generate mock historical data
#         mock_results = []
#         total_items = 25  # Mock total
#         
#         # Calculate pagination
#         start_idx = (page - 1) * per_page
#         end_idx = min(start_idx + per_page, total_items)
#         
#         for i in range(start_idx, end_idx):
#             mock_results.append({
#                 "id": f"mock-{i+1}",
#                 "item_type": ["car", "cat", "tree", "dog", "person"][i % 5],
#                 "count": (i % 10) + 1,
#                 "confidence_score": 0.85 + (i % 15) * 0.01,
#                 "processing_time": 2.3 + (i % 5) * 0.5,
#                 "timestamp": datetime.utcnow().isoformat(),
#                 "image_path": f"mock_image_{i+1}.jpg"
#             })
#         
#         return jsonify({
#             "results": mock_results,
#             "page": page,
#             "per_page": per_page,
#             "total": total_items,
#             "has_more": end_idx < total_items
#         })
#         
#     except Exception as e:
#         logger.error(f"Error in get_history: {str(e)}")
#         return jsonify({"error": str(e)}), 500
# 
# 
# @app.route("/api/count", methods=["POST"])
# def count_objects():
#     """
#     Mock API endpoint to upload an image and count objects of a specific type.
#     """
#     try:
#         # Check if image file is present
#         if "image" not in request.files:
#             return jsonify({"error": "No image file provided"}), 400
# 
#         file = request.files["image"]
#         if file.filename == "":
#             return jsonify({"error": "No image file selected"}), 400
# 
#         # Check if item_type is provided
#         item_type = request.form.get("item_type")
#         if not item_type:
#             return jsonify({"error": "No item type specified"}), 400
# 
#         # Validate item_type
#         if item_type not in OBJECT_TYPES:
#             return (
#                 jsonify(
#                     {"error": f"Invalid item type. Must be one of: {OBJECT_TYPES}"}
#                 ),
#                 400,
#             )
# 
#         # Mock object counting
#         result = object_counter.count_objects("mock_image.jpg", item_type)
# 
#         # Create response
#         response_data = {
#             "id": str(uuid.uuid4()),
#             "count": result["count"],
#             "confidence_score": result["confidence_score"],
#             "processing_time": result["processing_time"],
#             "item_type": item_type,
#             "image_path": f"uploads/{file.filename}",
#             "details": result["details"],
#         }
# 
#         return jsonify(response_data), 200
# 
#     except Exception as e:
#         logger.error(f"Error in count_objects: {str(e)}")
#         return jsonify({"error": str(e)}), 500
# 
# 
# @app.route("/api/correct", methods=["POST"])
# def correct_count():
#     """
#     Mock API endpoint to correct the count provided by the user.
#     """
#     try:
#         data = request.get_json()
# 
#         if not data:
#             return jsonify({"error": "No data provided"}), 400
# 
#         result_id = data.get("result_id")
#         corrected_count = data.get("corrected_count")
#         user_feedback = data.get("user_feedback", "")
# 
#         if not result_id:
#             return jsonify({"error": "No result ID provided"}), 400
# 
#         if corrected_count is None:
#             return jsonify({"error": "No corrected count provided"}), 400
# 
#         # Mock correction response
#         response_data = {
#             "message": "Count corrected successfully",
#             "result_id": result_id,
#             "original_count": 3,
#             "corrected_count": corrected_count,
#             "user_feedback": user_feedback,
#             "timestamp": datetime.utcnow().isoformat(),
#         }
# 
#         return jsonify(response_data), 200
# 
#     except Exception as e:
#         logger.error(f"Error in correct_count: {str(e)}")
#         return jsonify({"error": str(e)}), 500
# 
# 
# @app.route("/api/results", methods=["GET"])
# def get_results():
#     """Mock endpoint to get counting results with pagination."""
#     try:
#         page = request.args.get('page', 1, type=int)
#         per_page = request.args.get('per_page', 10, type=int)
#         
#         # Generate mock results data
#         mock_results = []
#         total_items = 25  # Mock total
#         
#         # Calculate pagination
#         start_idx = (page - 1) * per_page
#         end_idx = min(start_idx + per_page, total_items)
#         
#         for i in range(start_idx, end_idx):
#             mock_results.append({
#                 "id": f"result-{i+1}",
#                 "item_type": ["car", "cat", "tree", "dog", "person"][i % 5],
#                 "count": (i % 10) + 1,
#                 "confidence_score": 0.85 + (i % 15) * 0.01,
#                 "processing_time": 2.3 + (i % 5) * 0.5,
#                 "timestamp": datetime.utcnow().isoformat(),
#                 "image_path": f"result_image_{i+1}.jpg"
#             })
#         
#         return jsonify({
#             "results": mock_results,
#             "page": page,
#             "per_page": per_page,
#             "total": total_items,
#             "has_more": end_idx < total_items
#         })
#         
#     except Exception as e:
#         logger.error(f"Error in get_results: {str(e)}")
#         return jsonify({"error": str(e)}), 500
# 
# 
# if __name__ == "__main__":
#     with app.app_context():
#         db.create_all()
#     app.run(debug=True, host="0.0.0.0", port=5001)
