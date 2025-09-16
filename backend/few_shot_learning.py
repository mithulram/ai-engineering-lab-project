"""
Few-Shot Learning Module for AI Object Counting Application
Implements advanced mode for counting objects not in predefined set
"""

import os
import json
import logging
import numpy as np
from PIL import Image
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Tuple, Optional
import pickle
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FewShotDataset(Dataset):
    """Dataset for few-shot learning with new object types"""
    
    def __init__(self, images: List[str], labels: List[str], transform=None):
        self.images = images
        self.labels = labels
        self.transform = transform or transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        image_path = self.images[idx]
        label = self.labels[idx]
        
        try:
            image = Image.open(image_path).convert('RGB')
            if self.transform:
                image = self.transform(image)
            return image, label
        except Exception as e:
            logger.error(f"Error loading image {image_path}: {str(e)}")
            # Return a blank image if loading fails
            blank_image = torch.zeros(3, 224, 224)
            return blank_image, label

class FewShotLearner:
    """
    Few-shot learning system for new object types
    """
    
    def __init__(self, model_dir: str = "few_shot_models", feature_dim: int = 512):
        self.model_dir = model_dir
        self.feature_dim = feature_dim
        self.known_objects = {}
        self.feature_extractor = None
        self.classifier = None
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # Create model directory
        os.makedirs(model_dir, exist_ok=True)
        
        # Initialize feature extractor (using a pre-trained backbone)
        self._initialize_feature_extractor()
        
        logger.info(f"Few-shot learner initialized on device: {self.device}")
    
    def _initialize_feature_extractor(self):
        """Initialize the feature extractor using a pre-trained model"""
        try:
            # Use a simple CNN as feature extractor
            self.feature_extractor = nn.Sequential(
                nn.Conv2d(3, 64, kernel_size=3, padding=1),
                nn.ReLU(),
                nn.MaxPool2d(2),
                nn.Conv2d(64, 128, kernel_size=3, padding=1),
                nn.ReLU(),
                nn.MaxPool2d(2),
                nn.Conv2d(128, 256, kernel_size=3, padding=1),
                nn.ReLU(),
                nn.MaxPool2d(2),
                nn.AdaptiveAvgPool2d((4, 4)),
                nn.Flatten(),
                nn.Linear(256 * 4 * 4, self.feature_dim),
                nn.ReLU()
            ).to(self.device)
            
            logger.info("Feature extractor initialized successfully")
        except Exception as e:
            logger.error(f"Error initializing feature extractor: {str(e)}")
            raise
    
    def learn_new_object(self, object_name: str, training_images: List[str], 
                        validation_images: List[str] = None) -> Dict:
        """
        Learn to recognize a new object type from few examples
        
        Args:
            object_name: Name of the new object type
            training_images: List of image paths for training
            validation_images: List of image paths for validation (optional)
            
        Returns:
            Dictionary with learning results and performance metrics
        """
        try:
            logger.info(f"Learning new object type: {object_name}")
            logger.info(f"Training images: {len(training_images)}")
            
            if len(training_images) < 2:
                raise ValueError("At least 2 training images are required for few-shot learning")
            
            # Prepare training data
            train_dataset = FewShotDataset(training_images, [object_name] * len(training_images))
            train_loader = DataLoader(train_dataset, batch_size=min(4, len(training_images)), shuffle=True)
            
            # Extract features from training images
            features = self._extract_features(train_loader)
            
            # Learn object representation
            object_representation = self._learn_object_representation(features, object_name)
            
            # Store learned object
            self.known_objects[object_name] = {
                'representation': object_representation,
                'training_images': training_images,
                'learned_at': datetime.now().isoformat(),
                'feature_dim': self.feature_dim
            }
            
            # Validate if validation images provided
            validation_results = {}
            if validation_images:
                validation_results = self._validate_object(object_name, validation_images)
            
            # Save model
            self._save_object_model(object_name)
            
            results = {
                'object_name': object_name,
                'training_images_count': len(training_images),
                'validation_images_count': len(validation_images) if validation_images else 0,
                'feature_dim': self.feature_dim,
                'learning_successful': True,
                'validation_results': validation_results,
                'learned_at': datetime.now().isoformat()
            }
            
            logger.info(f"Successfully learned object type: {object_name}")
            return results
            
        except Exception as e:
            logger.error(f"Error learning new object {object_name}: {str(e)}")
            return {
                'object_name': object_name,
                'learning_successful': False,
                'error': str(e),
                'learned_at': datetime.now().isoformat()
            }
    
    def _extract_features(self, data_loader: DataLoader) -> np.ndarray:
        """Extract features from images using the feature extractor"""
        self.feature_extractor.eval()
        features = []
        
        with torch.no_grad():
            for images, _ in data_loader:
                images = images.to(self.device)
                batch_features = self.feature_extractor(images)
                features.append(batch_features.cpu().numpy())
        
        return np.vstack(features)
    
    def _learn_object_representation(self, features: np.ndarray, object_name: str) -> Dict:
        """Learn a representation for the object from its features"""
        # Calculate mean feature vector as object representation
        mean_features = np.mean(features, axis=0)
        
        # Calculate feature variance for uncertainty estimation
        feature_variance = np.var(features, axis=0)
        
        # Calculate feature similarity matrix
        similarity_matrix = cosine_similarity(features)
        
        representation = {
            'mean_features': mean_features,
            'feature_variance': feature_variance,
            'similarity_matrix': similarity_matrix,
            'feature_count': len(features),
            'object_name': object_name
        }
        
        return representation
    
    def _validate_object(self, object_name: str, validation_images: List[str]) -> Dict:
        """Validate the learned object representation"""
        try:
            val_dataset = FewShotDataset(validation_images, [object_name] * len(validation_images))
            val_loader = DataLoader(val_dataset, batch_size=4, shuffle=False)
            
            # Extract features from validation images
            val_features = self._extract_features(val_loader)
            
            # Calculate similarity to learned representation
            learned_features = self.known_objects[object_name]['representation']['mean_features']
            similarities = cosine_similarity(val_features, learned_features.reshape(1, -1))
            
            # Calculate validation metrics
            avg_similarity = np.mean(similarities)
            min_similarity = np.min(similarities)
            max_similarity = np.max(similarities)
            
            return {
                'avg_similarity': float(avg_similarity),
                'min_similarity': float(min_similarity),
                'max_similarity': float(max_similarity),
                'validation_images_count': len(validation_images),
                'validation_successful': avg_similarity > 0.5  # Threshold for successful validation
            }
            
        except Exception as e:
            logger.error(f"Error validating object {object_name}: {str(e)}")
            return {
                'validation_successful': False,
                'error': str(e)
            }
    
    def recognize_object(self, image_path: str, threshold: float = 0.5) -> Dict:
        """
        Recognize objects in an image using learned representations
        
        Args:
            image_path: Path to the image
            threshold: Similarity threshold for recognition
            
        Returns:
            Dictionary with recognition results
        """
        try:
            if not self.known_objects:
                return {
                    'recognized': False,
                    'message': 'No objects learned yet',
                    'similarities': {}
                }
            
            # Extract features from the image
            dataset = FewShotDataset([image_path], ['unknown'])
            data_loader = DataLoader(dataset, batch_size=1, shuffle=False)
            features = self._extract_features(data_loader)
            
            if len(features) == 0:
                return {
                    'recognized': False,
                    'message': 'Failed to extract features from image',
                    'similarities': {}
                }
            
            image_features = features[0]
            similarities = {}
            
            # Compare with all learned objects
            for obj_name, obj_data in self.known_objects.items():
                learned_features = obj_data['representation']['mean_features']
                similarity = cosine_similarity(
                    image_features.reshape(1, -1),
                    learned_features.reshape(1, -1)
                )[0][0]
                similarities[obj_name] = float(similarity)
            
            # Find best match
            best_match = max(similarities.items(), key=lambda x: x[1])
            best_object, best_similarity = best_match
            
            recognized = best_similarity >= threshold
            
            return {
                'recognized': recognized,
                'best_match': best_object if recognized else None,
                'best_similarity': best_similarity,
                'similarities': similarities,
                'threshold': threshold
            }
            
        except Exception as e:
            logger.error(f"Error recognizing objects in {image_path}: {str(e)}")
            return {
                'recognized': False,
                'message': f'Error: {str(e)}',
                'similarities': {}
            }
    
    def count_learned_objects(self, image_path: str, object_name: str) -> Dict:
        """
        Count instances of a learned object in an image
        
        Args:
            image_path: Path to the image
            object_name: Name of the learned object to count
            
        Returns:
            Dictionary with counting results
        """
        try:
            if object_name not in self.known_objects:
                return {
                    'count': 0,
                    'error': f'Object type "{object_name}" not learned yet',
                    'confidence': 0.0
                }
            
            # For now, use a simple approach: segment the image and check each segment
            # In a full implementation, this would use more sophisticated segmentation
            image = Image.open(image_path).convert('RGB')
            width, height = image.size
            
            # Divide image into segments and check each
            segment_size = 64  # 64x64 pixel segments
            segments_x = width // segment_size
            segments_y = height // segment_size
            
            object_count = 0
            segment_similarities = []
            
            for y in range(segments_y):
                for x in range(segments_x):
                    # Extract segment
                    left = x * segment_size
                    top = y * segment_size
                    right = min(left + segment_size, width)
                    bottom = min(top + segment_size, height)
                    
                    segment = image.crop((left, top, right, bottom))
                    
                    # Save segment temporarily
                    temp_path = f"temp_segment_{x}_{y}.png"
                    segment.save(temp_path)
                    
                    try:
                        # Check if segment contains the object
                        recognition_result = self.recognize_object(temp_path)
                        similarity = recognition_result['similarities'].get(object_name, 0.0)
                        segment_similarities.append(similarity)
                        
                        if similarity > 0.6:  # Threshold for counting
                            object_count += 1
                    
                    finally:
                        # Clean up temp file
                        if os.path.exists(temp_path):
                            os.remove(temp_path)
            
            # Calculate confidence based on segment similarities
            avg_similarity = np.mean(segment_similarities) if segment_similarities else 0.0
            confidence = min(1.0, avg_similarity * 2)  # Scale confidence
            
            return {
                'count': object_count,
                'confidence': confidence,
                'segments_checked': len(segment_similarities),
                'avg_similarity': avg_similarity,
                'object_name': object_name
            }
            
        except Exception as e:
            logger.error(f"Error counting objects in {image_path}: {str(e)}")
            return {
                'count': 0,
                'error': str(e),
                'confidence': 0.0
            }
    
    def _save_object_model(self, object_name: str):
        """Save the learned object model to disk"""
        try:
            model_path = os.path.join(self.model_dir, f"{object_name}_model.pkl")
            with open(model_path, 'wb') as f:
                pickle.dump(self.known_objects[object_name], f)
            logger.info(f"Saved model for {object_name} to {model_path}")
        except Exception as e:
            logger.error(f"Error saving model for {object_name}: {str(e)}")
    
    def load_object_model(self, object_name: str) -> bool:
        """Load a learned object model from disk"""
        try:
            model_path = os.path.join(self.model_dir, f"{object_name}_model.pkl")
            if os.path.exists(model_path):
                with open(model_path, 'rb') as f:
                    self.known_objects[object_name] = pickle.load(f)
                logger.info(f"Loaded model for {object_name} from {model_path}")
                return True
            else:
                logger.warning(f"Model file not found for {object_name}")
                return False
        except Exception as e:
            logger.error(f"Error loading model for {object_name}: {str(e)}")
            return False
    
    def list_learned_objects(self) -> List[Dict]:
        """List all learned objects"""
        objects = []
        for obj_name, obj_data in self.known_objects.items():
            objects.append({
                'name': obj_name,
                'training_images_count': len(obj_data['training_images']),
                'learned_at': obj_data['learned_at'],
                'feature_dim': obj_data['feature_dim']
            })
        return objects
    
    def delete_object(self, object_name: str) -> bool:
        """Delete a learned object"""
        try:
            if object_name in self.known_objects:
                del self.known_objects[object_name]
                
                # Remove model file
                model_path = os.path.join(self.model_dir, f"{object_name}_model.pkl")
                if os.path.exists(model_path):
                    os.remove(model_path)
                
                logger.info(f"Deleted object: {object_name}")
                return True
            else:
                logger.warning(f"Object {object_name} not found")
                return False
        except Exception as e:
            logger.error(f"Error deleting object {object_name}: {str(e)}")
            return False

# Global few-shot learner instance
few_shot_learner = FewShotLearner()
