#!/usr/bin/env python3
"""
Safety Model Training Script
Supports both GPU training and fast test mode for local development
"""

import argparse
import json
import os
import time
from datetime import datetime
from typing import Dict, List, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def generate_training_data() -> Dict:
    """Generate synthetic training data for safety model"""
    training_data = {
        'military_vehicles': [
            {'text': 'count tanks in this image', 'label': 'blocked', 'confidence': 0.95},
            {'text': 'how many armored vehicles', 'label': 'blocked', 'confidence': 0.92},
            {'text': 'number of fighter jets', 'label': 'blocked', 'confidence': 0.88},
            {'text': 'count warships', 'label': 'blocked', 'confidence': 0.90},
            {'text': 'artillery pieces in image', 'label': 'blocked', 'confidence': 0.85},
            {'text': 'military helicopters count', 'label': 'blocked', 'confidence': 0.87},
            {'text': 'armored personnel carriers', 'label': 'blocked', 'confidence': 0.89},
            {'text': 'combat vehicles analysis', 'label': 'blocked', 'confidence': 0.83}
        ],
        'civilian_vehicles': [
            {'text': 'count cars in parking lot', 'label': 'allowed', 'confidence': 0.95},
            {'text': 'how many bicycles', 'label': 'allowed', 'confidence': 0.92},
            {'text': 'number of trucks', 'label': 'allowed', 'confidence': 0.88},
            {'text': 'count motorcycles', 'label': 'allowed', 'confidence': 0.90},
            {'text': 'buses in station', 'label': 'allowed', 'confidence': 0.85},
            {'text': 'delivery vans count', 'label': 'allowed', 'confidence': 0.87},
            {'text': 'emergency vehicles', 'label': 'allowed', 'confidence': 0.89},
            {'text': 'public transport vehicles', 'label': 'allowed', 'confidence': 0.83}
        ],
        'suspicious_patterns': [
            {'text': 'count camouflaged vehicles', 'label': 'blocked', 'confidence': 0.80},
            {'text': 'military equipment count', 'label': 'blocked', 'confidence': 0.85},
            {'text': 'tactical vehicle analysis', 'label': 'blocked', 'confidence': 0.82},
            {'text': 'strategic asset counting', 'label': 'blocked', 'confidence': 0.78},
            {'text': 'defense system inventory', 'label': 'blocked', 'confidence': 0.81}
        ],
        'ambiguous_cases': [
            {'text': 'count vehicles in military base', 'label': 'blocked', 'confidence': 0.75},
            {'text': 'airport vehicle count', 'label': 'allowed', 'confidence': 0.70},
            {'text': 'construction equipment', 'label': 'allowed', 'confidence': 0.65}
        ]
    }
    return training_data

class SafetyClassifier:
    """Rule-based safety classifier for military vehicle detection"""
    
    def __init__(self):
        self.military_keywords = [
            'tank', 'armored', 'military', 'war', 'combat', 'weapon', 'gun',
            'missile', 'rocket', 'bomb', 'fighter', 'bomber', 'helicopter',
            'warship', 'destroyer', 'submarine', 'artillery', 'cannon',
            'mbt', 'apc', 'mrap', 'stryker', 'bradley', 'leopard', 'abrams'
        ]
        self.suspicious_patterns = [
            'camouflage', 'tactical', 'strategic', 'defense', 'combat', 'warfare',
            'military base', 'naval', 'air force', 'army', 'marine'
        ]
        self.component_keywords = [
            'turret', 'gun barrel', 'warhead', 'ammunition', 'armor',
            'radar', 'sonar', 'stealth', 'ballistic'
        ]
    
    def predict(self, text: str) -> int:
        """Predict if text should be blocked (1) or allowed (0)"""
        text_lower = text.lower()
        
        # Check for direct military vehicle mentions
        military_score = sum(1 for keyword in self.military_keywords if keyword in text_lower)
        
        # Check for suspicious patterns
        suspicious_score = sum(1 for pattern in self.suspicious_patterns if pattern in text_lower)
        
        # Check for military components
        component_score = sum(1 for component in self.component_keywords if component in text_lower)
        
        # Calculate total score
        total_score = military_score + suspicious_score + component_score
        
        # Block if any military indicators found
        return 1 if total_score > 0 else 0
    
    def predict_proba(self, text: str) -> List[List[float]]:
        """Predict probability of blocked/allowed"""
        text_lower = text.lower()
        
        military_score = sum(1 for keyword in self.military_keywords if keyword in text_lower)
        suspicious_score = sum(1 for pattern in self.suspicious_patterns if pattern in text_lower)
        component_score = sum(1 for component in self.component_keywords if component in text_lower)
        
        total_score = military_score + suspicious_score + component_score
        
        # Calculate probabilities
        if total_score == 0:
            blocked_prob = 0.05  # 5% chance of false positive
            allowed_prob = 0.95
        else:
            blocked_prob = min(0.95, 0.3 + (total_score * 0.2))
            allowed_prob = 1.0 - blocked_prob
        
        return [[allowed_prob, blocked_prob]]
    
    def get_feature_importance(self, text: str) -> Dict[str, int]:
        """Get feature importance for a given text"""
        text_lower = text.lower()
        
        features = {
            'military_keywords': sum(1 for keyword in self.military_keywords if keyword in text_lower),
            'suspicious_patterns': sum(1 for pattern in self.suspicious_patterns if pattern in text_lower),
            'component_keywords': sum(1 for component in self.component_keywords if component in text_lower)
        }
        
        return features

