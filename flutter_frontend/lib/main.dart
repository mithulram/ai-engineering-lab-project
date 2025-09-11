import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upload_page.dart';
import 'results_page.dart';
import 'history_page.dart';
import 'monitoring_page.dart';
import 'few_shot_learning_page.dart';
import 'image_generation_page.dart';
import 'performance_analysis_page.dart';
import 'services/app_state.dart';

void main() {
  runApp(const AIObjectCounterApp());
}

class AIObjectCounterApp extends StatelessWidget {
  const AIObjectCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Object Counter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _backendStatus = 'checking';
  final AppState _appState = AppState();
  Map<String, dynamic> _systemMetrics = {};
  

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
    _startPeriodicHealthCheck();
  }

  Future<void> _checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5001/api/health'));
      if (response.statusCode == 200) {
        setState(() {
          _backendStatus = 'healthy';
        });
        _fetchSystemMetrics();
      } else {
        setState(() {
          _backendStatus = 'error';
        });
      }
    } catch (e) {
      setState(() {
        _backendStatus = 'error';
      });
    }
  }

  Future<void> _fetchSystemMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/metrics'),
        headers: {'Content-Type': 'text/plain'},
      );
      
      if (response.statusCode == 200) {
        final metrics = _parseMetrics(response.body);
        setState(() {
          _systemMetrics = metrics;
        });
      }
    } catch (e) {
      print('Error fetching metrics: $e');
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

  void _startPeriodicHealthCheck() {
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        _checkBackendHealth();
        _startPeriodicHealthCheck();
      }
    });
  }

  Widget _getStatusIcon() {
    switch (_backendStatus) {
      case 'healthy':
        return Icon(Icons.check_circle, 
          color: Theme.of(context).colorScheme.primary, size: 16);
      case 'error':
        return Icon(Icons.error, 
          color: Theme.of(context).colorScheme.error, size: 16);
      default:
        return Icon(Icons.pending, 
          color: Theme.of(context).colorScheme.secondary, size: 16);
    }
  }

  String _getStatusText() {
    switch (_backendStatus) {
      case 'healthy':
        return 'Connected';
      case 'error':
        return 'Offline';
      default:
        return 'Checking...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Icon(
              Icons.psychology, 
              color: Theme.of(context).colorScheme.primary, 
              size: 32,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AI Object Counter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isMediumScreen)
                    Text(
                      'Powered by SAM, ResNet-50 & DistilBERT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _backendStatus == 'healthy' 
                ? Theme.of(context).colorScheme.primaryContainer
                : _backendStatus == 'error' 
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getStatusIcon(),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _backendStatus == 'healthy' 
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : _backendStatus == 'error' 
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (_systemMetrics.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_systemMetrics.length} metrics',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavButton(0, Icons.upload, 'Upload & Count'),
                  const SizedBox(width: 8),
                  _buildNavButton(1, Icons.insights, 'Results'),
                  const SizedBox(width: 8),
                  _buildNavButton(2, Icons.history, 'History'),
                  const SizedBox(width: 8),
                  _buildNavButton(3, Icons.monitor, 'Monitoring'),
                  const SizedBox(width: 8),
                  _buildNavButton(4, Icons.psychology, 'Few-Shot Learning'),
                  const SizedBox(width: 8),
                  _buildNavButton(5, Icons.image, 'Image Generation'),
                  const SizedBox(width: 8),
                  _buildNavButton(6, Icons.assessment, 'Performance Analysis'),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isLargeScreen ? 32 : isMediumScreen ? 24 : 16),
              child: _getSelectedPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return UploadPage(
          onResultReceived: (result) {
            _appState.addResult(result);
            setState(() {
              _selectedIndex = 1; // Switch to results page
            });
          },
        );
      case 1:
        return const ResultsPageWidget();
      case 2:
        return const HistoryPageWidget();
      case 3:
        return MonitoringPage(metrics: _systemMetrics);
      case 4:
        return const FewShotLearningPage();
      case 5:
        return const ImageGenerationPage();
      case 6:
        return const PerformanceAnalysisPage();
      default:
        return UploadPage(
          onResultReceived: (result) {
            _appState.addResult(result);
            setState(() {
              _selectedIndex = 1;
            });
          },
        );
    }
  }
}
