#!/usr/bin/env python3
"""
Automated verification tests for Week 2 requirements
Tests metrics endpoint and Grafana dashboard JSONs
"""

import json
import os
import requests
import subprocess
import sys
import time
from pathlib import Path

def test_metrics_endpoint():
    """Test that /metrics endpoint contains required metrics with pipeline_version labels"""
    print("Testing /metrics endpoint...")
    
    try:
        # Wait for server to be ready
        time.sleep(2)
        response = requests.get('http://localhost:5001/metrics', timeout=10)
        response.raise_for_status()
        metrics_text = response.text
        
        # Required metrics with pipeline_version labels
        required_metrics = [
            'ai_object_counting_inference_time_seconds',
            'ai_object_counting_model_confidence',
            'ai_object_counting_request_count_total',
            'ai_object_counting_blocked_requests_total',
            'ai_object_counting_accuracy',
            'ai_object_counting_precision',
            'ai_object_counting_recall'
        ]
        
        missing_metrics = []
        for metric in required_metrics:
            if metric not in metrics_text:
                missing_metrics.append(metric)
        
        if missing_metrics:
            print(f"❌ Missing metrics: {missing_metrics}")
            return False
        
        # Check for pipeline_version labels in metric definitions
        pipeline_version_found = False
        for line in metrics_text.split('\n'):
            if 'pipeline_version' in line:
                pipeline_version_found = True
                break
        
        if not pipeline_version_found:
            print("❌ pipeline_version labels not found in metrics")
            return False
        
        print("✅ All required metrics found with pipeline_version labels")
        return True
        
    except Exception as e:
        print(f"❌ Error testing metrics endpoint: {e}")
        return False

def test_grafana_dashboards():
    """Test that Grafana dashboard JSONs are valid and contain required elements"""
    print("Testing Grafana dashboard JSONs...")
    
    dashboard_files = [
        'monitoring/grafana/dashboards/pipeline_overview.json',
        'monitoring/grafana/dashboards/version_comparison.json',
        'monitoring/grafana/dashboards/safety_misuse.json',
        'monitoring/grafana/dashboards/resource_latency.json'
    ]
    
    all_valid = True
    
    for dashboard_file in dashboard_files:
        if not os.path.exists(dashboard_file):
            print(f"❌ Dashboard file not found: {dashboard_file}")
            all_valid = False
            continue
        
        try:
            with open(dashboard_file, 'r') as f:
                dashboard = json.load(f)
            
            # Check for required fields
            required_fields = ['title', 'uid', 'panels', 'templating']
            for field in required_fields:
                if field not in dashboard:
                    print(f"❌ Missing field '{field}' in {dashboard_file}")
                    all_valid = False
            
            # Check for pipeline_version variable
            pipeline_version_found = False
            if 'templating' in dashboard and 'list' in dashboard['templating']:
                for var in dashboard['templating']['list']:
                    if var.get('name') == 'pipeline_version':
                        pipeline_version_found = True
                        break
            
            if not pipeline_version_found:
                print(f"❌ pipeline_version variable not found in {dashboard_file}")
                all_valid = False
            
            # Check for blocked_requests_total query in safety_misuse.json
            if 'safety_misuse.json' in dashboard_file:
                blocked_requests_found = False
                for panel in dashboard.get('panels', []):
                    for target in panel.get('targets', []):
                        if 'blocked_requests_total' in target.get('expr', ''):
                            blocked_requests_found = True
                            break
                    if blocked_requests_found:
                        break
                
                if not blocked_requests_found:
                    print(f"❌ blocked_requests_total query not found in {dashboard_file}")
                    all_valid = False
            
            print(f"✅ {dashboard_file} is valid")
            
        except json.JSONDecodeError as e:
            print(f"❌ Invalid JSON in {dashboard_file}: {e}")
            all_valid = False
        except Exception as e:
            print(f"❌ Error testing {dashboard_file}: {e}")
            all_valid = False
    
    return all_valid

def test_dashboards_yml():
    """Test that dashboards.yml is properly configured"""
    print("Testing dashboards.yml configuration...")
    
    yml_file = 'monitoring/grafana/provisioning/dashboards/dashboards.yml'
    
    if not os.path.exists(yml_file):
        print(f"❌ dashboards.yml not found: {yml_file}")
        return False
    
    try:
        with open(yml_file, 'r') as f:
            content = f.read()
        
        # Check for required dashboard files
        required_dashboards = [
            'pipeline_overview.json',
            'version_comparison.json',
            'safety_misuse.json',
            'resource_latency.json'
        ]
        
        missing_dashboards = []
        for dashboard in required_dashboards:
            if dashboard not in content:
                missing_dashboards.append(dashboard)
        
        if missing_dashboards:
            print(f"❌ Missing dashboard references in dashboards.yml: {missing_dashboards}")
            return False
        
        print("✅ dashboards.yml is properly configured")
        return True
        
    except Exception as e:
        print(f"❌ Error testing dashboards.yml: {e}")
        return False

def test_port_configuration():
    """Test that port configuration works via environment variables"""
    print("Testing port configuration...")
    
    # Test API_PORT by checking the code
    try:
        with open('app.py', 'r') as f:
            app_content = f.read()
        
        if 'os.environ.get(\'API_PORT\', 5001)' in app_content:
            print("✅ API_PORT environment variable is configured in app.py")
        else:
            print("❌ API_PORT environment variable not found in app.py")
            return False
            
    except Exception as e:
        print(f"❌ Error testing API_PORT: {e}")
        return False
    
    # Test MONITORING_PORT by checking the code
    try:
        with open('monitoring_server_enhanced.py', 'r') as f:
            monitoring_content = f.read()
        
        if 'os.environ.get(\'MONITORING_PORT\', 8080)' in monitoring_content:
            print("✅ MONITORING_PORT environment variable is configured in monitoring_server_enhanced.py")
        else:
            print("❌ MONITORING_PORT environment variable not found in monitoring_server_enhanced.py")
            return False
            
    except Exception as e:
        print(f"❌ Error testing MONITORING_PORT: {e}")
        return False
    
    return True

def main():
    """Run all verification tests"""
    print("=" * 60)
    print("Week 2 Requirements Verification Tests")
    print("=" * 60)
    
    tests = [
        ("Metrics Endpoint", test_metrics_endpoint),
        ("Grafana Dashboards", test_grafana_dashboards),
        ("Dashboards YML", test_dashboards_yml),
        ("Port Configuration", test_port_configuration)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n--- {test_name} ---")
        try:
            if test_func():
                passed += 1
            else:
                print(f"❌ {test_name} failed")
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
    
    print("\n" + "=" * 60)
    print(f"Test Results: {passed}/{total} tests passed")
    print("=" * 60)
    
    if passed == total:
        print("🎉 All Week 2 requirements verified successfully!")
        return 0
    else:
        print("❌ Some tests failed. Please check the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