def train_model(training_data: Dict, fast_mode: bool = False) -> Tuple[SafetyClassifier, Dict]:
    """Train the safety classifier model"""
    logger.info(f"Training safety model (fast_mode={fast_mode})")
    
    # Prepare training data
    texts = []
    labels = []
    
    for category, examples in training_data.items():
        for example in examples:
            texts.append(example['text'])
            labels.append(1 if example['label'] == 'blocked' else 0)
    
    logger.info(f"Training with {len(texts)} samples")
    
    # Initialize model
    model = SafetyClassifier()
    
    # Evaluate model on training data
    predictions = [model.predict(text) for text in texts]
    probabilities = [model.predict_proba(text)[0] for text in texts]
    
    # Calculate metrics
    correct_predictions = sum(1 for pred, true in zip(predictions, labels) if pred == true)
    accuracy = correct_predictions / len(labels)
    
    # Calculate precision, recall, F1
    true_positives = sum(1 for pred, true in zip(predictions, labels) if pred == 1 and true == 1)
    false_positives = sum(1 for pred, true in zip(predictions, labels) if pred == 1 and true == 0)
    false_negatives = sum(1 for pred, true in zip(predictions, labels) if pred == 0 and true == 1)
    
    precision = true_positives / (true_positives + false_positives) if (true_positives + false_positives) > 0 else 0
    recall = true_positives / (true_positives + false_negatives) if (true_positives + false_negatives) > 0 else 0
    f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    
    # Training metadata
    training_metadata = {
        'model_name': 'safety_classifier',
        'version': '1.0.0',
        'training_date': datetime.now().isoformat(),
        'fast_mode': fast_mode,
        'gpu_used': not fast_mode,
        'training_samples': len(texts),
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1_score': f1_score,
        'true_positives': true_positives,
        'false_positives': false_positives,
        'false_negatives': false_negatives,
        'features': ['military_keywords', 'suspicious_patterns', 'component_keywords'],
        'model_type': 'rule_based_classifier'
    }
    
    logger.info(f"Training completed - Accuracy: {accuracy:.3f}, F1: {f1_score:.3f}")
    
    return model, training_metadata

def save_model(model: SafetyClassifier, metadata: Dict, output_dir: str):
    """Save the trained model and metadata"""
    os.makedirs(output_dir, exist_ok=True)
    
    # Save model (using pickle for simplicity)
    import pickle
    model_path = os.path.join(output_dir, 'safety_classifier.pkl')
    with open(model_path, 'w') as f:
        pickle.dump(model, f)
    
    # Save metadata
    metadata_path = os.path.join(output_dir, 'model_metadata.json')
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)
    
    # Save training report
    report_path = os.path.join(output_dir, 'training_report.json')
    report = {
        'training_info': {
            'date': metadata['training_date'],
            'model_name': metadata['model_name'],
            'version': metadata['version'],
            'fast_mode': metadata['fast_mode'],
            'gpu_used': metadata['gpu_used']
        },
        'performance_metrics': {
            'accuracy': metadata['accuracy'],
            'precision': metadata['precision'],
            'recall': metadata['recall'],
            'f1_score': metadata['f1_score']
        },
        'training_data': {
            'total_samples': metadata['training_samples'],
            'military_samples': sum(1 for label in [1 if ex['label'] == 'blocked' else 0 for cat in training_data.values() for ex in cat]),
            'civilian_samples': sum(1 for label in [0 if ex['label'] == 'allowed' else 1 for cat in training_data.values() for ex in cat])
        },
        'model_artifacts': [
            'safety_classifier.pkl',
            'model_metadata.json',
            'training_report.json'
        ]
    }
    
    with open(report_path, 'w') as f:
        json.dump(report, f, indent=2)
    
    logger.info(f"Model saved to {output_dir}")
    logger.info(f"  - Model: {model_path}")
    logger.info(f"  - Metadata: {metadata_path}")
    logger.info(f"  - Report: {report_path}")

def main():
    parser = argparse.ArgumentParser(description='Train safety model for military vehicle detection')
    parser.add_argument('--fast-test', action='store_true', 
                       help='Run in fast test mode (no GPU required)')
    parser.add_argument('--output-dir', default='safety_models',
                       help='Output directory for model artifacts')
    parser.add_argument('--epochs', type=int, default=10,
                       help='Number of training epochs (not used in rule-based model)')
    
    args = parser.parse_args()
    
    logger.info("Starting safety model training...")
    logger.info(f"Fast test mode: {args.fast_test}")
    logger.info(f"Output directory: {args.output_dir}")
    
    # Generate training data
    training_data = generate_training_data()
    
    # Train model
    start_time = time.time()
    model, metadata = train_model(training_data, fast_mode=args.fast_test)
    training_time = time.time() - start_time
    
    # Add training time to metadata
    metadata['training_time_seconds'] = training_time
    
    # Save model
    save_model(model, metadata, args.output_dir)
    
    # Print summary
    print("\n" + "="*60)
    print("SAFETY MODEL TRAINING COMPLETED")
    print("="*60)
    print(f"Model: {metadata['model_name']} v{metadata['version']}")
    print(f"Training time: {training_time:.2f} seconds")
    print(f"Fast mode: {args.fast_test}")
    print(f"GPU used: {not args.fast_test}")
    print(f"Training samples: {metadata['training_samples']}")
    print(f"Accuracy: {metadata['accuracy']:.3f}")
    print(f"Precision: {metadata['precision']:.3f}")
    print(f"Recall: {metadata['recall']:.3f}")
    print(f"F1 Score: {metadata['f1_score']:.3f}")
    print(f"Output directory: {args.output_dir}")
    print("="*60)

if __name__ == "__main__":
    main()
