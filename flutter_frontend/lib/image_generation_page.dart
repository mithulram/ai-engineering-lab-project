import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageGenerationPage extends StatefulWidget {
  const ImageGenerationPage({Key? key}) : super(key: key);

  @override
  _ImageGenerationPageState createState() => _ImageGenerationPageState();
}

class _ImageGenerationPageState extends State<ImageGenerationPage> {
  bool _isGenerating = false;
  String _errorMessage = '';
  Map<String, dynamic> _generationResults = {};
  List<Map<String, dynamic>> _testResults = [];

  // Generation parameters
  String _selectedObjectType = 'car';
  int _objectCount = 3;
  String _selectedSize = '512x512';
  double _clarityLevel = 0.8;
  int _noiseLevel = 10;
  int _rotationAngle = 0;
  String _selectedBackground = 'white';
  int _numTests = 10;

  final List<String> _objectTypes = [
    'car', 'cat', 'tree', 'dog', 'building', 'person', 'sky', 'ground', 'hardware'
  ];

  final List<String> _imageSizes = [
    '256x256', '512x256', '256x512', '512x512', '1024x512', '512x1024', '1024x1024'
  ];

  final List<String> _backgroundTypes = [
    'white', 'black', 'sky', 'ground', 'gradient'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildGenerationSettings(),
            SizedBox(height: 24),
            _buildGenerationControls(),
            if (_generationResults.isNotEmpty) ...[
              SizedBox(height: 24),
              _buildGenerationResults(),
            ],
            if (_testResults.isNotEmpty) ...[
              SizedBox(height: 24),
              _buildTestResults(),
            ],
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
                Icon(Icons.image, size: 32, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  'Image Generation & Testing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Generate synthetic test images and automatically test the AI model',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation Parameters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildParameterRow(
              'Object Type',
              DropdownButton<String>(
                value: _selectedObjectType,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _selectedObjectType = value!;
                  });
                },
                items: _objectTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
            ),
            _buildParameterRow(
              'Object Count',
              Slider(
                value: _objectCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: _objectCount.toString(),
                onChanged: (value) {
                  setState(() {
                    _objectCount = value.round();
                  });
                },
              ),
            ),
            _buildParameterRow(
              'Image Size',
              DropdownButton<String>(
                value: _selectedSize,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _selectedSize = value!;
                  });
                },
                items: _imageSizes.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  );
                }).toList(),
              ),
            ),
            _buildParameterRow(
              'Clarity Level',
              Slider(
                value: _clarityLevel,
                min: 0.3,
                max: 1.0,
                divisions: 7,
                label: _clarityLevel.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _clarityLevel = value;
                  });
                },
              ),
            ),
            _buildParameterRow(
              'Noise Level',
              Slider(
                value: _noiseLevel.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                label: _noiseLevel.toString(),
                onChanged: (value) {
                  setState(() {
                    _noiseLevel = value.round();
                  });
                },
              ),
            ),
            _buildParameterRow(
              'Rotation Angle',
              Slider(
                value: _rotationAngle.toDouble(),
                min: 0,
                max: 315,
                divisions: 7,
                label: '${_rotationAngle}°',
                onChanged: (value) {
                  setState(() {
                    _rotationAngle = (value / 45).round() * 45;
                  });
                },
              ),
            ),
            _buildParameterRow(
              'Background Type',
              DropdownButton<String>(
                value: _selectedBackground,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _selectedBackground = value!;
                  });
                },
                items: _backgroundTypes.map((bg) {
                  return DropdownMenuItem(
                    value: bg,
                    child: Text(bg),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, Widget control) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(child: control),
        ],
      ),
    );
  }

  Widget _buildGenerationControls() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateSingleImage,
                    icon: Icon(Icons.image),
                    label: Text('Generate Single Image'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _runBatchTest,
                    icon: Icon(Icons.play_arrow),
                    label: Text('Run Batch Test'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Number of test images:'),
                ),
                SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      _numTests = int.tryParse(value) ?? 10;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSingleImage() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = '';
    });

    try {
      // Simulate image generation (in real implementation, this would call the backend)
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _generationResults = {
          'object_type': _selectedObjectType,
          'count': _objectCount,
          'size': _selectedSize,
          'clarity': _clarityLevel,
          'noise': _noiseLevel,
          'rotation': _rotationAngle,
          'background': _selectedBackground,
          'generated_at': DateTime.now().toIso8601String(),
        };
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating image: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _runBatchTest() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = '';
      _testResults.clear();
    });

    try {
      // Simulate batch testing
      for (int i = 0; i < _numTests; i++) {
        await Future.delayed(Duration(milliseconds: 500));
        
        // Simulate test results
        final result = {
          'test_id': i + 1,
          'object_type': _objectTypes[i % _objectTypes.length],
          'true_count': (i % 5) + 1,
          'predicted_count': (i % 5) + 1 + (i % 3) - 1,
          'accuracy': (i % 2) == 0 ? 1.0 : 0.0,
          'response_time': 0.1 + (i % 10) * 0.01,
          'image_size': _imageSizes[i % _imageSizes.length],
        };
        
        setState(() {
          _testResults.add(result);
        });
      }

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch test completed! ${_testResults.length} images tested.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error running batch test: $e';
        _isGenerating = false;
      });
    }
  }

  Widget _buildGenerationResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildResultRow('Object Type', _generationResults['object_type']),
            _buildResultRow('Count', _generationResults['count'].toString()),
            _buildResultRow('Size', _generationResults['size']),
            _buildResultRow('Clarity', _generationResults['clarity'].toString()),
            _buildResultRow('Noise', _generationResults['noise'].toString()),
            _buildResultRow('Rotation', '${_generationResults['rotation']}°'),
            _buildResultRow('Background', _generationResults['background']),
            _buildResultRow('Generated At', _generationResults['generated_at']?.toString().substring(11, 19) ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    final successfulTests = _testResults.where((r) => r['accuracy'] == 1.0).length;
    final accuracyRate = _testResults.isNotEmpty ? (successfulTests / _testResults.length) * 100 : 0.0;
    final avgResponseTime = _testResults.isNotEmpty 
        ? _testResults.map((r) => r['response_time'] as double).reduce((a, b) => a + b) / _testResults.length 
        : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Tests',
                    _testResults.length.toString(),
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Accuracy Rate',
                    '${accuracyRate.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Avg Response Time',
                    '${avgResponseTime.toStringAsFixed(2)}s',
                    Icons.timer,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Individual Test Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 200,
              child: ListView.builder(
                itemCount: _testResults.length,
                itemBuilder: (context, index) {
                  final result = _testResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: result['accuracy'] == 1.0 ? Colors.green : Colors.red,
                      child: Icon(
                        result['accuracy'] == 1.0 ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text('Test ${result['test_id']} - ${result['object_type']}'),
                    subtitle: Text('True: ${result['true_count']}, Predicted: ${result['predicted_count']}'),
                    trailing: Text('${(result['response_time'] * 1000).toStringAsFixed(0)}ms'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(': $value'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
