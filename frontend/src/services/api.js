import axios from 'axios';

// Create axios instance with base URL
const api = axios.create({
    baseURL: 'http://localhost:5001/api',
    timeout: 60000, // 60 seconds timeout for AI processing
    headers: {
        'Content-Type': 'application/json',
    },
});

// Request interceptor for logging
api.interceptors.request.use(
    (config) => {
        console.log(`Making ${config.method.toUpperCase()} request to ${config.url}`);
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Response interceptor for error handling
api.interceptors.response.use(
    (response) => {
        return response;
    },
    (error) => {
        console.error('API Error:', error.response?.data || error.message);
        return Promise.reject(error);
    }
);

// API Service functions
export const apiService = {
    // Upload image and count objects
    countObjects: async (imageFile, itemType) => {
        const formData = new FormData();
        formData.append('image', imageFile);
        formData.append('item_type', itemType);

        const response = await api.post('/count', formData, {
            headers: {
                'Content-Type': 'multipart/form-data',
            },
        });

        return response.data;
    },

    // Submit count correction
    correctCount: async (resultId, correctedCount, userFeedback = '') => {
        const response = await api.post('/correct', {
            result_id: resultId,
            corrected_count: correctedCount,
            user_feedback: userFeedback,
        });

        return response.data;
    },

    // Get results history
    getResults: async (filters = {}) => {
        const params = new URLSearchParams();

        if (filters.itemType) {
            params.append('item_type', filters.itemType);
        }
        if (filters.limit) {
            params.append('limit', filters.limit);
        }
        if (filters.offset) {
            params.append('offset', filters.offset);
        }

        const response = await api.get(`/results?${params}`);
        return response.data;
    },

    // Health check
    healthCheck: async () => {
        const response = await api.get('/health');
        return response.data;
    },

    // Get uploaded file URL
    getImageUrl: (imagePath) => {
        // Remove the 'uploads/' prefix if present since the backend endpoint serves from uploads folder
        const filename = imagePath.includes('/') ? imagePath.split('/').pop() : imagePath;
        return `http://localhost:5001/uploads/${filename}`;
    },
};

// Supported object types (from backend)
export const OBJECT_TYPES = [
    'car',
    'cat',
    'tree',
    'dog',
    'building',
    'person',
    'sky',
    'ground',
    'hardware'
];

// File validation
export const validateImageFile = (file) => {
    const allowedTypes = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/bmp'];
    const maxSize = 16 * 1024 * 1024; // 16MB

    if (!allowedTypes.includes(file.type)) {
        throw new Error('Invalid file type. Please upload PNG, JPG, JPEG, GIF, or BMP files.');
    }

    if (file.size > maxSize) {
        throw new Error('File too large. Maximum size is 16MB.');
    }

    return true;
};

export default api;
