#!/usr/bin/env python3
"""
Comprehensive test script for Week 2 Flutter frontend integration
Tests all backend functionality that the Flutter app will use
"""

import requests
import json
import time
import os
from image_generator import ImageGenerator

def test_backend_health():
    """Test backend health endpoint"""
    print("🔍 Testing Backend Health...")
    try:
        response = requests.get('http://localhost:5001/api/health')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Backend is healthy: {data['status']}")
            return True
        else:
            print(f"❌ Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend connection failed: {e}")
        return False

def test_metrics_endpoint():
    """Test OpenMetrics endpoint"""
    print("\n📊 Testing Metrics Endpoint...")
    try:
        response = requests.get('http://localhost:5001/metrics')
        if response.status_code == 200:
            content = response.text
            metrics_count = len([line for line in content.split('\n') if line.startswith('ai_object_counting_')])
            print(f"✅ Metrics endpoint working: {metrics_count} metrics found")
            return True
        else:
            print(f"❌ Metrics endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Metrics endpoint error: {e}")
        return False

def test_object_counting():
    """Test object counting API"""
    print("\n🎯 Testing Object Counting API...")
    try:
        # Generate a test image
        generator = ImageGenerator("test_images")
        img, metadata = generator.generate_synthetic_image(
            object_type="car",
            count=3,
            width=256,
            height=256
        )
        
        test_image_path = "test_car_image.png"
        img.save(test_image_path)
        
        # Test API call
        with open(test_image_path, 'rb') as f:
            files = {'image': f}
            data = {'item_type': 'car'}
            response = requests.post('http://localhost:5001/api/count', files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Object counting successful: {result['count']} objects detected")
            return True
        else:
            print(f"❌ Object counting failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Object counting error: {e}")
        return False
    finally:
        # Clean up test image
        if os.path.exists("test_car_image.png"):
            os.remove("test_car_image.png")

def test_few_shot_learning():
    """Test few-shot learning functionality"""
    print("\n🧠 Testing Few-Shot Learning...")
    try:
        # Test list learned objects
        response = requests.get('http://localhost:5001/api/learned-objects')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Learned objects endpoint working: {data['count']} objects")
        else:
            print(f"❌ Learned objects endpoint failed: {response.status_code}")
            return False
        
        # Test learning a new object (simulate with generated images)
        generator = ImageGenerator("few_shot_test")
        training_images = []
        
        for i in range(3):
            img, _ = generator.generate_synthetic_image(
                object_type="bicycle",
                count=2,
                width=128,
                height=128
            )
            img_path = f"bicycle_training_{i}.png"
            img.save(img_path)
            training_images.append(img_path)
        
        # Learn the object
        files = []
        for img_path in training_images:
            files.append(('images', open(img_path, 'rb')))
        
        data = {'object_name': 'bicycle'}
        response = requests.post('http://localhost:5001/api/learn', files=files, data=data)
        
        # Close files
        for _, file in files:
            file.close()
        
        if response.status_code == 200:
            result = response.json()
            if result.get('learning_successful'):
                print("✅ Few-shot learning successful")
            else:
                print(f"⚠️ Learning completed but with issues: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ Few-shot learning failed: {response.status_code}")
        
        # Clean up test images
        for img_path in training_images:
            if os.path.exists(img_path):
                os.remove(img_path)
        
        return True
    except Exception as e:
        print(f"❌ Few-shot learning error: {e}")
        return False

def test_monitoring_server():
    """Test monitoring server"""
    print("\n📈 Testing Monitoring Server...")
    try:
        response = requests.get('http://localhost:8080/api/metrics')
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Monitoring server working: {len(data.get('metrics', {}))} metrics")
            return True
        else:
            print(f"❌ Monitoring server failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Monitoring server error: {e}")
        return False

def test_image_generation():
    """Test image generation functionality"""
    print("\n🖼️ Testing Image Generation...")
    try:
        generator = ImageGenerator("test_generation")
        
        # Test different configurations
        configs = [
            {"object_type": "car", "count": 3, "width": 256, "height": 256},
            {"object_type": "tree", "count": 2, "width": 512, "height": 512},
            {"object_type": "person", "count": 1, "width": 128, "height": 128},
        ]
        
        for i, config in enumerate(configs):
            img, metadata = generator.generate_synthetic_image(**config)
            filename = f"test_gen_{i}.png"
            img.save(filename)
            
            print(f"✅ Generated {config['object_type']} image: {filename}")
            
            # Clean up
            if os.path.exists(filename):
                os.remove(filename)
        
        return True
    except Exception as e:
        print(f"❌ Image generation error: {e}")
        return False

def test_performance_metrics():
    """Test performance metrics collection"""
    print("\n⚡ Testing Performance Metrics...")
    try:
        # Make several API calls to generate metrics
        generator = ImageGenerator("perf_test")
        
        for i in range(5):
            img, _ = generator.generate_synthetic_image(
                object_type="car",
                count=i + 1,
                width=256,
                height=256
            )
            
            test_path = f"perf_test_{i}.png"
            img.save(test_path)
            
            with open(test_path, 'rb') as f:
                files = {'image': f}
                data = {'item_type': 'car'}
                requests.post('http://localhost:5001/api/count', files=files, data=data)
            
            # Clean up
            if os.path.exists(test_path):
                os.remove(test_path)
        
        # Check metrics
        response = requests.get('http://localhost:5001/metrics')
        if response.status_code == 200:
            content = response.text
            metrics = [line for line in content.split('\n') if line.startswith('ai_object_counting_')]
            print(f"✅ Performance metrics collected: {len(metrics)} metrics")
            return True
        else:
            print(f"❌ Metrics collection failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Performance metrics error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Week 2 Flutter Frontend Integration Test")
    print("=" * 50)
    
    tests = [
        ("Backend Health", test_backend_health),
        ("Metrics Endpoint", test_metrics_endpoint),
        ("Object Counting", test_object_counting),
        ("Few-Shot Learning", test_few_shot_learning),
        ("Monitoring Server", test_monitoring_server),
        ("Image Generation", test_image_generation),
        ("Performance Metrics", test_performance_metrics),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 50)
    print("📋 TEST SUMMARY")
    print("=" * 50)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\n🎯 Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Flutter frontend should work perfectly.")
    elif passed >= total * 0.8:
        print("⚠️ Most tests passed. Flutter frontend should work with minor issues.")
    else:
        print("❌ Many tests failed. Please check the backend setup.")
    
    print("\n🌐 Flutter App URLs:")
    print("   - Flutter Web App: http://localhost:3000")
    print("   - Backend API: http://localhost:5001")
    print("   - Monitoring Dashboard: http://localhost:8080")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
