"""
AI Object Counting - Test Image Generation Script
Generates synthetic images for testing the object counting application
"""

import os
import random
import requests
import json
import time
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
from typing import List, Dict, Tuple, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ImageGenerator:
    """
    Generates synthetic test images for object counting
    """
    
    def __init__(self, output_dir: str = "test_images", api_base_url: str = "http://localhost:5001"):
        self.output_dir = output_dir
        self.api_base_url = api_base_url
        self.object_types = ["car", "cat", "tree", "dog", "building", "person", "sky", "ground", "hardware"]
        
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # AI Image Generation API credentials (to be provided by TAs)
        self.ai_api_url = "llm-web.aieng.fim.uni-passau.de"
        self.ai_api_key = None  # Will be set when credentials are provided
        
    def generate_synthetic_image(self, 
                                object_type: str, 
                                count: int, 
                                width: int = 512, 
                                height: int = 512,
                                background_type: str = "sky",
                                clarity_level: float = 1.0,
                                noise_level: float = 0.0,
                                rotation_range: Tuple[int, int] = (0, 0)) -> Tuple[Image.Image, Dict]:
        """
        Generate a synthetic image with specified objects
        
        Args:
            object_type: Type of object to draw
            count: Number of objects to draw
            width: Image width
            height: Image height
            background_type: Type of background
            clarity_level: Clarity level (0.0 = very blurry, 1.0 = sharp)
            noise_level: Noise level (0.0 = no noise, 1.0 = heavy noise)
            rotation_range: Range of rotation angles for objects
            
        Returns:
            Tuple of (PIL Image, metadata dict)
        """
        # Create base image
        img = Image.new('RGB', (width, height), self._get_background_color(background_type))
        draw = ImageDraw.Draw(img)
        
        # Generate object positions
        positions = self._generate_object_positions(count, width, height)
        
        # Draw objects
        for i, (x, y) in enumerate(positions):
            self._draw_object(draw, object_type, x, y, width, height, 
                            clarity_level, rotation_range)
        
        # Apply effects
        if clarity_level < 1.0:
            img = img.filter(ImageFilter.GaussianBlur(radius=(1-clarity_level)*5))
        
        if noise_level > 0:
            img = self._add_noise(img, noise_level)
        
        # Create metadata
        metadata = {
            'object_type': object_type,
            'count': count,
            'width': width,
            'height': height,
            'background_type': background_type,
            'clarity_level': clarity_level,
            'noise_level': noise_level,
            'rotation_range': rotation_range,
            'positions': positions
        }
        
        return img, metadata
    
    def generate_ai_image(self, 
                         object_type: str, 
                         count: int, 
                         style: str = "realistic",
                         quality: str = "high") -> Optional[Tuple[Image.Image, Dict]]:
        """
        Generate image using AI image generation API
        
        Args:
            object_type: Type of object to generate
            count: Number of objects
            style: Image style (realistic, cartoon, artistic)
            quality: Image quality (low, medium, high)
            
        Returns:
            Tuple of (PIL Image, metadata dict) or None if API unavailable
        """
        if not self.ai_api_key:
            logger.warning("AI API key not provided, skipping AI generation")
            return None
        
        try:
            prompt = f"Generate an image with {count} {object_type}s, {style} style, {quality} quality"
            
            # This would be the actual API call to the AI image generation service
            # For now, we'll use synthetic generation as fallback
            logger.info(f"AI generation not implemented yet, using synthetic generation for: {prompt}")
            return self.generate_synthetic_image(object_type, count)
            
        except Exception as e:
            logger.error(f"Error generating AI image: {str(e)}")
            return None
    
    def _get_background_color(self, background_type: str) -> Tuple[int, int, int]:
        """Get background color based on type"""
        colors = {
            'sky': (135, 206, 235),      # Sky blue
            'ground': (139, 69, 19),     # Brown
            'white': (255, 255, 255),    # White
            'black': (0, 0, 0),          # Black
            'green': (34, 139, 34),      # Forest green
            'gray': (128, 128, 128)      # Gray
        }
        return colors.get(background_type, colors['sky'])
    
    def _generate_object_positions(self, count: int, width: int, height: int) -> List[Tuple[int, int]]:
        """Generate random positions for objects"""
        positions = []
        min_distance = min(width, height) // 10  # Minimum distance between objects
        
        for _ in range(count):
            attempts = 0
            while attempts < 100:  # Prevent infinite loop
                x = random.randint(50, width - 50)
                y = random.randint(50, height - 50)
                
                # Check distance from other objects
                too_close = False
                for px, py in positions:
                    if ((x - px) ** 2 + (y - py) ** 2) ** 0.5 < min_distance:
                        too_close = True
                        break
                
                if not too_close:
                    positions.append((x, y))
                    break
                
                attempts += 1
            
            if attempts >= 100:
                # If we can't find a good position, just place it randomly
                positions.append((random.randint(50, width - 50), 
                                random.randint(50, height - 50)))
        
        return positions
    
    def _draw_object(self, draw: ImageDraw.Draw, object_type: str, x: int, y: int, 
                    width: int, height: int, clarity_level: float, 
                    rotation_range: Tuple[int, int]) -> None:
        """Draw a specific object type"""
        size = random.randint(30, 80)
        rotation = random.randint(rotation_range[0], rotation_range[1])
        
        # Define object colors
        colors = {
            'car': (255, 0, 0),      # Red
            'cat': (255, 165, 0),    # Orange
            'tree': (0, 128, 0),     # Green
            'dog': (139, 69, 19),    # Brown
            'building': (105, 105, 105),  # Gray
            'person': (255, 192, 203),    # Pink
            'sky': (135, 206, 235),       # Sky blue
            'ground': (139, 69, 19),      # Brown
            'hardware': (192, 192, 192)   # Silver
        }
        
        color = colors.get(object_type, (128, 128, 128))
        
        # Draw different shapes based on object type
        if object_type == 'car':
            # Draw car as rectangle
            draw.rectangle([x-size//2, y-size//3, x+size//2, y+size//3], 
                         fill=color, outline=(0, 0, 0), width=2)
            # Wheels
            draw.ellipse([x-size//2+5, y+size//3-10, x-size//2+15, y+size//3], 
                        fill=(0, 0, 0))
            draw.ellipse([x+size//2-15, y+size//3-10, x+size//2-5, y+size//3], 
                        fill=(0, 0, 0))
        
        elif object_type == 'cat':
            # Draw cat as circle with ears
            draw.ellipse([x-size//2, y-size//2, x+size//2, y+size//2], 
                        fill=color, outline=(0, 0, 0), width=2)
            # Ears
            draw.polygon([(x-size//2, y-size//2), (x-size//4, y-size//2-10), 
                         (x, y-size//2)], fill=color)
            draw.polygon([(x, y-size//2), (x+size//4, y-size//2-10), 
                         (x+size//2, y-size//2)], fill=color)
        
        elif object_type == 'tree':
            # Draw tree as triangle with trunk
            draw.polygon([(x, y-size//2), (x-size//2, y+size//4), 
                         (x+size//2, y+size//4)], fill=color)
            # Trunk
            draw.rectangle([x-5, y+size//4, x+5, y+size//2], 
                         fill=(139, 69, 19))
        
        elif object_type == 'dog':
            # Draw dog similar to cat but with different ears
            draw.ellipse([x-size//2, y-size//2, x+size//2, y+size//2], 
                        fill=color, outline=(0, 0, 0), width=2)
            # Floppy ears
            draw.ellipse([x-size//2-5, y-size//2+5, x-size//4, y+size//4], 
                        fill=color)
            draw.ellipse([x+size//4, y-size//2+5, x+size//2+5, y+size//4], 
                        fill=color)
        
        elif object_type == 'building':
            # Draw building as rectangle
            draw.rectangle([x-size//2, y-size//2, x+size//2, y+size//2], 
                         fill=color, outline=(0, 0, 0), width=2)
            # Windows
            for i in range(2):
                for j in range(3):
                    wx = x - size//4 + i * size//2
                    wy = y - size//4 + j * size//6
                    draw.rectangle([wx-5, wy-5, wx+5, wy+5], 
                                 fill=(255, 255, 0), outline=(0, 0, 0))
        
        elif object_type == 'person':
            # Draw person as stick figure
            # Head
            draw.ellipse([x-8, y-size//2, x+8, y-size//2+16], 
                        fill=color, outline=(0, 0, 0), width=2)
            # Body
            draw.line([(x, y-size//2+16), (x, y+size//4)], fill=(0, 0, 0), width=3)
            # Arms
            draw.line([(x, y-size//2+20), (x-size//3, y-size//2+30)], fill=(0, 0, 0), width=2)
            draw.line([(x, y-size//2+20), (x+size//3, y-size//2+30)], fill=(0, 0, 0), width=2)
            # Legs
            draw.line([(x, y+size//4), (x-size//3, y+size//2)], fill=(0, 0, 0), width=2)
            draw.line([(x, y+size//4), (x+size//3, y+size//2)], fill=(0, 0, 0), width=2)
        
        else:
            # Default: draw as circle
            draw.ellipse([x-size//2, y-size//2, x+size//2, y+size//2], 
                        fill=color, outline=(0, 0, 0), width=2)
    
    def _add_noise(self, img: Image.Image, noise_level: float) -> Image.Image:
        """Add noise to image"""
        img_array = np.array(img)
        noise = np.random.normal(0, noise_level * 25, img_array.shape)
        noisy_array = np.clip(img_array + noise, 0, 255).astype(np.uint8)
        return Image.fromarray(noisy_array)
    
    def test_api_with_image(self, image: Image.Image, object_type: str, 
                           expected_count: int) -> Dict:
        """
        Test the API with a generated image
        
        Args:
            image: Generated image
            object_type: Type of object in image
            expected_count: Expected count of objects
            
        Returns:
            API response dictionary
        """
        try:
            # Save image temporarily
            temp_path = f"temp_{int(time.time())}.png"
            image.save(temp_path)
            
            # Prepare API request
            url = f"{self.api_base_url}/api/count"
            files = {'image': open(temp_path, 'rb')}
            data = {'item_type': object_type}
            
            # Make API call
            response = requests.post(url, files=files, data=data, timeout=30)
            
            # Close file
            files['image'].close()
            
            # Clean up temp file
            os.remove(temp_path)
            
            if response.status_code == 200:
                result = response.json()
                result['expected_count'] = expected_count
                result['accuracy'] = 1.0 if result['count'] == expected_count else 0.0
                return result
            else:
                return {
                    'error': f"API call failed with status {response.status_code}",
                    'expected_count': expected_count,
                    'accuracy': 0.0
                }
                
        except Exception as e:
            logger.error(f"Error testing API: {str(e)}")
            return {
                'error': str(e),
                'expected_count': expected_count,
                'accuracy': 0.0
            }
    
    def generate_test_suite(self, num_tests: int = 50) -> List[Dict]:
        """
        Generate a comprehensive test suite
        
        Args:
            num_tests: Number of test cases to generate
            
        Returns:
            List of test results
        """
        test_results = []
        
        logger.info(f"Generating {num_tests} test cases...")
        
        for i in range(num_tests):
            # Randomize test parameters
            object_type = random.choice(self.object_types)
            count = random.randint(1, 10)
            width = random.choice([256, 512, 1024])
            height = random.choice([256, 512, 1024])
            background_type = random.choice(['sky', 'ground', 'white', 'green'])
            clarity_level = random.uniform(0.3, 1.0)
            noise_level = random.uniform(0.0, 0.3)
            rotation_range = (0, random.randint(0, 45))
            
            # Generate image
            img, metadata = self.generate_synthetic_image(
                object_type=object_type,
                count=count,
                width=width,
                height=height,
                background_type=background_type,
                clarity_level=clarity_level,
                noise_level=noise_level,
                rotation_range=rotation_range
            )
            
            # Save image
            filename = f"test_{i:03d}_{object_type}_{count}_{width}x{height}.png"
            filepath = os.path.join(self.output_dir, filename)
            img.save(filepath)
            
            # Test with API
            api_result = self.test_api_with_image(img, object_type, count)
            
            # Combine results
            test_result = {
                'test_id': i,
                'filename': filename,
                'metadata': metadata,
                'api_result': api_result,
                'timestamp': time.time()
            }
            
            test_results.append(test_result)
            
            # Log progress
            if (i + 1) % 10 == 0:
                logger.info(f"Completed {i + 1}/{num_tests} tests")
            
            # Small delay to avoid overwhelming the API
            time.sleep(0.1)
        
        return test_results
    
    def save_test_results(self, test_results: List[Dict], filename: str = "test_results.json"):
        """Save test results to JSON file"""
        filepath = os.path.join(self.output_dir, filename)
        with open(filepath, 'w') as f:
            json.dump(test_results, f, indent=2, default=str)
        logger.info(f"Test results saved to {filepath}")
    
    def analyze_results(self, test_results: List[Dict]) -> Dict:
        """Analyze test results and generate performance report"""
        total_tests = len(test_results)
        successful_tests = sum(1 for r in test_results if 'error' not in r['api_result'])
        accurate_tests = sum(1 for r in test_results if r['api_result'].get('accuracy', 0) == 1.0)
        
        # Calculate accuracy by object type
        accuracy_by_type = {}
        for result in test_results:
            object_type = result['metadata']['object_type']
            if object_type not in accuracy_by_type:
                accuracy_by_type[object_type] = {'total': 0, 'accurate': 0}
            accuracy_by_type[object_type]['total'] += 1
            if result['api_result'].get('accuracy', 0) == 1.0:
                accuracy_by_type[object_type]['accurate'] += 1
        
        # Calculate accuracy by image properties
        accuracy_by_clarity = {}
        accuracy_by_noise = {}
        accuracy_by_size = {}
        
        for result in test_results:
            clarity = result['metadata']['clarity_level']
            noise = result['metadata']['noise_level']
            size = result['metadata']['width'] * result['metadata']['height']
            
            # Clarity bins
            clarity_bin = f"{clarity:.1f}"
            if clarity_bin not in accuracy_by_clarity:
                accuracy_by_clarity[clarity_bin] = {'total': 0, 'accurate': 0}
            accuracy_by_clarity[clarity_bin]['total'] += 1
            if result['api_result'].get('accuracy', 0) == 1.0:
                accuracy_by_clarity[clarity_bin]['accurate'] += 1
            
            # Noise bins
            noise_bin = f"{noise:.1f}"
            if noise_bin not in accuracy_by_noise:
                accuracy_by_noise[noise_bin] = {'total': 0, 'accurate': 0}
            accuracy_by_noise[noise_bin]['total'] += 1
            if result['api_result'].get('accuracy', 0) == 1.0:
                accuracy_by_noise[noise_bin]['accurate'] += 1
            
            # Size bins
            if size < 256*256:
                size_bin = "small"
            elif size < 512*512:
                size_bin = "medium"
            else:
                size_bin = "large"
            
            if size_bin not in accuracy_by_size:
                accuracy_by_size[size_bin] = {'total': 0, 'accurate': 0}
            accuracy_by_size[size_bin]['total'] += 1
            if result['api_result'].get('accuracy', 0) == 1.0:
                accuracy_by_size[size_bin]['accurate'] += 1
        
        # Calculate average response time
        response_times = [r['api_result'].get('processing_time', 0) 
                         for r in test_results if 'processing_time' in r['api_result']]
        avg_response_time = sum(response_times) / len(response_times) if response_times else 0
        
        analysis = {
            'summary': {
                'total_tests': total_tests,
                'successful_tests': successful_tests,
                'success_rate': successful_tests / total_tests if total_tests > 0 else 0,
                'accurate_tests': accurate_tests,
                'accuracy_rate': accurate_tests / total_tests if total_tests > 0 else 0,
                'avg_response_time': avg_response_time
            },
            'accuracy_by_object_type': {
                obj_type: {
                    'accuracy': data['accurate'] / data['total'] if data['total'] > 0 else 0,
                    'total_tests': data['total']
                }
                for obj_type, data in accuracy_by_type.items()
            },
            'accuracy_by_clarity': {
                clarity: {
                    'accuracy': data['accurate'] / data['total'] if data['total'] > 0 else 0,
                    'total_tests': data['total']
                }
                for clarity, data in accuracy_by_clarity.items()
            },
            'accuracy_by_noise': {
                noise: {
                    'accuracy': data['accurate'] / data['total'] if data['total'] > 0 else 0,
                    'total_tests': data['total']
                }
                for noise, data in accuracy_by_noise.items()
            },
            'accuracy_by_size': {
                size: {
                    'accuracy': data['accurate'] / data['total'] if data['total'] > 0 else 0,
                    'total_tests': data['total']
                }
                for size, data in accuracy_by_size.items()
            }
        }
        
        return analysis

def main():
    """Main function to run image generation and testing"""
    generator = ImageGenerator()
    
    # Generate test suite
    test_results = generator.generate_test_suite(num_tests=20)  # Start with 20 tests
    
    # Save results
    generator.save_test_results(test_results)
    
    # Analyze results
    analysis = generator.analyze_results(test_results)
    
    # Print summary
    print("\n" + "="*50)
    print("TEST RESULTS SUMMARY")
    print("="*50)
    print(f"Total tests: {analysis['summary']['total_tests']}")
    print(f"Successful tests: {analysis['summary']['successful_tests']}")
    print(f"Success rate: {analysis['summary']['success_rate']:.2%}")
    print(f"Accurate tests: {analysis['summary']['accurate_tests']}")
    print(f"Accuracy rate: {analysis['summary']['accuracy_rate']:.2%}")
    print(f"Average response time: {analysis['summary']['avg_response_time']:.2f}s")
    
    print("\nAccuracy by Object Type:")
    for obj_type, data in analysis['accuracy_by_object_type'].items():
        print(f"  {obj_type}: {data['accuracy']:.2%} ({data['total_tests']} tests)")
    
    print("\nAccuracy by Image Clarity:")
    for clarity, data in analysis['accuracy_by_clarity'].items():
        print(f"  {clarity}: {data['accuracy']:.2%} ({data['total_tests']} tests)")
    
    print("\nAccuracy by Image Size:")
    for size, data in analysis['accuracy_by_size'].items():
        print(f"  {size}: {data['accuracy']:.2%} ({data['total_tests']} tests)")

if __name__ == "__main__":
    main()
