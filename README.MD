# AI Object Counting App - Week 2

A comprehensive AI-powered object counting application with Flutter frontend, Flask backend, monitoring dashboard, and few-shot learning capabilities.

## 🚀 Quick Start

### One-Line Demo Run
```bash
./run_local.sh
```

### Manual Setup
1. **Clone and checkout** the week2 branch:
   ```bash
   git clone https://github.com/mithulram/ai-engineering-lab-project.git
   cd ai-engineering-lab-project
   git checkout week2
   ```
2. **Follow** the complete setup guide: [`SETUP_GUIDE.md`](SETUP_GUIDE.md)
3. **Or use** the quick commands: [`QUICK_START.md`](QUICK_START.md)

### Health Check
```bash
curl http://127.0.0.1:5001/api/health
```

### Example API Call
```bash
curl -X POST http://127.0.0.1:5001/api/count \
  -F "image=@sample_image.jpg" \
  -F "item_type=car"
```

### Monitoring Setup
```bash
cd monitoring && docker-compose up -d
# Access Grafana: http://127.0.0.1:3000 (admin/admin)
```

### Memory Optimization
For systems with limited RAM (8GB or less), the application automatically uses low memory mode:
- **LOCAL_LOW_MEMORY=1**: Enables lazy loading and lightweight models
- **Automatic Fallbacks**: Uses mock models when full models can't load
- **Optimized for M1 MacBook Air**: Tested and optimized for 8GB RAM systems

## 📁 Project Structure

```
ai-engineering-lab-project/
├── app.py                    # Main Flask backend API
├── monitoring_server.py      # Monitoring dashboard server
├── few_shot_learning.py      # Few-shot learning implementation
├── image_generator.py        # Automated image generation
├── requirements.txt          # Python dependencies
├── flutter_frontend/         # Flutter web application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── monitoring_page.dart
│   │   ├── few_shot_learning_page.dart
│   │   └── ...
│   └── pubspec.yaml
├── start_app.sh             # Automated startup script
├── stop_app.sh              # Automated cleanup script
└── RUN_INSTRUCTIONS.md      # Detailed setup and run guide
```

## 🌟 Features

- **Object Counting**: Upload images and count objects using AI
- **Real-time Monitoring**: Live metrics dashboard with Prometheus-compatible endpoints
- **Few-Shot Learning**: Learn new object types with minimal training data
- **Image Generation**: Automated test image generation and API testing
- **Performance Analysis**: Comprehensive performance metrics and reporting
- **Flutter Web UI**: Modern, responsive web interface

## 🛠️ Technology Stack

- **Backend**: Python Flask, SQLAlchemy, PyTorch, Scikit-learn
- **Frontend**: Flutter Web, Dart
- **Monitoring**: Custom Python monitoring server with OpenMetrics
- **AI/ML**: SAM (Segment Anything Model), ResNet, Few-shot learning

## 📖 Documentation

- **[RUN_INSTRUCTIONS.md](RUN_INSTRUCTIONS.md)** - Complete setup and run guide
- **[architecture_diagram_week2.md](architecture_diagram_week2.md)** - System architecture
- **[performance_analysis_report.md](performance_analysis_report.md)** - Performance analysis

## 🎯 Access URLs

Once running:
- **Flutter App**: http://localhost:3000
- **Backend API**: http://localhost:5001
- **Monitoring Dashboard**: http://localhost:8080/dashboard

## 🆘 Need Help?

1. Check the detailed instructions in [`RUN_INSTRUCTIONS.md`](RUN_INSTRUCTIONS.md)
2. Verify all prerequisites are installed
3. Ensure you're in the correct project directory
4. Check that required ports (3000, 5001, 8080) are available

## 📝 Notes

- The application uses real AI models (SAM, ResNet-50, DistilBERT) for object counting
- All core functionality works as designed
- Monitoring shows real metrics from the backend
- Few-shot learning creates actual model files for persistence

---

**Happy Object Counting! 🎉**