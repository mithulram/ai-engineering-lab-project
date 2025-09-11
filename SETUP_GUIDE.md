# 🚀 AI Object Counting App - Complete Setup Guide

## 📋 Prerequisites

Before running this project, ensure you have the following installed:

- **Python 3.9+** with pip
- **Flutter SDK** (for web development)
- **Git** (for version control)
- **Chrome/Edge browser** (for Flutter web)

## 🔧 Step-by-Step Setup Instructions

### 1. Clone and Checkout the Repository

```bash
# Clone the repository
git clone https://github.com/mithulram/ai-engineering-lab-project.git

# Navigate to the project directory
cd ai-engineering-lab-project

# Checkout the week2 branch
git checkout week2

# Verify you're on the correct branch
git branch
```

### 2. Install Python Dependencies

```bash
# Install required Python packages
pip3 install -r requirements.txt

# If you encounter permission issues, use:
pip3 install --user -r requirements.txt
```

### 3. Fix HuggingFace Cache Issues (Important!)

```bash
# Run the cache fix script to resolve model loading issues
python3 fix_huggingface_cache.py
```

### 4. Install Flutter Dependencies

```bash
# Navigate to Flutter frontend directory
cd flutter_frontend

# Install Flutter dependencies
flutter pub get

# Go back to project root
cd ..
```

### 5. Start the Application

#### Option A: Using the Automated Script (Recommended)

```bash
# Make the script executable
chmod +x start_app.sh

# Run the automated startup script
./start_app.sh
```

#### Option B: Manual Startup (3 separate terminals)

**Terminal 1 - Start the AI Backend:**
```bash
# Set HuggingFace cache environment variables
export HF_HOME=/Users/anuvidhyas/Desktop/Mithul/Week\ 2/ai-engineering-lab-project/.huggingface_cache
export TRANSFORMERS_CACHE=/Users/anuvidhyas/Desktop/Mithul/Week\ 2/ai-engineering-lab-project/.huggingface_cache

# Start the Flask backend with real AI
python3 app.py
```

**Terminal 2 - Start the Monitoring Server:**
```bash
# Start the enhanced monitoring dashboard
python3 monitoring_server_enhanced.py
```

**Terminal 3 - Start the Flutter Frontend:**
```bash
# Navigate to Flutter directory
cd flutter_frontend

# Start Flutter web app
flutter run -d web-server --web-port 3000
```

## 🌐 Access URLs

Once all services are running, you can access:

- **🎨 Flutter Web App**: http://localhost:3000
- **🤖 AI Backend API**: http://localhost:5001
- **📊 Enhanced Monitoring Dashboard**: http://localhost:8080/dashboard
- **📈 Metrics API**: http://localhost:8080/api/metrics

## 🧪 Testing the Application

### 1. Test Backend Health
```bash
curl http://localhost:5001/api/health
```

### 2. Test Monitoring Dashboard
```bash
curl http://localhost:8080/api/metrics
```

### 3. Test Object Counting
```bash
# Upload an image and count objects
curl -X POST -F "image=@test_images/your_image.jpg" -F "object_type=car" http://localhost:5001/api/count
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. HuggingFace Permission Error
```bash
# If you see permission errors, run:
python3 fix_huggingface_cache.py

# Or manually set environment variables:
export HF_HOME=$(pwd)/.huggingface_cache
export TRANSFORMERS_CACHE=$(pwd)/.huggingface_cache
```

#### 2. Port Already in Use
```bash
# Kill processes using the ports
pkill -f "python3 app.py"
pkill -f "python3 monitoring_server"
pkill -f "flutter run"

# Or use specific port killing:
lsof -ti:3000 | xargs kill -9
lsof -ti:5001 | xargs kill -9
lsof -ti:8080 | xargs kill -9
```

#### 3. Flutter Web Issues
```bash
# Clean and rebuild Flutter
cd flutter_frontend
flutter clean
flutter pub get
flutter run -d web-server --web-port 3000
```

#### 4. Python Dependencies Issues
```bash
# Upgrade pip and reinstall
pip3 install --upgrade pip
pip3 install -r requirements.txt --force-reinstall
```

## 📱 Features Available

### 🎯 Core Features
- **Real AI Object Counting** using SAM, ResNet-50, and DistilBERT
- **Image Upload & Processing** with drag-and-drop interface
- **Real-time Results** with confidence scores and segment details
- **History Tracking** of all processed images
- **Few-shot Learning** for custom object types

### 📊 Monitoring & Analytics
- **Enhanced Monitoring Dashboard** with beautiful UI
- **Real-time Performance Metrics** (accuracy, precision, recall)
- **System Health Monitoring** (API, database, AI models)
- **Interactive Charts** showing performance trends
- **Mobile-responsive Design**

### 🔧 Technical Features
- **Fallback Mode** when AI models fail to load
- **Prometheus-compatible Metrics** for monitoring
- **RESTful API** with comprehensive endpoints
- **Error Handling** with user-friendly messages
- **Background Processing** for heavy AI operations

## 🛑 Stopping the Application

```bash
# Use the stop script
./stop_app.sh

# Or manually kill processes
pkill -f "python3 app.py"
pkill -f "python3 monitoring_server"
pkill -f "flutter run"
```

## 📁 Project Structure

```
ai-engineering-lab-project/
├── app.py                          # Main Flask backend
├── model_pipeline.py               # AI model pipeline
├── monitoring_server_enhanced.py   # Enhanced monitoring dashboard
├── flutter_frontend/               # Flutter web application
├── test_images/                    # Sample images for testing
├── requirements.txt                # Python dependencies
├── start_app.sh                    # Automated startup script
├── stop_app.sh                     # Stop script
└── SETUP_GUIDE.md                  # This setup guide
```

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ **Flutter App**: Shows "Backend Status: Healthy" in the top bar
2. ✅ **Backend API**: Returns 200 status on health check
3. ✅ **Monitoring Dashboard**: Shows real-time metrics and charts
4. ✅ **Object Counting**: Successfully processes uploaded images
5. ✅ **All Services**: Running on their respective ports (3000, 5001, 8080)

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs** in each terminal for error messages
2. **Verify all services** are running on correct ports
3. **Run the cache fix script** if HuggingFace models fail
4. **Check the monitoring dashboard** for system health
5. **Review this setup guide** for troubleshooting steps

---

**🎯 Ready to count objects with AI!** Upload an image, select an object type, and watch the magic happen! 🚀
