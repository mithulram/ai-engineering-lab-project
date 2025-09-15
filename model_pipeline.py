import os
import urllib.request
import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
import matplotlib.pyplot as plt
import torchvision.transforms as tf
from transformers import AutoImageProcessor, AutoModelForImageClassification, pipeline
from segment_anything import SamAutomaticMaskGenerator, sam_model_registry
import logging

logger = logging.getLogger(__name__)

class ObjectCounter:
    """
    AI Object Counting Pipeline
    
    This class implements the three-step pipeline from the Jupyter notebook:
    1. SAM (Segment Anything Model) for image segmentation
    2. ResNet-50 for object classification
    3. DistilBERT for zero-shot label refinement
    """
    
    def __init__(self, top_n=10):
        """
        Initialize the ObjectCounter with all required models.
        
        Args:
            top_n (int): Number of top segments to process
        """
        self.top_n = top_n
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {self.device}")
        
        # Initialize models
        self._initialize_sam()
        self._initialize_classification_models()
        
    def _initialize_sam(self):
        """Initialize the SAM (Segment Anything Model)."""
        try:
            # Download SAM checkpoint if not exists
            checkpoint_path = "sam_vit_b_01ec64.pth"
            if not os.path.exists(checkpoint_path):
                logger.info("Downloading SAM checkpoint...")
                url = "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth"
                urllib.request.urlretrieve(url, checkpoint_path)
                logger.info("SAM checkpoint downloaded successfully")
            
            # Load SAM model
            self.sam = sam_model_registry["vit_b"](checkpoint_path)
            self.sam.to(self.device)
            
            # Initialize mask generator
            self.mask_generator = SamAutomaticMaskGenerator(
                model=self.sam,
                points_per_side=16,
                pred_iou_thresh=0.7,
                stability_score_thresh=0.85,
                min_mask_region_area=500,
            )
            
            logger.info("SAM model initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing SAM: {str(e)}")
            raise
    
    def _initialize_classification_models(self):
        """Initialize ResNet-50 and DistilBERT models."""
        try:
            # Set up local cache directory
            import os
            cache_dir = os.path.join(os.getcwd(), ".huggingface_cache")
            os.makedirs(cache_dir, exist_ok=True)
            
            # Initialize ResNet-50
            self.image_processor = AutoImageProcessor.from_pretrained(
                "microsoft/resnet-50",
                cache_dir=cache_dir
            )
            self.class_model = AutoModelForImageClassification.from_pretrained(
                "microsoft/resnet-50",
                cache_dir=cache_dir
            )
            
            # Initialize DistilBERT zero-shot classifier
            self.label_classifier = pipeline(
                "zero-shot-classification", 
                model="typeform/distilbert-base-uncased-mnli",
                model_kwargs={"cache_dir": cache_dir}
            )
            
            # Define candidate labels
            self.candidate_labels = [
                "car", "cat", "tree", "dog", "building", 
                "person", "sky", "ground", "hardware"
            ]
            
            logger.info("Classification models initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing classification models: {str(e)}")
            logger.error("CRITICAL: Cannot initialize real AI models!")
            logger.error("Please run 'python3 fix_huggingface_cache.py' to fix model loading issues")
            raise RuntimeError(f"Failed to initialize AI models: {str(e)}")
    
    def count_objects_from_bytes(self, image_bytes, item_type):
        """
        Count objects of a specific type from image bytes.
        
        Args:
            image_bytes (bytes): Image data as bytes
            item_type (str): Type of object to count
            
        Returns:
            dict: Results containing count, confidence, and details
        """
        import io
        from PIL import Image
        
        # Convert bytes to PIL Image
        image = Image.open(io.BytesIO(image_bytes))
        return self.count_objects_from_image(image, item_type)
    
    def count_objects_from_image(self, image, target_item_type):
        """
        Count objects of a specific type in a PIL Image.
        
        Args:
            image (PIL.Image): Input image
            target_item_type (str): Type of object to count
            
        Returns:
            dict: Results containing count, confidence, and details
        """
        try:
            logger.info(f"Processing image for item type: {target_item_type}")
            
            # Ensure real AI models are loaded - no fallback mode allowed
            if self.image_processor is None or self.class_model is None:
                logger.error("CRITICAL: AI models not initialized!")
                raise RuntimeError("AI models not initialized. Please run fix_huggingface_cache.py to resolve model loading issues.")
            
            # Process image
            height, width = image.size[1], image.size[0]
            logger.info(f"Image size: {width}x{height}")
            
            # Step 1: Generate segmentation masks using SAM
            logger.info("Generating segmentation masks...")
            masks = self.mask_generator.generate(np.array(image))
            masks_sorted = sorted(masks, key=lambda x: x['area'], reverse=True)
            
            # Create panoptic map
            panoptic_map = np.zeros((height, width), dtype=np.uint32)
            for i, mask_data in enumerate(masks_sorted):
                panoptic_map[mask_data['segmentation']] = i + 1
            
            logger.info(f"Generated {len(masks_sorted)} segments")
            
            # Step 2: Classify each segment using ResNet-50
            logger.info("Classifying segments...")
            segment_labels = []
            segment_confidences = []
            
            for i, mask_data in enumerate(masks_sorted):
                # Extract segment
                segment_mask = mask_data['segmentation']
                segment_bbox = mask_data['bbox']  # [x, y, w, h]
                
                # Crop segment from original image
                x, y, w, h = segment_bbox
                x, y, w, h = int(x), int(y), int(w), int(h)
                segment_crop = image.crop((x, y, x + w, y + h))
                
                # Classify segment
                try:
                    inputs = self.image_processor(segment_crop, return_tensors="pt")
                    with torch.no_grad():
                        outputs = self.class_model(**inputs)
                        probabilities = torch.nn.functional.softmax(outputs.logits[0], dim=-1)
                        predicted_class_id = probabilities.argmax().item()
                        confidence = probabilities[predicted_class_id].item()
                        predicted_label = self.class_model.config.id2label[predicted_class_id]
                    
                    segment_labels.append(predicted_label)
                    segment_confidences.append(confidence)
                except Exception as e:
                    logger.warning(f"Failed to classify segment {i}: {str(e)}")
                    segment_labels.append("unknown")
                    segment_confidences.append(0.0)
            
            # Step 3: Use DistilBERT for zero-shot classification to refine results
            logger.info("Refining classification with zero-shot learning...")
            refined_labels = []
            refined_confidences = []
            
            for i, (label, confidence) in enumerate(zip(segment_labels, segment_confidences)):
                if confidence > 0.3:  # Only refine high-confidence predictions
                    try:
                        # Create a description of the segment
                        segment_description = f"An image of a {label}"
                        
                        # Use zero-shot classification
                        result = self.zero_shot_classifier(
                            segment_description,
                            candidate_labels=[target_item_type, "other", "background"]
                        )
                        
                        # Update label if zero-shot gives higher confidence for target
                        if result['labels'][0] == target_item_type and result['scores'][0] > confidence:
                            refined_labels.append(target_item_type)
                            refined_confidences.append(result['scores'][0])
                        else:
                            refined_labels.append(label)
                            refined_confidences.append(confidence)
                    except Exception as e:
                        logger.warning(f"Zero-shot classification failed for segment {i}: {str(e)}")
                        refined_labels.append(label)
                        refined_confidences.append(confidence)
                else:
                    refined_labels.append(label)
                    refined_confidences.append(confidence)
            
            # Step 4: Count objects of the target type
            target_count = 0
            target_confidences = []
            
            for label, confidence in zip(refined_labels, refined_confidences):
                if label.lower() == target_item_type.lower() or target_item_type.lower() in label.lower():
                    target_count += 1
                    target_confidences.append(confidence)
            
            # Calculate overall confidence
            overall_confidence = np.mean(target_confidences) if target_confidences else 0.5
            
            # Prepare results
            result = {
                'count': target_count,
                'confidence': overall_confidence,
                'details': {
                    'total_segments': len(masks_sorted),
                    'refined_labels': refined_labels,
                    'refined_confidences': refined_confidences,
                    'target_confidences': target_confidences
                }
            }
            
            logger.info(f"Object counting completed. Count: {target_count}, Confidence: {overall_confidence}")
            return result
            
        except Exception as e:
            logger.error(f"Error in object counting: {str(e)}")
            return {
                'count': 0,
                'confidence': 0.0,
                'details': {'error': str(e)}
            }

    def count_objects(self, image_path, target_item_type):
        """
        Count objects of a specific type in an image.
        
        Args:
            image_path (str): Path to the input image
            target_item_type (str): Type of object to count
            
        Returns:
            dict: Results containing count, confidence, and details
        """
        try:
            logger.info(f"Processing image: {image_path} for item type: {target_item_type}")
            
            # Ensure real AI models are loaded - no fallback mode allowed
            if self.image_processor is None or self.class_model is None:
                logger.error("CRITICAL: AI models not initialized!")
                raise RuntimeError("AI models not initialized. Please run fix_huggingface_cache.py to resolve model loading issues.")
            
            # Load and process image
            image = Image.open(image_path)
            height, width = image.size[1], image.size[0]
            logger.info(f"Image size: {width}x{height}")
            
            # Step 1: Generate segmentation masks using SAM
            logger.info("Generating segmentation masks...")
            masks = self.mask_generator.generate(np.array(image))
            masks_sorted = sorted(masks, key=lambda x: x['area'], reverse=True)
            
            # Create panoptic map
            predicted_panoptic_map = np.zeros((height, width), dtype=np.int32)
            for idx, mask_data in enumerate(masks_sorted[:self.top_n]):
                predicted_panoptic_map[mask_data['segmentation']] = idx + 1
            
            predicted_panoptic_map = torch.from_numpy(predicted_panoptic_map)
            logger.info(f"Generated {len(masks_sorted[:self.top_n])} segments")
            
            # Step 2: Extract and classify segments
            segments, labels, predicted_classes = self._process_segments(
                image, predicted_panoptic_map
            )
            
            # Step 3: Count target objects
            count, confidence, details = self._count_target_objects(
                labels, target_item_type, segments, predicted_classes
            )
            
            result = {
                'count': count,
                'confidence': confidence,
                'details': {
                    'total_segments': len(segments),
                    'target_type': target_item_type,
                    'segment_details': [
                        {
                            'segment_id': i,
                            'predicted_class': pred_class,
                            'refined_label': label,
                            'is_target': label == target_item_type
                        }
                        for i, (pred_class, label) in enumerate(zip(predicted_classes, labels))
                    ]
                }
            }
            
            logger.info(f"Object counting completed. Count: {count}, Confidence: {confidence}")
            return result
            
        except Exception as e:
            logger.error(f"Error in count_objects: {str(e)}")
            raise
    
    def _process_segments(self, image, panoptic_map):
        """
        Process individual segments for classification.
        
        Args:
            image: PIL Image object
            panoptic_map: Tensor containing segment labels
            
        Returns:
            tuple: (segments, labels, predicted_classes)
        """
        transform = tf.Compose([tf.PILToTensor()])
        img_tensor = transform(image)
        
        segments = []
        predicted_classes = []
        
        # Process each segment
        for label in panoptic_map.unique():
            if label == 0:  # Skip background
                continue
                
            # Get bounding box for segment
            y_start, y_end = self._get_mask_box(panoptic_map == label)
            x_start, x_end = self._get_mask_box((panoptic_map == label).T)
            
            if y_start is None or x_start is None:
                continue
            
            # Crop segment
            cropped_tensor = img_tensor[:, y_start:y_end+1, x_start:x_end+1]
            cropped_mask = panoptic_map[y_start:y_end+1, x_start:x_end+1] == label
            
            # Create masked segment
            segment = cropped_tensor * cropped_mask.unsqueeze(0)
            segment[:, ~cropped_mask] = 188  # Background color
            
            segments.append(segment)
            
            # Classify segment with ResNet-50 (if available)
            if self.image_processor is not None and self.class_model is not None:
                try:
                    inputs = self.image_processor(images=segment, return_tensors="pt")
                    outputs = self.class_model(**inputs)
                    logits = outputs.logits
                    predicted_class_idx = logits.argmax(-1).item()
                    predicted_class = self.class_model.config.id2label[predicted_class_idx]
                    predicted_classes.append(predicted_class)
                except Exception as e:
                    logger.warning(f"Error classifying segment {label}: {str(e)}")
                    predicted_classes.append("unknown")
            else:
                # DISABLED: Fallback removed - force real AI usage
                logger.error("CRITICAL: ResNet model not available!")
                raise RuntimeError("ResNet model not initialized. Please run fix_huggingface_cache.py to resolve model loading issues.")
        
        # Refine labels using DistilBERT (if available)
        labels = []
        if self.label_classifier is not None:
            for predicted_class in predicted_classes:
                try:
                    result = self.label_classifier(predicted_class, self.candidate_labels)
                    label = result['labels'][0]
                    labels.append(label)
                except Exception as e:
                    logger.warning(f"Error refining label for {predicted_class}: {str(e)}")
                    labels.append("unknown")
        else:
            # DISABLED: Fallback removed - force real AI usage
            logger.error("CRITICAL: DistilBERT model not available!")
            raise RuntimeError("DistilBERT model not initialized. Please run fix_huggingface_cache.py to resolve model loading issues.")
        
        return segments, labels, predicted_classes
    
    def _get_mask_box(self, tensor):
        """
        Get bounding box of non-zero elements in a tensor.
        
        Args:
            tensor (torch.Tensor): Input tensor
            
        Returns:
            tuple: (first_n, last_n) indices
        """
        non_zero_indices = torch.nonzero(tensor, as_tuple=True)[0]
        if non_zero_indices.shape[0] == 0:
            return None, None
        
        first_n = non_zero_indices[:1].item()
        last_n = non_zero_indices[-1:].item()
        
        return first_n, last_n
    
    def _count_target_objects(self, labels, target_type, segments, predicted_classes):
        """
        Count objects of the target type and calculate confidence.
        
        Args:
            labels (list): Refined labels for each segment
            target_type (str): Type of object to count
            segments (list): List of segment tensors
            predicted_classes (list): Original ResNet predictions
            
        Returns:
            tuple: (count, confidence, details)
        """
        # Count target objects
        target_count = sum(1 for label in labels if label == target_type)
        
        # Calculate confidence based on classification scores
        # For now, using a simple heuristic - can be improved
        confidence = 0.8 if target_count > 0 else 0.5
        
        # Additional confidence factors
        if target_count > 0:
            # Higher confidence if multiple segments agree
            if target_count > 1:
                confidence += 0.1
            
            # Higher confidence if ResNet and DistilBERT agree
            agreement_count = sum(
                1 for i, (pred, label) in enumerate(zip(predicted_classes, labels))
                if label == target_type and pred.lower() in target_type.lower()
            )
            if agreement_count > 0:
                confidence += 0.1
        
        # Cap confidence at 1.0
        confidence = min(confidence, 1.0)
        
        # Create details dictionary
        details = {
            "segments_found": len(segments),
            "target_segments": target_count,
            "model_confidence": confidence,
            "predicted_classes": predicted_classes,
            "refined_labels": labels
        }
        
        return target_count, confidence, details
    
    
    def get_supported_item_types(self):
        """
        Get list of supported item types for counting.
        
        Returns:
            list: Supported item types
        """
        return self.candidate_labels.copy()
    
    def get_model_info(self):
        """
        Get information about the loaded models.
        
        Returns:
            dict: Model information
        """
        return {
            'sam_model': 'Segment Anything Model (ViT-B)',
            'classification_model': 'ResNet-50 (ImageNet)',
            'label_refinement': 'DistilBERT (Zero-shot)',
            'device': self.device,
            'supported_types': self.candidate_labels,
            'max_segments': self.top_n
        }
