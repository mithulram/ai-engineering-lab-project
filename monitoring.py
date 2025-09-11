"""
Monitoring module for AI Object Counting Application
Implements OpenMetrics compatible metrics for Prometheus scraping
"""

from prometheus_client import Counter, Histogram, Gauge, Info, generate_latest, CONTENT_TYPE_LATEST
from prometheus_client.core import CollectorRegistry
import time
import logging

logger = logging.getLogger(__name__)

class MetricsCollector:
    """
    Collects and exposes metrics for the AI Object Counting application
    """
    
    def __init__(self):
        """Initialize the metrics collector with all required metrics"""
        
        # Create a custom registry
        self.registry = CollectorRegistry()
        
        # Performance Metrics
        self.accuracy_gauge = Gauge(
            'ai_object_counting_accuracy',
            'Accuracy of object counting predictions',
            ['object_type', 'image_resolution', 'segments_found'],
            registry=self.registry
        )
        
        self.precision_gauge = Gauge(
            'ai_object_counting_precision',
            'Precision of object counting predictions',
            ['object_type', 'image_resolution', 'segments_found'],
            registry=self.registry
        )
        
        self.recall_gauge = Gauge(
            'ai_object_counting_recall',
            'Recall of object counting predictions',
            ['object_type', 'image_resolution', 'segments_found'],
            registry=self.registry
        )
        
        # Model Confidence Metrics
        self.model_confidence_gauge = Gauge(
            'ai_object_counting_model_confidence',
            'Confidence score per predicted label',
            ['model_name', 'object_type', 'predicted_label'],
            registry=self.registry
        )
        
        # Inference Time Metrics
        self.inference_time_histogram = Histogram(
            'ai_object_counting_inference_time_seconds',
            'Time taken for model inference',
            ['model_name', 'object_type'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, float('inf')],
            registry=self.registry
        )
        
        # Overall Response Time
        self.response_time_histogram = Histogram(
            'ai_object_counting_response_time_seconds',
            'Total response time for API requests',
            ['endpoint', 'object_type'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0, float('inf')],
            registry=self.registry
        )
        
        # Image Processing Metrics
        self.image_resolution_gauge = Gauge(
            'ai_object_counting_image_resolution',
            'Resolution of processed images',
            ['object_type'],
            registry=self.registry
        )
        
        self.segments_found_gauge = Gauge(
            'ai_object_counting_segments_found',
            'Number of segments found in images',
            ['object_type', 'image_resolution'],
            registry=self.registry
        )
        
        self.object_types_found_gauge = Gauge(
            'ai_object_counting_object_types_found',
            'Number of different object types found in images',
            ['object_type', 'image_resolution'],
            registry=self.registry
        )
        
        self.avg_segment_resolution_gauge = Gauge(
            'ai_object_counting_avg_segment_resolution',
            'Average resolution of segments',
            ['object_type', 'image_resolution'],
            registry=self.registry
        )
        
        # Request Counters
        self.requests_total = Counter(
            'ai_object_counting_requests_total',
            'Total number of API requests',
            ['endpoint', 'method', 'status_code'],
            registry=self.registry
        )
        
        self.predictions_total = Counter(
            'ai_object_counting_predictions_total',
            'Total number of predictions made',
            ['object_type', 'model_name'],
            registry=self.registry
        )
        
        # Model Information
        self.model_info = Info(
            'ai_object_counting_model_info',
            'Information about the models used',
            registry=self.registry
        )
        
        # Set model information
        self.model_info.info({
            'sam_model': 'Segment Anything Model (ViT-B)',
            'classification_model': 'ResNet-50 (ImageNet)',
            'label_refinement': 'DistilBERT (Zero-shot)',
            'pipeline_version': '1.0.0'
        })
        
        logger.info("Metrics collector initialized successfully")
    
    def record_prediction(self, object_type, predicted_count, actual_count, 
                         confidence_scores, inference_times, image_metadata):
        """
        Record metrics for a single prediction
        
        Args:
            object_type (str): Type of object being counted
            predicted_count (int): Count predicted by the model
            actual_count (int): Actual count (ground truth)
            confidence_scores (dict): Confidence scores for each model
            inference_times (dict): Inference times for each model
            image_metadata (dict): Metadata about the processed image
        """
        try:
            # Calculate accuracy, precision, recall
            accuracy = 1.0 if predicted_count == actual_count else 0.0
            precision = self._calculate_precision(predicted_count, actual_count)
            recall = self._calculate_recall(predicted_count, actual_count)
            
            # Extract metadata
            image_resolution = f"{image_metadata.get('width', 0)}x{image_metadata.get('height', 0)}"
            segments_found = image_metadata.get('segments_found', 0)
            object_types_found = image_metadata.get('object_types_found', 1)
            avg_segment_resolution = image_metadata.get('avg_segment_resolution', 0)
            
            # Record performance metrics
            self.accuracy_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution,
                segments_found=str(segments_found)
            ).set(accuracy)
            
            self.precision_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution,
                segments_found=str(segments_found)
            ).set(precision)
            
            self.recall_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution,
                segments_found=str(segments_found)
            ).set(recall)
            
            # Record model confidence
            for model_name, confidence in confidence_scores.items():
                self.model_confidence_gauge.labels(
                    model_name=model_name,
                    object_type=object_type,
                    predicted_label=object_type
                ).set(confidence)
            
            # Record inference times
            for model_name, inference_time in inference_times.items():
                self.inference_time_histogram.labels(
                    model_name=model_name,
                    object_type=object_type
                ).observe(inference_time)
            
            # Record image processing metrics
            self.image_resolution_gauge.labels(object_type=object_type).set(
                image_metadata.get('width', 0) * image_metadata.get('height', 0)
            )
            
            self.segments_found_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution
            ).set(segments_found)
            
            self.object_types_found_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution
            ).set(object_types_found)
            
            self.avg_segment_resolution_gauge.labels(
                object_type=object_type,
                image_resolution=image_resolution
            ).set(avg_segment_resolution)
            
            # Increment counters
            self.predictions_total.labels(
                object_type=object_type,
                model_name='pipeline'
            ).inc()
            
            logger.info(f"Recorded metrics for {object_type}: accuracy={accuracy}, precision={precision}, recall={recall}")
            
        except Exception as e:
            logger.error(f"Error recording prediction metrics: {str(e)}")
    
    def record_request(self, endpoint, method, status_code, response_time, object_type=None):
        """
        Record metrics for an API request
        
        Args:
            endpoint (str): API endpoint
            method (str): HTTP method
            status_code (int): HTTP status code
            response_time (float): Response time in seconds
            object_type (str): Type of object (if applicable)
        """
        try:
            # Record response time
            self.response_time_histogram.labels(
                endpoint=endpoint,
                object_type=object_type or 'unknown'
            ).observe(response_time)
            
            # Increment request counter
            self.requests_total.labels(
                endpoint=endpoint,
                method=method,
                status_code=str(status_code)
            ).inc()
            
        except Exception as e:
            logger.error(f"Error recording request metrics: {str(e)}")
    
    def _calculate_precision(self, predicted_count, actual_count):
        """Calculate precision for counting task"""
        if predicted_count == 0:
            return 1.0 if actual_count == 0 else 0.0
        return min(1.0, actual_count / predicted_count) if predicted_count > 0 else 0.0
    
    def _calculate_recall(self, predicted_count, actual_count):
        """Calculate recall for counting task"""
        if actual_count == 0:
            return 1.0 if predicted_count == 0 else 0.0
        return min(1.0, predicted_count / actual_count) if actual_count > 0 else 0.0
    
    def get_metrics(self):
        """
        Get metrics in OpenMetrics format
        
        Returns:
            str: Metrics in OpenMetrics format
        """
        return generate_latest(self.registry)
    
    def get_content_type(self):
        """Get the content type for metrics response"""
        return CONTENT_TYPE_LATEST

# Global metrics collector instance
metrics_collector = MetricsCollector()
