import React, { useState, useRef } from 'react';
import { Upload, Image, X, AlertCircle } from 'lucide-react';
import { validateImageFile, OBJECT_TYPES } from '../services/api';

const ImageUpload = ({ onUpload, isLoading }) => {
    const [selectedFile, setSelectedFile] = useState(null);
    const [selectedType, setSelectedType] = useState('');
    const [dragActive, setDragActive] = useState(false);
    const [error, setError] = useState('');
    const [previewUrl, setPreviewUrl] = useState('');
    const fileInputRef = useRef(null);

    const handleDrag = (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (e.type === 'dragenter' || e.type === 'dragover') {
            setDragActive(true);
        } else if (e.type === 'dragleave') {
            setDragActive(false);
        }
    };

    const handleDrop = (e) => {
        e.preventDefault();
        e.stopPropagation();
        setDragActive(false);

        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            handleFileSelect(e.dataTransfer.files[0]);
        }
    };

    const handleFileSelect = (file) => {
        try {
            validateImageFile(file);
            setSelectedFile(file);
            setError('');

            // Create preview URL
            const url = URL.createObjectURL(file);
            setPreviewUrl(url);
        } catch (err) {
            setError(err.message);
            setSelectedFile(null);
            setPreviewUrl('');
        }
    };

    const handleFileInput = (e) => {
        if (e.target.files && e.target.files[0]) {
            handleFileSelect(e.target.files[0]);
        }
    };

    const clearFile = () => {
        setSelectedFile(null);
        setPreviewUrl('');
        setError('');
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    const handleSubmit = () => {
        if (!selectedFile) {
            setError('Please select an image file');
            return;
        }
        if (!selectedType) {
            setError('Please select an object type to count');
            return;
        }

        onUpload(selectedFile, selectedType);
    };

    return (
        <div className="bg-white rounded-lg shadow-lg p-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Upload Image for Object Counting</h2>

            {/* Object Type Selection */}
            <div className="mb-6">
                <label htmlFor="object-type" className="block text-sm font-medium text-gray-700 mb-2">
                    What objects do you want to count?
                </label>
                <select
                    id="object-type"
                    value={selectedType}
                    onChange={(e) => setSelectedType(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                    disabled={isLoading}
                >
                    <option value="">Select object type...</option>
                    {OBJECT_TYPES.map((type) => (
                        <option key={type} value={type}>
                            {type.charAt(0).toUpperCase() + type.slice(1)}
                        </option>
                    ))}
                </select>
            </div>

            {/* File Upload Area */}
            <div
                className={`relative border-2 border-dashed rounded-lg p-6 text-center transition-colors ${dragActive
                        ? 'border-primary-500 bg-primary-50'
                        : selectedFile
                            ? 'border-green-500 bg-green-50'
                            : 'border-gray-300 hover:border-gray-400'
                    }`}
                onDragEnter={handleDrag}
                onDragLeave={handleDrag}
                onDragOver={handleDrag}
                onDrop={handleDrop}
            >
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileInput}
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                    disabled={isLoading}
                />

                {selectedFile ? (
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <div className="flex items-center space-x-3">
                                <Image className="h-6 w-6 text-green-500" />
                                <span className="text-sm font-medium text-gray-900">{selectedFile.name}</span>
                                <span className="text-xs text-gray-500">
                                    ({(selectedFile.size / 1024 / 1024).toFixed(2)} MB)
                                </span>
                            </div>
                            <button
                                onClick={clearFile}
                                className="p-1 text-gray-400 hover:text-gray-600"
                                disabled={isLoading}
                            >
                                <X className="h-5 w-5" />
                            </button>
                        </div>

                        {previewUrl && (
                            <div className="mt-4">
                                <img
                                    src={previewUrl}
                                    alt="Preview"
                                    className="max-w-full max-h-64 mx-auto rounded-lg shadow-sm"
                                />
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="space-y-4">
                        <Upload className="mx-auto h-12 w-12 text-gray-400" />
                        <div className="space-y-2">
                            <p className="text-lg font-medium text-gray-900">
                                Drop your image here, or click to browse
                            </p>
                            <p className="text-sm text-gray-500">
                                Supports PNG, JPG, JPEG, GIF, BMP up to 16MB
                            </p>
                        </div>
                    </div>
                )}
            </div>

            {/* Error Message */}
            {error && (
                <div className="mt-4 flex items-center space-x-2 text-red-600">
                    <AlertCircle className="h-5 w-5" />
                    <span className="text-sm">{error}</span>
                </div>
            )}

            {/* Submit Button */}
            <div className="mt-6">
                <button
                    onClick={handleSubmit}
                    disabled={!selectedFile || !selectedType || isLoading}
                    className={`w-full flex items-center justify-center px-4 py-3 border border-transparent text-base font-medium rounded-md text-white transition-colors ${!selectedFile || !selectedType || isLoading
                            ? 'bg-gray-300 cursor-not-allowed'
                            : 'bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500'
                        }`}
                >
                    {isLoading ? (
                        <div className="flex items-center space-x-2">
                            <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                            <span>Processing Image...</span>
                        </div>
                    ) : (
                        'Count Objects'
                    )}
                </button>
            </div>
        </div>
    );
};

export default ImageUpload;
