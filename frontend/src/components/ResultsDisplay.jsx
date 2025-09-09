import React, { useState } from 'react';
import { CheckCircle, Clock, Target, AlertTriangle, Edit3, Save, X } from 'lucide-react';
import { apiService } from '../services/api';

const ResultsDisplay = ({ result, onCorrection }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [correctedCount, setCorrectedCount] = useState(result.count);
    const [feedback, setFeedback] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState('');

    const handleStartEdit = () => {
        setIsEditing(true);
        setCorrectedCount(result.count);
        setFeedback('');
        setError('');
    };

    const handleCancelEdit = () => {
        setIsEditing(false);
        setCorrectedCount(result.count);
        setFeedback('');
        setError('');
    };

    const handleSubmitCorrection = async () => {
        if (correctedCount === result.count && !feedback.trim()) {
            setError('Please either change the count or provide feedback');
            return;
        }

        setIsSubmitting(true);
        setError('');

        try {
            await apiService.correctCount(result.id, parseInt(correctedCount), feedback);
            onCorrection && onCorrection(result.id, correctedCount, feedback);
            setIsEditing(false);
        } catch (err) {
            setError(err.response?.data?.error || 'Failed to submit correction');
        } finally {
            setIsSubmitting(false);
        }
    };

    const getConfidenceColor = (confidence) => {
        if (confidence >= 0.8) return 'text-green-600 bg-green-100';
        if (confidence >= 0.6) return 'text-yellow-600 bg-yellow-100';
        return 'text-red-600 bg-red-100';
    };

    const formatTime = (seconds) => {
        return `${seconds.toFixed(1)}s`;
    };

    return (
        <div className="bg-white rounded-lg shadow-lg p-6 space-y-6">
            <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-gray-900">Results</h2>
                <div className="flex items-center space-x-2 text-green-600">
                    <CheckCircle className="h-5 w-5" />
                    <span className="text-sm font-medium">Analysis Complete</span>
                </div>
            </div>

            {/* Main Results Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {/* Count Result */}
                <div className="bg-gradient-to-br from-primary-50 to-primary-100 rounded-lg p-6 text-center">
                    <Target className="h-8 w-8 text-primary-600 mx-auto mb-2" />
                    <div className="text-3xl font-bold text-primary-900">
                        {result.count}
                    </div>
                    <div className="text-sm text-primary-700 capitalize">
                        {result.item_type}{result.count !== 1 ? 's' : ''} found
                    </div>
                </div>

                {/* Confidence Score */}
                <div className="bg-gray-50 rounded-lg p-6 text-center">
                    <div className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getConfidenceColor(result.confidence_score)}`}>
                        {(result.confidence_score * 100).toFixed(0)}% confident
                    </div>
                    <div className="mt-2 text-xs text-gray-500">
                        AI Confidence Level
                    </div>
                </div>

                {/* Processing Time */}
                <div className="bg-gray-50 rounded-lg p-6 text-center">
                    <Clock className="h-6 w-6 text-gray-600 mx-auto mb-2" />
                    <div className="text-lg font-semibold text-gray-900">
                        {formatTime(result.processing_time)}
                    </div>
                    <div className="text-xs text-gray-500">
                        Processing Time
                    </div>
                </div>
            </div>

            {/* Image Display */}
            {result.image_path && (
                <div className="text-center">
                    <h3 className="text-lg font-medium text-gray-900 mb-3">Analyzed Image</h3>
                    <img
                        src={apiService.getImageUrl(result.image_path)}
                        alt="Analyzed"
                        className="max-w-full max-h-96 mx-auto rounded-lg shadow-sm border"
                    />
                </div>
            )}

            {/* Detailed Results */}
            {result.details && (
                <div className="bg-gray-50 rounded-lg p-4">
                    <h3 className="text-lg font-medium text-gray-900 mb-3">Analysis Details</h3>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <span className="font-medium text-gray-700">Total Segments:</span>
                            <span className="ml-2 text-gray-900">{result.details.total_segments}</span>
                        </div>
                        <div>
                            <span className="font-medium text-gray-700">Target Type:</span>
                            <span className="ml-2 text-gray-900 capitalize">{result.details.target_type}</span>
                        </div>
                    </div>
                </div>
            )}

            {/* Correction Interface */}
            <div className="border-t pt-6">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="text-lg font-medium text-gray-900">Feedback & Corrections</h3>
                    {!isEditing && (
                        <button
                            onClick={handleStartEdit}
                            className="flex items-center space-x-2 px-3 py-2 text-sm font-medium text-primary-600 hover:text-primary-700 hover:bg-primary-50 rounded-md transition-colors"
                        >
                            <Edit3 className="h-4 w-4" />
                            <span>Correct Count</span>
                        </button>
                    )}
                </div>

                {isEditing ? (
                    <div className="space-y-4">
                        <div>
                            <label htmlFor="corrected-count" className="block text-sm font-medium text-gray-700 mb-1">
                                Correct Count
                            </label>
                            <input
                                id="corrected-count"
                                type="number"
                                min="0"
                                value={correctedCount}
                                onChange={(e) => setCorrectedCount(e.target.value)}
                                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                                disabled={isSubmitting}
                            />
                        </div>

                        <div>
                            <label htmlFor="feedback" className="block text-sm font-medium text-gray-700 mb-1">
                                Feedback (Optional)
                            </label>
                            <textarea
                                id="feedback"
                                rows={3}
                                value={feedback}
                                onChange={(e) => setFeedback(e.target.value)}
                                placeholder="Tell us why the count was incorrect..."
                                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                                disabled={isSubmitting}
                            />
                        </div>

                        {error && (
                            <div className="flex items-center space-x-2 text-red-600">
                                <AlertTriangle className="h-4 w-4" />
                                <span className="text-sm">{error}</span>
                            </div>
                        )}

                        <div className="flex items-center space-x-3">
                            <button
                                onClick={handleSubmitCorrection}
                                disabled={isSubmitting}
                                className="flex items-center space-x-2 px-4 py-2 bg-primary-600 text-white text-sm font-medium rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                {isSubmitting ? (
                                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                                ) : (
                                    <Save className="h-4 w-4" />
                                )}
                                <span>{isSubmitting ? 'Submitting...' : 'Submit Correction'}</span>
                            </button>

                            <button
                                onClick={handleCancelEdit}
                                disabled={isSubmitting}
                                className="flex items-center space-x-2 px-4 py-2 border border-gray-300 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
                            >
                                <X className="h-4 w-4" />
                                <span>Cancel</span>
                            </button>
                        </div>
                    </div>
                ) : (
                    <p className="text-sm text-gray-600">
                        Was this count accurate? You can help improve our AI by providing corrections and feedback.
                    </p>
                )}
            </div>
        </div>
    );
};

export default ResultsDisplay;
