#!/usr/bin/env python3
"""
Safety Module for AI Object Counting Application
Prevents counting of military vehicles and related components
"""

import json
import logging
import os
import time
import re
from typing import Dict, List, Tuple, Optional
from PIL import Image
import numpy as np
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
import torch

# Military keyword detection with word boundaries
MILITARY_KEYWORDS = {"tank","armored","armour","howitzer","turret","IFV","APC","artillery","armor"}
MILITARY_RE = re.compile(r'\b(' + r'|'.join(re.escape(k) for k in MILITARY_KEYWORDS) + r')\b', flags=re.I)

def contains_military_keyword(text: str) -> bool:
    return bool(MILITARY_RE.search(text or ""))

DEFAULT_MILITARY_PROB_BLOCK = float(os.getenv('MILITARY_BLOCK_THRESH', 0.65))
DEFAULT_TURRET_SCORE_THRESH = float(os.getenv('TURRET_SCORE_THRESH', 0.45))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SafetyViolation:
    """Represents a safety violation with evidence"""
    def __init__(self, violation_type: str, reason: str, confidence: float, evidence: Dict):
        self.violation_type = violation_type
        self.reason = reason
        self.confidence = confidence
        self.evidence = evidence
        self.timestamp = time.time()

class SafetyModule:
    """Safety module to detect and prevent military vehicle counting"""
    
    def __init__(self):
        """Initialize the safety module with classifiers and rules"""
        self.violations_log = []
        self.evidence_dir = "safety_evidence"
        os.makedirs(self.evidence_dir, exist_ok=True)
        
        # Military vehicle keywords and patterns
        self.military_vehicles = {
            'tanks': ['tank', 'mbt', 'main battle tank', 'armored vehicle', 'panzer', 'leopard', 'abrams'],
            'armored_trucks': ['armored truck', 'mrap', 'stryker', 'bradley', 'apc', 'armored personnel carrier'],
            'military_aircraft': ['fighter jet', 'bomber', 'helicopter', 'drone', 'uav', 'military aircraft'],
            'naval_vessels': ['warship', 'destroyer', 'frigate', 'submarine', 'battleship', 'cruiser'],
            'artillery': ['howitzer', 'cannon', 'mortar', 'rocket launcher', 'artillery piece']
        }
        
        # Suspicious patterns that might indicate military counting
        self.suspicious_patterns = {
            'camouflage': ['camouflage', 'camouflaged', 'military camo', 'desert camo', 'urban camo'],
            'military_components': ['turret', 'gun barrel', 'missile', 'rocket', 'bomb', 'warhead'],
            'counting_indicators': ['count tanks', 'how many vehicles', 'number of aircraft', 'vehicle count'],
            'military_terms': ['combat', 'warfare', 'military', 'defense', 'strategic', 'tactical']
        }
        
        # Initialize text classifier for military content detection
        try:
            self.text_classifier = pipeline(
                "text-classification",
                model="microsoft/DialoGPT-medium",
                return_all_scores=True
            )
            logger.info("Text classifier initialized successfully")
        except Exception as e:
            logger.warning(f"Could not initialize text classifier: {e}")
            self.text_classifier = None
        
        # Initialize image classifier for military vehicle detection
        try:
            self.image_classifier = pipeline(
                "image-classification",
                model="google/vit-base-patch16-224"
            )
            logger.info("Image classifier initialized successfully")
        except Exception as e:
            logger.warning(f"Could not initialize image classifier: {e}")
            self.image_classifier = None
    
    def check_text_safety(self, text: str) -> List[SafetyViolation]:
        """Check if text contains military vehicle counting requests"""
        violations = []
        text_lower = text.lower()
        
        # Use regex-based military keyword detection
        if contains_military_keyword(text):
            confidence = DEFAULT_MILITARY_PROB_BLOCK
            violation = SafetyViolation(
                violation_type="military_vehicle_detection",
                reason=f"Text contains military vehicle reference",
                confidence=confidence,
                evidence={
                    "text": text,
                    "detection_method": "regex_keyword_matching"
                }
            )
            violations.append(violation)
        
        # Check for suspicious patterns
        for pattern_type, patterns in self.suspicious_patterns.items():
            for pattern in patterns:
                if pattern in text_lower:
                    confidence = self._calculate_confidence(text_lower, pattern)
                    if confidence > DEFAULT_TURRET_SCORE_THRESH:
                        violation = SafetyViolation(
                            violation_type="suspicious_pattern",
                            reason=f"Text contains suspicious pattern: {pattern}",
                            confidence=confidence,
                            evidence={
                                "text": text,
                                "pattern": pattern,
                                "pattern_type": pattern_type,
                                "detection_method": "pattern_matching"
                            }
                        )
                        violations.append(violation)
        
        # Use ML classifier if available
        if self.text_classifier:
            try:
                results = self.text_classifier(text)
                # Check if any classification suggests military content
                for result in results:
                    if 'military' in result['label'].lower() or 'war' in result['label'].lower():
                        if result['score'] > 0.7:
                            violation = SafetyViolation(
                                violation_type="ml_classification",
                                reason=f"ML classifier detected military content: {result['label']}",
                                confidence=result['score'],
                                evidence={
                                    "text": text,
                                    "classification": result,
                                    "detection_method": "ml_classifier"
                                }
                            )
                            violations.append(violation)
            except Exception as e:
                logger.warning(f"ML text classification failed: {e}")
        
        return violations
    
    def check_image_safety(self, image_path: str) -> List[SafetyViolation]:
        """Check if image contains military vehicles"""
        violations = []
        
        try:
            # Load and analyze image
            image = Image.open(image_path)
            
            # Use ML classifier if available
            if self.image_classifier:
                try:
                    results = self.image_classifier(image)
                    for result in results:
                        # Check for military-related classifications
                        if self._is_military_related(result['label']):
                            if result['score'] > 0.7:
                                violation = SafetyViolation(
                                    violation_type="military_image_detection",
                                    reason=f"Image classified as military content: {result['label']}",
                                    confidence=result['score'],
                                    evidence={
                                        "image_path": image_path,
                                        "classification": result,
                                        "detection_method": "ml_image_classifier"
                                    }
                                )
                                violations.append(violation)
                except Exception as e:
                    logger.warning(f"ML image classification failed: {e}")
            
            # Basic image analysis for military characteristics
            military_indicators = self._analyze_image_characteristics(image)
            for indicator, confidence in military_indicators.items():
                if confidence > 0.6:
                    violation = SafetyViolation(
                        violation_type="image_characteristics",
                        reason=f"Image shows military characteristics: {indicator}",
                        confidence=confidence,
                        evidence={
                            "image_path": image_path,
                            "indicator": indicator,
                            "detection_method": "image_analysis"
                        }
                    )
                    violations.append(violation)
        
        except Exception as e:
            logger.error(f"Error analyzing image {image_path}: {e}")
        
        return violations
    
    def _is_military_related(self, label: str) -> bool:
        """Check if a classification label is military-related"""
        military_terms = [
            'tank', 'armored', 'military', 'war', 'combat', 'weapon', 'gun',
            'missile', 'rocket', 'bomb', 'fighter', 'bomber', 'helicopter',
            'warship', 'destroyer', 'submarine', 'artillery', 'cannon'
        ]
        label_lower = label.lower()
        return any(term in label_lower for term in military_terms)
    
    def _analyze_image_characteristics(self, image: Image.Image) -> Dict[str, float]:
        """Analyze image for military characteristics"""
        indicators = {}
        
        try:
            # Convert to numpy array for analysis
            img_array = np.array(image)
            
            # Check for camouflage patterns (green/brown color dominance)
            if len(img_array.shape) == 3:
                # Calculate color distribution
                green_ratio = np.mean(img_array[:, :, 1]) / 255.0
                brown_ratio = np.mean((img_array[:, :, 0] + img_array[:, :, 2]) / 2) / 255.0
                
                if green_ratio > 0.4 and brown_ratio > 0.3:
                    indicators['camouflage_pattern'] = min(0.8, (green_ratio + brown_ratio) / 2)
            
            # Check for angular/geometric shapes (common in military vehicles)
            # This is a simplified check - in practice, you'd use more sophisticated computer vision
            gray = np.mean(img_array, axis=2) if len(img_array.shape) == 3 else img_array
            edges = np.abs(np.diff(gray, axis=1)) + np.abs(np.diff(gray, axis=0))
            edge_density = np.mean(edges > 30)  # Threshold for edge detection
            
            if edge_density > 0.1:  # High edge density might indicate geometric shapes
                indicators['geometric_shapes'] = min(0.7, edge_density * 5)
        
        except Exception as e:
            logger.warning(f"Image analysis failed: {e}")
        
        return indicators
    
    def _calculate_confidence(self, text: str, keyword: str) -> float:
        """Calculate confidence score for keyword detection"""
        # Simple confidence calculation based on context
        keyword_count = text.count(keyword)
        text_length = len(text.split())
        
        # Higher confidence for multiple occurrences or shorter text
        base_confidence = min(0.95, 0.6 + (keyword_count * 0.2))
        length_factor = max(0.3, 1.0 - (text_length / 200.0))
        
        return min(0.95, base_confidence * length_factor)
    
    def log_violation(self, violation: SafetyViolation, image_path: Optional[str] = None):
        """Log a safety violation with evidence"""
        self.violations_log.append(violation)
        
        # Create evidence file
        evidence_data = {
            "violation_type": violation.violation_type,
            "reason": violation.reason,
            "confidence": violation.confidence,
            "timestamp": violation.timestamp,
            "evidence": violation.evidence
        }
        
        if image_path:
            evidence_data["image_path"] = image_path
        
        # Save evidence JSON
        evidence_file = os.path.join(
            self.evidence_dir,
            f"violation_{int(violation.timestamp)}_{violation.violation_type}.json"
        )
        
        try:
            with open(evidence_file, 'w') as f:
                json.dump(evidence_data, f, indent=2)
            logger.info(f"Safety violation logged: {evidence_file}")
        except Exception as e:
            logger.error(f"Failed to save evidence: {e}")
    
    def get_violation_stats(self) -> Dict:
        """Get statistics about safety violations"""
        if not self.violations_log:
            return {"total_violations": 0, "violation_types": {}}
        
        stats = {
            "total_violations": len(self.violations_log),
            "violation_types": {},
            "recent_violations": []
        }
        
        # Count by violation type
        for violation in self.violations_log:
            if violation.violation_type not in stats["violation_types"]:
                stats["violation_types"][violation.violation_type] = 0
            stats["violation_types"][violation.violation_type] += 1
        
        # Get recent violations (last 10)
        recent = sorted(self.violations_log, key=lambda x: x.timestamp, reverse=True)[:10]
        stats["recent_violations"] = [
            {
                "type": v.violation_type,
                "reason": v.reason,
                "confidence": v.confidence,
                "timestamp": v.timestamp
            }
            for v in recent
        ]
        
        return stats

# Global safety module instance
safety_module = SafetyModule()
