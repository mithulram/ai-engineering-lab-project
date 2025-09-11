import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class MonitoringPage extends StatefulWidget {
  final Map<String, dynamic> metrics;
  
  const MonitoringPage({Key? key, required this.metrics}) : super(key: key);

  @override
  _MonitoringPageState createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _metrics = widget.metrics;
    _isLoading = false;
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        _fetchMetrics();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _fetchMetrics() async {
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
          _errorMessage = '';
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
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading System Metrics...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connecting to AI Object Counting System',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red[50]!, Colors.orange[50]!],
        ),
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchMetrics,
                icon: Icon(Icons.refresh),
                label: Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedHeader(),
              SizedBox(height: 24),
              _buildSystemHealthCard(),
              SizedBox(height: 20),
              _buildKeyMetricsSection(),
              SizedBox(height: 20),
              _buildPerformanceSection(),
              SizedBox(height: 20),
              _buildSystemInfoSection(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI System Monitor',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Real-time AI Object Counting Performance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Auto-refresh: 5s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: _fetchMetrics,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Refresh Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue[600],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    final isHealthy = _metrics.isNotEmpty;
    final totalRequests = _metrics['ai_object_counting_requests_total'] ?? 0;
    final accuracy = _metrics['ai_object_counting_accuracy'] ?? 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green[600] : Colors.red[600],
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      isHealthy ? 'All systems operational' : 'System issues detected',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHealthy ? Colors.green[600] : Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHealthMetric(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildHealthMetric(
                  'AI Accuracy',
                  '${(accuracy * 100).toStringAsFixed(1)}%',
                  Icons.psychology,
                  accuracy > 0.8 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        _buildMetricsGrid(),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final keyMetrics = [
      {
        'title': 'Total Requests',
        'value': _metrics['ai_object_counting_requests_total']?.toString() ?? '0',
        'description': 'Images processed by the AI system',
        'icon': Icons.upload_file,
        'color': Colors.blue,
      },
      {
        'title': 'AI Accuracy',
        'value': _formatPercentage(_metrics['ai_object_counting_accuracy'] ?? 0),
        'description': 'How often the AI counts correctly',
        'icon': Icons.gps_fixed,
        'color': Colors.green,
      },
      {
        'title': 'Precision',
        'value': _formatPercentage(_metrics['ai_object_counting_precision'] ?? 0),
        'description': 'Accuracy of positive predictions',
        'icon': Icons.precision_manufacturing,
        'color': Colors.orange,
      },
      {
        'title': 'Recall',
        'value': _formatPercentage(_metrics['ai_object_counting_recall'] ?? 0),
        'description': 'How many objects were found',
        'icon': Icons.search,
        'color': Colors.purple,
      },
      {
        'title': 'Model Confidence',
        'value': '${((_metrics['ai_object_counting_model_confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
        'description': 'AI confidence in its predictions',
        'icon': Icons.psychology,
        'color': Colors.indigo,
      },
      {
        'title': 'Response Time',
        'value': '${((_metrics['ai_object_counting_response_time_seconds_sum'] ?? 0) * 1000).toStringAsFixed(0)}ms',
        'description': 'Time to process each image',
        'icon': Icons.speed,
        'color': Colors.teal,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: keyMetrics.length,
      itemBuilder: (context, index) {
        final metric = keyMetrics[index];
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (metric['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      metric['icon'] as IconData,
                      color: metric['color'] as Color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metric['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                metric['value'] as String,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: metric['color'] as Color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                metric['description'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Analysis',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEnhancedMetricChart(
                'AI Model Confidence',
                (_metrics['ai_object_counting_model_confidence'] ?? 0) * 100,
                Colors.blue,
                'How confident the AI is in its predictions',
                '%',
              ),
              SizedBox(height: 20),
              _buildEnhancedMetricChart(
                'Response Time',
                (_metrics['ai_object_counting_response_time_seconds_sum'] ?? 0) * 1000,
                Colors.green,
                'Time taken to process each image',
                'ms',
              ),
              SizedBox(height: 20),
              _buildImageResolutionChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedMetricChart(String title, double value, Color color, String description, String unit) {
    final normalizedValue = unit == '%' ? value.clamp(0.0, 100.0) : value;
    final progressValue = unit == '%' ? normalizedValue / 100.0 : (normalizedValue / 1000.0).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                unit == '%' ? Icons.psychology : Icons.speed,
                color: color,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${normalizedValue.toStringAsFixed(unit == '%' ? 1 : 0)}$unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageResolutionChart() {
    final resolution = _metrics['ai_object_counting_image_resolution'] ?? 0;
    String displayValue;
    
    if (resolution > 0) {
      // Convert total pixels to readable format
      final sqrtPixels = math.sqrt(resolution);
      final aspectRatios = [
        (16, 9), (4, 3), (3, 2), (1, 1), (21, 9)
      ];
      
      var bestRatio = (1920, 1080); // Default
      var bestDiff = double.infinity;
      
      for (var (wRatio, hRatio) in aspectRatios) {
        final w = sqrtPixels * math.sqrt(wRatio / hRatio);
        final h = sqrtPixels * math.sqrt(hRatio / wRatio);
        final calculatedPixels = w * h;
        final diff = (calculatedPixels - resolution).abs();
        
        if (diff < bestDiff) {
          bestDiff = diff;
          bestRatio = (w.round(), h.round());
        }
      }
      
      if (bestDiff < resolution * 0.1) {
        displayValue = '${bestRatio.$1}x${bestRatio.$2}';
      } else {
        final megapixels = resolution / 1000000;
        displayValue = '${megapixels.toStringAsFixed(1)}MP';
      }
    } else {
      displayValue = 'No data';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.aspect_ratio,
                color: Colors.orange,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image Resolution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    'Resolution of processed images',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: resolution > 0 ? 0.8 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.orange.withOpacity(0.7)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEnhancedInfoRow(
                'Backend API',
                'http://localhost:5001',
                Icons.api,
                'Main AI processing server',
                Colors.blue,
              ),
              SizedBox(height: 16),
              _buildEnhancedInfoRow(
                'Metrics Endpoint',
                '/metrics',
                Icons.analytics,
                'Real-time performance data',
                Colors.green,
              ),
              SizedBox(height: 16),
              _buildEnhancedInfoRow(
                'Health Check',
                '/api/health',
                Icons.health_and_safety,
                'System status monitoring',
                Colors.orange,
              ),
              SizedBox(height: 16),
              _buildEnhancedInfoRow(
                'Total Metrics',
                '${_metrics.length}',
                Icons.list,
                'Number of tracked metrics',
                Colors.purple,
              ),
              SizedBox(height: 16),
              _buildEnhancedInfoRow(
                'Last Update',
                DateTime.now().toString().substring(11, 19),
                Icons.schedule,
                'Data refresh timestamp',
                Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercentage(dynamic value) {
    if (value is num) {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return '0.0%';
  }
}
