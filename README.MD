# AI Engineering Lab - Object Counting Application


## Group

| Name | Email | FIM ID |
|------|-------|---------|
| Mohamed Abdikafi Abdullahi | abdull07@ads.uni-passau.de | Abdullahi |
| Mithulram Gunasekaran | gunase01@ads.uni-passau.de | gunasekaran |
| Cem Girgin | girgin02@ads.uni-passau.de | girgin |

## Overview
This is an AI-powered application that can count objects in images. It works by using three different AI models that work together:

1. First, it uses SAM (Segment Anything Model) to identify and separate different objects in the image
2. Then, it uses ResNet-50 to classify what type of object each segment is
3. Finally, it uses DistilBERT to refine and standardize the labels

The app gives users a simple web interface where they can upload images, choose what type of object they want to count, and get an automated count. Users can also provide feedback if the count isn't quite right.

## What This App Can Do
- Upload images in common formats (PNG, JPG, JPEG, GIF, BMP)
- Automatically detect and separate objects in images
- Count how many of a specific type of object are in an image
- Let users correct the count if the AI gets it wrong
- Save all results and corrections in a database
- Run comprehensive tests to make sure everything works
- Automatically test and deploy updates
- Provide a user-friendly web interface

## Supported Object Types
- car
- cat
- tree
- dog
- building
- person
- sky
- ground
- hardware

## What You Need to Run This
- Python 3.8 or newer
- At least 4GB of RAM (the AI models need this much memory)
- Git (to download the code)
- Node.js 16 or newer (for the web interface)

## Application Architecture

![System Architecture](docs/architecture_diagram.jpg)

*Figure 1: Complete system architecture showing the four-layer design with AI processing pipeline*

## How to Get This Running

### Step 1: Download the Code
```bash
git clone <your-repository-url>
cd ai-engineering-lab
```

### Step 2: Set Up the Backend
```bash
# Create a Python virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows, use: venv\Scripts\activate

# Install the Python packages we need
pip install -r requirements.txt
```

### Step 3: Set Up the Web Interface
```bash
# Go to the frontend folder
cd frontend

# Install the web packages
npm install
```

### Step 4: Start Everything Up
```bash
# Open a new terminal and start the backend server
cd backend
python app.py

# Open another terminal and start the web interface
cd frontend
npm start
```

Once everything is running, you can access:
- The web interface at: http://localhost:3000
- The backend API at: http://localhost:5000

**Important**: The first time you run this, it will download some AI models (about 375MB), so make sure you have a good internet connection.



## How the App Talks to the Server (API)

### POST /api/count
This is how you send an image to be counted.

**What you send:**
- `image`: The image file you want to analyze
- `item_type`: What kind of object you want to count (like "car" or "dog")

**What you get back:**
```json
{
  "id": "uuid",
  "count": 3,
  "confidence_score": 0.85,
  "processing_time": 2.5,
  "item_type": "car",
  "image_path": "/uploads/filename.png",
  "details": {...}
}
```

### POST /api/correct
This is how you tell the app if it counted wrong.

**What you send:**
```json
{
  "result_id": "uuid",
  "corrected_count": 5,
  "user_feedback": "Optional feedback"
}
```

### GET /api/results
This gets you a list of all the counting jobs you've done.

**Optional filters:**
- `item_type`: Only show results for a specific object type
- `limit`: How many results to show (default: 50)
- `offset`: Skip some results (for pagination)

### GET /api/health
This just checks if the server is running properly.





## About This Project
This is our final project for the AI Engineering Lab course at the University of Passau. We built this object counting app to learn about AI models, web development, and how to put everything together into a working application.

## Our Team
We're a group of three students working together on this project. Each of us contributed different parts to make this app work.
