#!/usr/bin/env python3
"""
Test script for few-shot learning functionality
"""

import requests
import json
import os
from image_generator import ImageGenerator

def test_few_shot_learning():
    """Test the few-shot learning functionality"""
    
    print("🧠 Testing Few-Shot Learning Functionality")
    print("=" * 50)
    
    base_url = "http://localhost:5001"
    
    # Test 1: List learned objects (should be empty initially)
    print("\n1. Testing list learned objects...")
    try:
        response = requests.get(f"{base_url}/api/learned-objects")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Learned objects: {data['count']}")
            print(f"   Objects: {[obj['name'] for obj in data['learned_objects']]}")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 2: Generate training images for a new object type
    print("\n2. Generating training images for 'bicycle'...")
    generator = ImageGenerator("few_shot_training_images")
    
    # Generate 5 training images for bicycle
    training_images = []
    for i in range(5):
        img, metadata = generator.generate_synthetic_image(
            object_type="bicycle",
            count=2,  # 2 bicycles per image
            width=256,
            height=256,
            background_type="white",
            clarity_level=0.9
        )
        
        filename = f"bicycle_training_{i}.png"
        filepath = os.path.join("few_shot_training_images", filename)
        img.save(filepath)
        training_images.append(filepath)
        print(f"   Generated: {filename}")
    
    # Test 3: Learn the new object type
    print("\n3. Learning new object type 'bicycle'...")
    try:
        files = []
        for img_path in training_images:
            files.append(('images', open(img_path, 'rb')))
        
        data = {'object_name': 'bicycle'}
        
        response = requests.post(f"{base_url}/api/learn", files=files, data=data)
        
        # Close files
        for _, file in files:
            file.close()
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Learning successful!")
            print(f"   Object: {result['object_name']}")
            print(f"   Training images: {result['training_images_count']}")
            print(f"   Feature dimension: {result['feature_dim']}")
        else:
            print(f"❌ Learning failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 4: List learned objects again
    print("\n4. Checking learned objects after learning...")
    try:
        response = requests.get(f"{base_url}/api/learned-objects")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Learned objects: {data['count']}")
            for obj in data['learned_objects']:
                print(f"   - {obj['name']}: {obj['training_images_count']} images")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 5: Generate a test image and count learned objects
    print("\n5. Testing object counting with learned object...")
    try:
        # Generate a test image with bicycles
        test_img, _ = generator.generate_synthetic_image(
            object_type="bicycle",
            count=3,
            width=512,
            height=512,
            background_type="sky",
            clarity_level=0.8
        )
        
        test_filename = "bicycle_test.png"
        test_filepath = os.path.join("few_shot_training_images", test_filename)
        test_img.save(test_filepath)
        
        # Count bicycles in the test image
        with open(test_filepath, 'rb') as f:
            files = {'image': f}
            data = {'object_name': 'bicycle'}
            
            response = requests.post(f"{base_url}/api/count-learned", files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Counting successful!")
            print(f"   Count: {result['count']}")
            print(f"   Confidence: {result['confidence']:.3f}")
            print(f"   Segments checked: {result['segments_checked']}")
        else:
            print(f"❌ Counting failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 6: Test object recognition
    print("\n6. Testing object recognition...")
    try:
        with open(test_filepath, 'rb') as f:
            files = {'image': f}
            data = {'threshold': 0.3}
            
            response = requests.post(f"{base_url}/api/recognize", files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Recognition successful!")
            print(f"   Recognized: {result['recognized']}")
            if result['recognized']:
                print(f"   Best match: {result['best_match']}")
                print(f"   Similarity: {result['best_similarity']:.3f}")
            print(f"   All similarities: {result['similarities']}")
        else:
            print(f"❌ Recognition failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 7: Learn another object type
    print("\n7. Learning another object type 'chair'...")
    try:
        # Generate training images for chair
        chair_images = []
        for i in range(3):
            img, _ = generator.generate_synthetic_image(
                object_type="chair",
                count=1,
                width=256,
                height=256,
                background_type="white",
                clarity_level=0.9
            )
            
            filename = f"chair_training_{i}.png"
            filepath = os.path.join("few_shot_training_images", filename)
            img.save(filepath)
            chair_images.append(filepath)
        
        # Learn chair
        files = []
        for img_path in chair_images:
            files.append(('images', open(img_path, 'rb')))
        
        data = {'object_name': 'chair'}
        
        response = requests.post(f"{base_url}/api/learn", files=files, data=data)
        
        # Close files
        for _, file in files:
            file.close()
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Chair learning successful!")
        else:
            print(f"❌ Chair learning failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 8: Final check of learned objects
    print("\n8. Final check of all learned objects...")
    try:
        response = requests.get(f"{base_url}/api/learned-objects")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Total learned objects: {data['count']}")
            for obj in data['learned_objects']:
                print(f"   - {obj['name']}: {obj['training_images_count']} images (learned at {obj['learned_at']})")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    print("\n" + "=" * 50)
    print("🎉 Few-shot learning tests completed!")

if __name__ == "__main__":
    test_few_shot_learning()
