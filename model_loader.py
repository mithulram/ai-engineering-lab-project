#!/usr/bin/env python3
"""
Lazy Model Loader for AI Object Counting Application
Provides memory-safe model loading with fallback mechanisms
"""

import os
import logging
import torch

logger = logging.getLogger(__name__)


class LazyModelLoader:
    """Lazy loader for AI models with memory-safe initialization"""

    def __init__(self):
        self.models = {}
        self.local_low_memory = os.getenv("LOCAL_LOW_MEMORY", "1") == "1"
        self.device = "cuda" if torch.cuda.is_available() and not self.local_low_memory else "cpu"

        logger.info(
            f"LazyModelLoader initialized - Low memory mode: {self.local_low_memory}, "
            f"Device: {self.device}"
        )

    def get_sam_model(self):
        """Get SAM model with lazy loading"""
        if "sam" not in self.models:
            try:
                if self.local_low_memory:
                    logger.info("Loading lightweight SAM model for low memory mode...")
                    # Use a smaller SAM variant or skip heavy initialization
                    self.models["sam"] = self._load_lightweight_sam()
                else:
                    logger.info("Loading full SAM model...")
                    self.models["sam"] = self._load_full_sam()
            except Exception as e:
                logger.error(f"Failed to load SAM model: {e}")
                self.models["sam"] = None

        return self.models["sam"]

    def get_classification_models(self):
        """Get classification models with lazy loading"""
        if "classification" not in self.models:
            try:
                if self.local_low_memory:
                    logger.info("Loading lightweight classification models...")
                    self.models["classification"] = self._load_lightweight_classification()
                else:
                    logger.info("Loading full classification models...")
                    self.models["classification"] = self._load_full_classification()
            except Exception as e:
                logger.error(f"Failed to load classification models: {e}")
                self.models["classification"] = None

        return self.models["classification"]

    def get_safety_models(self):
        """Get safety models with lazy loading"""
        if "safety" not in self.models:
            try:
                logger.info("Loading safety models...")
                self.models["safety"] = self._load_safety_models()
            except Exception as e:
                logger.error(f"Failed to load safety models: {e}")
                self.models["safety"] = None

        return self.models["safety"]

    def _load_lightweight_sam(self):
        """Load lightweight SAM model for low memory mode"""

        # Return a mock SAM model for testing
        class MockSAM:
            def __init__(self):
                self.device = self.device
                logger.info("Mock SAM model loaded (low memory mode)")

            def predict(self, *args, **kwargs):
                # Return mock predictions
                return {"masks": [], "scores": []}

        return MockSAM()

    def _load_full_sam(self):
        """Load full SAM model"""
        try:
            from segment_anything import sam_model_registry, SamPredictor

            # Load SAM model
            sam_checkpoint = "sam_vit_b_01ec64.pth"
            model_type = "vit_b"

            if not os.path.exists(sam_checkpoint):
                logger.warning(f"SAM checkpoint not found: {sam_checkpoint}")
                return self._load_lightweight_sam()

            sam = sam_model_registry[model_type](checkpoint=sam_checkpoint)
            sam.to(device=self.device)

            predictor = SamPredictor(sam)
            logger.info("Full SAM model loaded successfully")
            return predictor

        except Exception as e:
            logger.error(f"Failed to load full SAM model: {e}")
            return self._load_lightweight_sam()

    def _load_lightweight_classification(self):
        """Load lightweight classification models"""

        # Return mock classification models
        class MockClassifier:
            def __init__(self):
                self.device = self.device
                logger.info("Mock classifier loaded (low memory mode)")

            def predict(self, *args, **kwargs):
                return {"predictions": [], "confidence": 0.5}

        return {
            "classifier": MockClassifier(),
            "feature_extractor": MockClassifier(),
            "zero_shot_classifier": MockClassifier(),
        }

    def _load_full_classification(self):
        """Load full classification models"""
        try:
            from transformers import AutoModel, AutoTokenizer, pipeline

            # Load ResNet classifier
            classifier = AutoModel.from_pretrained("microsoft/resnet-50")
            feature_extractor = AutoTokenizer.from_pretrained("microsoft/resnet-50")

            # Load zero-shot classifier
            zero_shot_classifier = pipeline(
                "zero-shot-classification", model="facebook/bart-large-mnli"
            )

            logger.info("Full classification models loaded successfully")
            return {
                "classifier": classifier,
                "feature_extractor": feature_extractor,
                "zero_shot_classifier": zero_shot_classifier,
            }

        except Exception as e:
            logger.error(f"Failed to load full classification models: {e}")
            return self._load_lightweight_classification()

    def _load_safety_models(self):
        """Load safety models"""
        try:
            from transformers import pipeline

            # Load text classifier
            text_classifier = pipeline(
                "text-classification", model="microsoft/DialoGPT-medium", return_all_scores=True
            )

            # Load image classifier
            image_classifier = pipeline("image-classification", model="google/vit-base-patch16-224")

            logger.info("Safety models loaded successfully")
            return {"text_classifier": text_classifier, "image_classifier": image_classifier}

        except Exception as e:
            logger.error(f"Failed to load safety models: {e}")
            return None

    def clear_models(self):
        """Clear all loaded models to free memory"""
        self.models.clear()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        logger.info("All models cleared from memory")


# Global instance
lazy_loader = LazyModelLoader()
