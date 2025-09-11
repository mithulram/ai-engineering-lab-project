import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
                      _buildMetricsGrid(),
                      SizedBox(height: 24),
                      _buildChartsSection(),
                      SizedBox(height: 24),
                      _buildSystemInfo(),
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
                Icon(Icons.monitor, size: 32, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  'System Monitoring Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Real-time performance metrics and system health monitoring',
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
                  'Auto-refresh every 5 seconds',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _fetchMetrics,
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Refresh Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final keyMetrics = [
      {
        'title': 'Total Requests',
        'value': _metrics['ai_object_counting_requests_total']?.toString() ?? '0',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'title': 'Average Accuracy',
        'value': _formatPercentage(_metrics['ai_object_counting_accuracy'] ?? 0),
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': 'Average Precision',
        'value': _formatPercentage(_metrics['ai_object_counting_precision'] ?? 0),
        'icon': Icons.trending_up,
        'color': Colors.orange,
      },
      {
        'title': 'Average Recall',
        'value': _formatPercentage(_metrics['ai_object_counting_recall'] ?? 0),
        'icon': Icons.refresh,
        'color': Colors.purple,
      },
      {
        'title': 'Total Predictions',
        'value': _metrics['ai_object_counting_predictions_total']?.toString() ?? '0',
        'icon': Icons.psychology,
        'color': Colors.indigo,
      },
      {
        'title': 'System Health',
        'value': 'Healthy',
        'icon': Icons.health_and_safety,
        'color': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: keyMetrics.length,
      itemBuilder: (context, index) {
        final metric = keyMetrics[index];
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      metric['icon'] as IconData,
                      color: metric['color'] as Color,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        metric['title'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  metric['value'] as String,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: metric['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildMetricChart(
              'Model Confidence',
              _metrics['ai_object_counting_model_confidence'] ?? 0,
              Colors.blue,
            ),
            SizedBox(height: 16),
            _buildMetricChart(
              'Response Time (ms)',
              (_metrics['ai_object_counting_response_time_seconds_sum'] ?? 0) * 1000,
              Colors.green,
            ),
            SizedBox(height: 16),
            _buildMetricChart(
              'Image Resolution',
              _metrics['ai_object_counting_image_resolution'] ?? 0,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChart(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Backend API', 'http://localhost:5001', Icons.api),
            _buildInfoRow('Metrics Endpoint', '/metrics', Icons.analytics),
            _buildInfoRow('Health Check', '/api/health', Icons.health_and_safety),
            _buildInfoRow('Total Metrics', '${_metrics.length}', Icons.list),
            _buildInfoRow('Last Update', DateTime.now().toString().substring(11, 19), Icons.schedule),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
