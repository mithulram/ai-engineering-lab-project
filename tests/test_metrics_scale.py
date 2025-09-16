"""
Test to verify metrics are stored in 0-1 range for proper Grafana display
"""
import re
import pytest


def test_metrics_scale_smoke(client):
    """
    Test that metrics are stored in 0-1 range (not 0-100)
    This ensures Grafana will display them as proper percentages
    """
    # Make a demo request to generate metrics
    with open('tests/data/sample_car.jpg', 'rb') as f:
        response = client.post('/api/count', 
                             data={'image': f, 'item_type': 'car'},
                             content_type='multipart/form-data')
    
    # Fetch metrics
    res = client.get("/metrics")
    text = res.get_data(as_text=True)
    
    # Parse metric values and verify they're in 0-1 range
    metrics_to_check = [
        'ai_object_counting_model_confidence',
        'ai_object_counting_accuracy', 
        'ai_object_counting_precision',
        'ai_object_counting_recall'
    ]
    
    for metric_name in metrics_to_check:
        # Find the metric value (look for metric_name{...} value)
        pattern = rf'{re.escape(metric_name)}\{{[^}}]*\}} ([0-9]+\.[0-9]+|[0-9]+)'
        match = re.search(pattern, text)
        
        assert match, f"{metric_name} metric missing from /metrics"
        
        value = float(match.group(1))
        assert 0.0 <= value <= 1.0, f"{metric_name} out of expected 0..1 range: {value}"
        
        # Additional check: ensure it's not in the old 0-100 range
        assert value <= 1.0, f"{metric_name} appears to be in old 0-100 range: {value}"
