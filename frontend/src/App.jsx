import React, { useState, useEffect } from 'react';
import { Brain, History, Home, Activity, AlertCircle } from 'lucide-react';
import ImageUpload from './components/ImageUpload';
import ResultsDisplay from './components/ResultsDisplay';
import HistoryView from './components/HistoryView';
import { apiService } from './services/api';

function App() {
  const [currentView, setCurrentView] = useState('upload');
  const [currentResult, setCurrentResult] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState('');
  const [backendStatus, setBackendStatus] = useState('checking');

  // Check backend health on startup
  useEffect(() => {
    checkBackendHealth();
  }, []);

  const checkBackendHealth = async () => {
    try {
      await apiService.healthCheck();
      setBackendStatus('healthy');
    } catch (err) {
      setBackendStatus('error');
      setError('Cannot connect to backend server. Please make sure the Flask server is running on http://localhost:5001');
    }
  };

  const handleImageUpload = async (imageFile, itemType) => {
    setIsProcessing(true);
    setError('');

    try {
      const result = await apiService.countObjects(imageFile, itemType);
      setCurrentResult(result);
      setCurrentView('results');
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to process image. Please try again.');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleCorrection = (resultId, correctedCount, feedback) => {
    // Update the current result with correction info
    if (currentResult && currentResult.id === resultId) {
      setCurrentResult({
        ...currentResult,
        corrected_count: correctedCount,
        user_feedback: feedback,
      });
    }
  };

  const NavigationTab = ({ id, icon: Icon, label, isActive, onClick }) => (
    <button
      onClick={() => onClick(id)}
      className={`flex items-center space-x-2 px-4 py-2 rounded-lg font-medium transition-colors ${isActive
        ? 'bg-primary-600 text-white'
        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
        }`}
    >
      <Icon className="h-5 w-5" />
      <span>{label}</span>
    </button>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center space-x-3">
              <Brain className="h-8 w-8 text-primary-600" />
              <div>
                <h1 className="text-xl font-bold text-gray-900">AI Object Counter</h1>
                <p className="text-xs text-gray-500">Powered by SAM, ResNet-50 & DistilBERT</p>
              </div>
            </div>

            {/* Backend Status Indicator */}
            <div className="flex items-center space-x-2">
              <Activity className={`h-4 w-4 ${backendStatus === 'healthy' ? 'text-green-500' :
                backendStatus === 'error' ? 'text-red-500' : 'text-yellow-500'
                }`} />
              <span className={`text-sm font-medium ${backendStatus === 'healthy' ? 'text-green-600' :
                backendStatus === 'error' ? 'text-red-600' : 'text-yellow-600'
                }`}>
                {backendStatus === 'healthy' ? 'Connected' :
                  backendStatus === 'error' ? 'Offline' : 'Checking...'}
              </span>
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-2 py-4">
            <NavigationTab
              id="upload"
              icon={Home}
              label="Upload & Count"
              isActive={currentView === 'upload'}
              onClick={setCurrentView}
            />
            <NavigationTab
              id="results"
              icon={Brain}
              label="Results"
              isActive={currentView === 'results'}
              onClick={setCurrentView}
            />
            <NavigationTab
              id="history"
              icon={History}
              label="History"
              isActive={currentView === 'history'}
              onClick={setCurrentView}
            />
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Global Error Message */}
        {error && (
          <div className="mb-6 flex items-center space-x-2 p-4 bg-red-50 border border-red-200 rounded-lg">
            <AlertCircle className="h-5 w-5 text-red-600 flex-shrink-0" />
            <span className="text-sm text-red-700">{error}</span>
            <button
              onClick={() => setError('')}
              className="ml-auto text-red-600 hover:text-red-800"
            >
              ×
            </button>
          </div>
        )}

        {/* Backend Offline Warning */}
        {backendStatus === 'error' && (
          <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div className="flex items-center space-x-2">
              <AlertCircle className="h-5 w-5 text-yellow-600" />
              <h3 className="font-medium text-yellow-800">Backend Server Offline</h3>
            </div>
            <p className="mt-2 text-sm text-yellow-700">
              To use the AI object counting features, please start the Flask backend server:
            </p>
            <div className="mt-2 p-2 bg-yellow-100 rounded text-xs font-mono text-yellow-800">
              cd backend && python app.py
            </div>
            <button
              onClick={checkBackendHealth}
              className="mt-3 text-sm text-yellow-700 underline hover:text-yellow-800"
            >
              Check connection again
            </button>
          </div>
        )}

        {/* Content Views */}
        {currentView === 'upload' && (
          <div className="space-y-8">
            <ImageUpload
              onUpload={handleImageUpload}
              isLoading={isProcessing}
            />

            {/* How it works */}
            <div className="bg-white rounded-lg shadow-lg p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">How It Works</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center mx-auto mb-3">
                    <span className="text-primary-600 font-bold">1</span>
                  </div>
                  <h3 className="font-medium text-gray-900 mb-2">Segment</h3>
                  <p className="text-sm text-gray-600">SAM identifies and separates objects in your image</p>
                </div>
                <div className="text-center">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center mx-auto mb-3">
                    <span className="text-primary-600 font-bold">2</span>
                  </div>
                  <h3 className="font-medium text-gray-900 mb-2">Classify</h3>
                  <p className="text-sm text-gray-600">ResNet-50 determines what each object is</p>
                </div>
                <div className="text-center">
                  <div className="w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center mx-auto mb-3">
                    <span className="text-primary-600 font-bold">3</span>
                  </div>
                  <h3 className="font-medium text-gray-900 mb-2">Refine</h3>
                  <p className="text-sm text-gray-600">DistilBERT standardizes and counts your target objects</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {currentView === 'results' && currentResult && (
          <ResultsDisplay
            result={currentResult}
            onCorrection={handleCorrection}
          />
        )}

        {currentView === 'results' && !currentResult && (
          <div className="bg-white rounded-lg shadow-lg p-12 text-center">
            <Brain className="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h2 className="text-xl font-medium text-gray-900 mb-2">No Results Yet</h2>
            <p className="text-gray-600 mb-6">Upload an image to see counting results here.</p>
            <button
              onClick={() => setCurrentView('upload')}
              className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
            >
              Upload Image
            </button>
          </div>
        )}

        {currentView === 'history' && <HistoryView />}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="text-center text-sm text-gray-500">
            <p>AI Engineering Lab - University of Passau</p>
            <p className="mt-1">Built by Mohamed Abdikafi Abdullahi, Mithulram Gunasekaran, and Cem Girgin</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
