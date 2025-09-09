import React, { useState, useEffect } from 'react';
import { Clock, Filter, ChevronLeft, ChevronRight, Image, Target, AlertCircle } from 'lucide-react';
import { apiService, OBJECT_TYPES } from '../services/api';

const HistoryView = () => {
    const [results, setResults] = useState([]);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState('');
    const [filters, setFilters] = useState({
        itemType: '',
        limit: 20,
        offset: 0,
    });
    const [pagination, setPagination] = useState({
        total: 0,
        hasMore: false,
    });

    const loadResults = async (newFilters = filters) => {
        setIsLoading(true);
        setError('');

        try {
            const response = await apiService.getResults(newFilters);
            setResults(response.results);
            setPagination(response.pagination);
        } catch (err) {
            setError(err.response?.data?.error || 'Failed to load results');
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        loadResults();
    }, []);

    const handleFilterChange = (key, value) => {
        const newFilters = {
            ...filters,
            [key]: value,
            offset: 0, // Reset to first page when filtering
        };
        setFilters(newFilters);
        loadResults(newFilters);
    };

    const handlePageChange = (direction) => {
        const newOffset = direction === 'next'
            ? filters.offset + filters.limit
            : Math.max(0, filters.offset - filters.limit);

        const newFilters = { ...filters, offset: newOffset };
        setFilters(newFilters);
        loadResults(newFilters);
    };

    const formatDate = (isoString) => {
        return new Date(isoString).toLocaleString();
    };

    const formatTime = (seconds) => {
        return `${seconds.toFixed(1)}s`;
    };

    const getConfidenceColor = (confidence) => {
        if (confidence >= 0.8) return 'text-green-600 bg-green-100';
        if (confidence >= 0.6) return 'text-yellow-600 bg-yellow-100';
        return 'text-red-600 bg-red-100';
    };

    return (
        <div className="bg-white rounded-lg shadow-lg p-6">
            <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-bold text-gray-900">Analysis History</h2>

                {/* Filters */}
                <div className="flex items-center space-x-4">
                    <div className="flex items-center space-x-2">
                        <Filter className="h-4 w-4 text-gray-500" />
                        <select
                            value={filters.itemType}
                            onChange={(e) => handleFilterChange('itemType', e.target.value)}
                            className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                        >
                            <option value="">All types</option>
                            {OBJECT_TYPES.map((type) => (
                                <option key={type} value={type}>
                                    {type.charAt(0).toUpperCase() + type.slice(1)}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>
            </div>

            {error && (
                <div className="mb-6 flex items-center space-x-2 p-4 bg-red-50 border border-red-200 rounded-md">
                    <AlertCircle className="h-5 w-5 text-red-600" />
                    <span className="text-sm text-red-700">{error}</span>
                </div>
            )}

            {isLoading ? (
                <div className="flex items-center justify-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
                    <span className="ml-3 text-gray-600">Loading results...</span>
                </div>
            ) : results.length === 0 ? (
                <div className="text-center py-12">
                    <Image className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No Results Found</h3>
                    <p className="text-gray-500">
                        {filters.itemType
                            ? `No ${filters.itemType} counting results found.`
                            : 'Upload an image to start counting objects.'
                        }
                    </p>
                </div>
            ) : (
                <>
                    {/* Results Grid */}
                    <div className="space-y-4">
                        {results.map((result) => (
                            <div key={result.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                                <div className="flex items-start space-x-4">
                                    {/* Image Thumbnail */}
                                    <div className="flex-shrink-0">
                                        <img
                                            src={apiService.getImageUrl(result.image_path)}
                                            alt="Analyzed"
                                            className="w-20 h-20 object-cover rounded-lg border"
                                        />
                                    </div>

                                    {/* Result Info */}
                                    <div className="flex-1 min-w-0">
                                        <div className="flex items-center justify-between">
                                            <div className="flex items-center space-x-3">
                                                <Target className="h-5 w-5 text-primary-600" />
                                                <span className="text-lg font-semibold text-gray-900">
                                                    {result.predicted_count} {result.item_type}{result.predicted_count !== 1 ? 's' : ''}
                                                </span>
                                                {result.corrected_count !== null && result.corrected_count !== result.predicted_count && (
                                                    <span className="text-sm text-orange-600 bg-orange-100 px-2 py-1 rounded-full">
                                                        Corrected to {result.corrected_count}
                                                    </span>
                                                )}
                                            </div>

                                            <div className="flex items-center space-x-3">
                                                <span className={`px-2 py-1 rounded-full text-xs font-medium ${getConfidenceColor(result.confidence_score)}`}>
                                                    {(result.confidence_score * 100).toFixed(0)}%
                                                </span>
                                                <div className="flex items-center space-x-1 text-xs text-gray-500">
                                                    <Clock className="h-3 w-3" />
                                                    <span>{formatTime(result.processing_time)}</span>
                                                </div>
                                            </div>
                                        </div>

                                        <div className="mt-2 text-sm text-gray-500">
                                            {formatDate(result.timestamp)}
                                        </div>

                                        {result.user_feedback && (
                                            <div className="mt-2 p-2 bg-gray-50 rounded text-sm text-gray-700">
                                                <span className="font-medium">Feedback: </span>
                                                {result.user_feedback}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>

                    {/* Pagination */}
                    {(pagination.total > filters.limit || filters.offset > 0) && (
                        <div className="mt-6 flex items-center justify-between">
                            <div className="text-sm text-gray-500">
                                Showing {filters.offset + 1} to {Math.min(filters.offset + filters.limit, pagination.total)} of {pagination.total} results
                            </div>

                            <div className="flex items-center space-x-2">
                                <button
                                    onClick={() => handlePageChange('prev')}
                                    disabled={filters.offset === 0}
                                    className="flex items-center space-x-1 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    <ChevronLeft className="h-4 w-4" />
                                    <span>Previous</span>
                                </button>

                                <button
                                    onClick={() => handlePageChange('next')}
                                    disabled={!pagination.hasMore}
                                    className="flex items-center space-x-1 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    <span>Next</span>
                                    <ChevronRight className="h-4 w-4" />
                                </button>
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    );
};

export default HistoryView;
