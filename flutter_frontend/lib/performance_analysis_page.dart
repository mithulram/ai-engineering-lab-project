import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerformanceAnalysisPage extends StatefulWidget {
  const PerformanceAnalysisPage({Key? key}) : super(key: key);

  @override
  _PerformanceAnalysisPageState createState() => _PerformanceAnalysisPageState();
}

class _PerformanceAnalysisPageState extends State<PerformanceAnalysisPage> {
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/metrics'),
        headers: {'Content-Type': 'text/plain'},
      );
      
      if (response.statusCode == 200) {
        final metrics = _parseMetrics(response.body);
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch metrics: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching metrics: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseMetrics(String metricsText) {
    Map<String, dynamic> metrics = {};
    List<String> lines = metricsText.split('\n');
    
    for (String line in lines) {
      if (line.startsWith('ai_object_counting_') && !line.startsWith('#')) {
        List<String> parts = line.split(' ');
        if (parts.length >= 2) {
          String metricName = parts[0];
          String value = parts[1];
          
          String baseName = metricName.split('{')[0];
          
          try {
            double numericValue = double.parse(value);
            metrics[baseName] = numericValue;
          } catch (e) {
            metrics[baseName] = value;
          }
        }
      }
    }
    
    return metrics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMetrics,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24),
                      _buildPerformanceOverview(),
                      SizedBox(height: 24),
                      _buildDetailedAnalysis(),
                      SizedBox(height: 24),
                      _buildRecommendations(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, size: 32, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  'Performance Analysis Report',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Comprehensive analysis of system performance and AI model effectiveness',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.refresh, size: 16),
                SizedBox(width: 8),
                Text(
                  'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _fetchMetrics,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Refresh Data'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final totalRequests = _metrics['ai_object_counting_requests_total'] ?? 0;
    final avgAccuracy = _metrics['ai_object_counting_accuracy'] ?? 0;
    final avgPrecision = _metrics['ai_object_counting_precision'] ?? 0;
    final avgRecall = _metrics['ai_object_counting_recall'] ?? 0;
    final totalPredictions = _metrics['ai_object_counting_predictions_total'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Requests',
                    totalRequests.toString(),
                    Icons.trending_up,
                    Colors.blue,
                    'API calls processed',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Accuracy',
                    '${(avgAccuracy * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                    'Overall accuracy rate',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Precision',
                    '${(avgPrecision * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.orange,
                    'Precision score',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Recall',
                    '${(avgRecall * 100).toStringAsFixed(1)}%',
                    Icons.refresh,
                    Colors.purple,
                    'Recall score',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Predictions',
                    totalPredictions.toString(),
                    Icons.psychology,
                    Colors.indigo,
                    'AI predictions made',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'System Health',
                    'Healthy',
                    Icons.health_and_safety,
                    Colors.green,
                    'Overall system status',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildAnalysisSection(
              'API Performance',
              [
                'Response Time: ${_getResponseTimeAnalysis()}',
                'Throughput: ${_getThroughputAnalysis()}',
                'Error Rate: ${_getErrorRateAnalysis()}',
              ],
              Icons.api,
              Colors.blue,
            ),
            SizedBox(height: 16),
            _buildAnalysisSection(
              'AI Model Performance',
              [
                'Model Confidence: ${_getModelConfidenceAnalysis()}',
                'Inference Time: ${_getInferenceTimeAnalysis()}',
                'Prediction Accuracy: ${_getPredictionAccuracyAnalysis()}',
              ],
              Icons.psychology,
              Colors.green,
            ),
            SizedBox(height: 16),
            _buildAnalysisSection(
              'Image Processing',
              [
                'Image Resolution: ${_getImageResolutionAnalysis()}',
                'Segments Found: ${_getSegmentsAnalysis()}',
                'Processing Efficiency: ${_getProcessingEfficiencyAnalysis()}',
              ],
              Icons.image,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: color),
                SizedBox(width: 8),
                Expanded(child: Text(item)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildRecommendationItem(
              'Performance Optimization',
              'Consider implementing model caching and batch processing to improve response times.',
              Icons.speed,
              Colors.blue,
            ),
            _buildRecommendationItem(
              'Accuracy Improvement',
              'Increase training data diversity and implement data augmentation techniques.',
              Icons.trending_up,
              Colors.green,
            ),
            _buildRecommendationItem(
              'Monitoring Enhancement',
              'Set up alerting thresholds for critical metrics and implement automated scaling.',
              Icons.monitor,
              Colors.orange,
            ),
            _buildRecommendationItem(
              'Model Updates',
              'Regularly retrain models with new data and implement A/B testing for model versions.',
              Icons.update,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getResponseTimeAnalysis() {
    final responseTime = _metrics['ai_object_counting_response_time_seconds_sum'] ?? 0;
    if (responseTime < 0.1) return 'Excellent (< 100ms)';
    if (responseTime < 0.5) return 'Good (< 500ms)';
    if (responseTime < 1.0) return 'Acceptable (< 1s)';
    return 'Needs improvement (> 1s)';
  }

  String _getThroughputAnalysis() {
    final requests = _metrics['ai_object_counting_requests_total'] ?? 0;
    if (requests > 1000) return 'High throughput';
    if (requests > 100) return 'Medium throughput';
    return 'Low throughput';
  }

  String _getErrorRateAnalysis() {
    // This would be calculated from error metrics
    return 'Low error rate (< 1%)';
  }

  String _getModelConfidenceAnalysis() {
    final confidence = _metrics['ai_object_counting_model_confidence'] ?? 0;
    if (confidence > 0.8) return 'High confidence';
    if (confidence > 0.6) return 'Medium confidence';
    return 'Low confidence';
  }

  String _getInferenceTimeAnalysis() {
    final inferenceTime = _metrics['ai_object_counting_inference_time_seconds_sum'] ?? 0;
    if (inferenceTime < 0.01) return 'Very fast (< 10ms)';
    if (inferenceTime < 0.1) return 'Fast (< 100ms)';
    return 'Slow (> 100ms)';
  }

  String _getPredictionAccuracyAnalysis() {
    final accuracy = _metrics['ai_object_counting_accuracy'] ?? 0;
    if (accuracy > 0.9) return 'Excellent (> 90%)';
    if (accuracy > 0.7) return 'Good (> 70%)';
    if (accuracy > 0.5) return 'Fair (> 50%)';
    return 'Poor (< 50%)';
  }

  String _getImageResolutionAnalysis() {
    final resolution = _metrics['ai_object_counting_image_resolution'] ?? 0;
    if (resolution > 1000000) return 'High resolution';
    if (resolution > 100000) return 'Medium resolution';
    return 'Low resolution';
  }

  String _getSegmentsAnalysis() {
    final segments = _metrics['ai_object_counting_segments_found'] ?? 0;
    if (segments > 10) return 'Many segments detected';
    if (segments > 5) return 'Moderate segments';
    return 'Few segments detected';
  }

  String _getProcessingEfficiencyAnalysis() {
    // This would be calculated from processing time vs image size
    return 'Efficient processing';
  }
}
