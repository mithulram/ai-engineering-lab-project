#!/usr/bin/env python3
"""
Test script for image generation API
"""

import requests
import json
import time

def test_image_generation():
    url = "http://localhost:5001/api/generate-image"
    data = {
        "object_type": "car",
        "count": 3,
        "size": "512x512",
        "clarity": 0.8,
        "noise": 10,
        "rotation": 0,
        "background": "white"
    }
    
    print("Testing image generation API...")
    print(f"Request data: {json.dumps(data, indent=2)}")
    
    start_time = time.time()
    
    try:
        response = requests.post(url, json=data, timeout=30)
        end_time = time.time()
        
        print(f"Response time: {end_time - start_time:.2f} seconds")
        print(f"Status code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("Success!")
            print(f"Response: {json.dumps(result, indent=2)}")
        else:
            print(f"Error: {response.text}")
            
    except requests.exceptions.Timeout:
        print("Request timed out after 30 seconds")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_image_generation()
