import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

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
  String? _generatedImageUrl;

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
            if (_isGenerating) ...[
              SizedBox(height: 24),
              _buildLoadingIndicator(),
            ],
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

  Widget _buildLoadingIndicator() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Generating image and testing with AI...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
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
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'object_type': _selectedObjectType,
          'count': _objectCount,
          'size': _selectedSize,
          'clarity': _clarityLevel,
          'noise': _noiseLevel,
          'rotation': _rotationAngle,
          'background': _selectedBackground,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
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
              'image_id': data['image_id'],
              'ai_test_result': data['ai_test_result'],
            };
            _generatedImageUrl = 'http://localhost:5001/api/generated-image/${data['image_id']}';
            _isGenerating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image generated and tested successfully! AI accuracy: ${(data['ai_test_result']['accuracy'] * 100).toStringAsFixed(1)}%'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to generate image: ${data['error'] ?? 'Unknown error'}';
            _isGenerating = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error generating image: ${response.statusCode}';
          _isGenerating = false;
        });
      }
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
      final response = await http.post(
        Uri.parse('http://localhost:5001/api/run-batch-test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'num_tests': _numTests,
          'object_type': _selectedObjectType,
          'size': _selectedSize,
          'clarity': _clarityLevel,
          'noise': _noiseLevel,
          'rotation': _rotationAngle,
          'background': _selectedBackground,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _testResults = List<Map<String, dynamic>>.from(data['test_results']);
            _isGenerating = false;
          });

          final summary = data['summary'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Batch test completed! ${summary['total_tests']} images tested. Accuracy: ${summary['accuracy_rate'].toStringAsFixed(1)}%'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to run batch test: ${data['error'] ?? 'Unknown error'}';
            _isGenerating = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error running batch test: ${response.statusCode}';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error running batch test: $e';
        _isGenerating = false;
      });
    }
  }

  Widget _buildGenerationResults() {
    final aiResult = _generationResults['ai_test_result'];
    final accuracy = aiResult != null ? (aiResult['accuracy'] * 100) : 0.0;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generation & AI Test Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Generated Image Display
            if (_generatedImageUrl != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.blue[600], size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Generated Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          onPressed: _downloadImage,
                          icon: Icon(Icons.download, size: 16),
                          label: Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _clearResults,
                          icon: Icon(Icons.clear, size: 16),
                          label: Text('Clear'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _generatedImageUrl!,
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 300,
                                height: 300,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 300,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 48),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // AI Test Results Section
            if (aiResult != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accuracy == 100.0 ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accuracy == 100.0 ? Colors.green[300]! : Colors.orange[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          accuracy == 100.0 ? Icons.check_circle : Icons.warning,
                          color: accuracy == 100.0 ? Colors.green[600] : Colors.orange[600],
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: accuracy == 100.0 ? Colors.green[800] : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAIMetricCard(
                            'True Count',
                            aiResult['true_count'].toString(),
                            Icons.numbers,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAIMetricCard(
                            'Predicted',
                            aiResult['predicted_count'].toString(),
                            Icons.psychology,
                            Colors.purple,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildAIMetricCard(
                            'Accuracy',
                            '${accuracy.toStringAsFixed(1)}%',
                            Icons.check_circle,
                            accuracy == 100.0 ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildResultRow('Confidence', '${(aiResult['confidence'] * 100).toStringAsFixed(1)}%'),
                    _buildResultRow('Processing Time', '${aiResult['processing_time'].toStringAsFixed(2)}s'),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // Generation Parameters
            Text(
              'Generation Parameters',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
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

  Widget _buildAIMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _downloadImage() async {
    if (_generatedImageUrl == null) return;
    
    try {
      // Create a temporary anchor element to trigger download
      final anchor = html.AnchorElement(href: _generatedImageUrl!)
        ..setAttribute('download', 'generated_image_${_generationResults['object_type']}_${_generationResults['count']}_objects.png')
        ..click();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image download started!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearResults() {
    setState(() {
      _generationResults.clear();
      _generatedImageUrl = null;
      _testResults.clear();
      _errorMessage = '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Results cleared'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
