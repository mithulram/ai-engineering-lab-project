#!/usr/bin/env python3
"""
Script to fix HuggingFace cache permissions and enable real AI models.
"""

import os
import shutil
import subprocess
import sys

def fix_huggingface_cache():
    """Fix HuggingFace cache directory permissions and clear any lock files."""
    
    print("🔧 Fixing HuggingFace cache permissions...")
    
    # Get cache directory
    cache_dir = os.path.join(os.getcwd(), ".huggingface_cache")
    huggingface_cache = os.path.expanduser("~/.cache/huggingface")
    
    print(f"Local cache dir: {cache_dir}")
    print(f"Global cache dir: {huggingface_cache}")
    
    # Create local cache directory
    os.makedirs(cache_dir, exist_ok=True)
    print(f"✅ Created local cache directory: {cache_dir}")
    
    # Fix permissions for global cache
    if os.path.exists(huggingface_cache):
        try:
            # Remove any lock files
            for root, dirs, files in os.walk(huggingface_cache):
                for file in files:
                    if file.endswith('.lock') or 'token' in file:
                        file_path = os.path.join(root, file)
                        try:
                            os.remove(file_path)
                            print(f"🗑️  Removed lock file: {file_path}")
                        except Exception as e:
                            print(f"⚠️  Could not remove {file_path}: {e}")
            
            # Fix permissions
            os.chmod(huggingface_cache, 0o755)
            print(f"✅ Fixed permissions for: {huggingface_cache}")
            
        except Exception as e:
            print(f"⚠️  Could not fix global cache permissions: {e}")
    
    # Set environment variables for HuggingFace
    os.environ['HF_HOME'] = cache_dir
    os.environ['TRANSFORMERS_CACHE'] = cache_dir
    os.environ['HF_DATASETS_CACHE'] = cache_dir
    
    print("✅ Set HuggingFace environment variables")
    
    return True

def install_requirements():
    """Install required packages for real AI models."""
    
    print("📦 Installing required packages...")
    
    packages = [
        "torch",
        "torchvision", 
        "transformers",
        "scikit-learn",
        "pillow",
        "numpy",
        "matplotlib"
    ]
    
    for package in packages:
        try:
            print(f"Installing {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            print(f"✅ Installed {package}")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install {package}: {e}")

def test_model_loading():
    """Test if models can be loaded successfully."""
    
    print("🧪 Testing model loading...")
    
    try:
        from transformers import AutoImageProcessor, AutoModelForImageClassification, pipeline
        
        # Test ResNet-50
        print("Loading ResNet-50...")
        processor = AutoImageProcessor.from_pretrained("microsoft/resnet-50")
        model = AutoModelForImageClassification.from_pretrained("microsoft/resnet-50")
        print("✅ ResNet-50 loaded successfully")
        
        # Test DistilBERT
        print("Loading DistilBERT...")
        classifier = pipeline(
            "zero-shot-classification", 
            model="typeform/distilbert-base-uncased-mnli"
        )
        print("✅ DistilBERT loaded successfully")
        
        return True
        
    except Exception as e:
        print(f"❌ Model loading failed: {e}")
        return False

def main():
    """Main function to fix HuggingFace cache and enable real AI."""
    
    print("🚀 Enabling Real AI Models for Object Counting")
    print("=" * 50)
    
    # Step 1: Fix cache permissions
    if not fix_huggingface_cache():
        print("❌ Failed to fix cache permissions")
        return False
    
    # Step 2: Install requirements
    install_requirements()
    
    # Step 3: Test model loading
    if test_model_loading():
        print("\n🎉 SUCCESS! Real AI models are now enabled!")
        print("You can now run the application with real AI instead of demo mode.")
        return True
    else:
        print("\n⚠️  Model loading failed. The system will still work in demo mode.")
        print("You may need to:")
        print("1. Check your internet connection")
        print("2. Ensure you have enough disk space")
        print("3. Try running this script again")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
