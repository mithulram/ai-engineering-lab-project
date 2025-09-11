import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FewShotLearningPage extends StatefulWidget {
  const FewShotLearningPage({Key? key}) : super(key: key);

  @override
  _FewShotLearningPageState createState() => _FewShotLearningPageState();
}

class _FewShotLearningPageState extends State<FewShotLearningPage> {
  List<Map<String, dynamic>> _learnedObjects = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final ImagePicker _picker = ImagePicker();
  
  // Inline learning state
  bool _isLearningMode = false;
  final TextEditingController _nameController = TextEditingController();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _loadLearnedObjects();
  }

  Future<void> _loadLearnedObjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/learned-objects'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _learnedObjects = List<Map<String, dynamic>>.from(data['learned_objects'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load learned objects: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading learned objects: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleLearningMode() {
    setState(() {
      _isLearningMode = !_isLearningMode;
      if (!_isLearningMode) {
        _nameController.clear();
        _selectedImages.clear();
        _errorMessage = '';
      }
    });
  }

  Future<void> _addImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      // Fallback to single image picker if multi-image fails
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  void _clearImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  Future<void> _processLearning() async {
    if (_selectedImages.length < 2 || _nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide at least 2 images and an object name.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5001/api/learn'),
      );

      request.fields['object_name'] = _nameController.text;
      
      // Web-compatible file upload
      for (int i = 0; i < _selectedImages.length; i++) {
        final bytes = await _selectedImages[i].readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: '${_nameController.text}_$i.jpg',
          ),
        );
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['learning_successful'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully learned object: ${_nameController.text}'),
              backgroundColor: Colors.green,
            ),
          );
          _toggleLearningMode();
          _loadLearnedObjects();
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Learning failed';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to learn object: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error learning object: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _countLearnedObject(String objectName) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5001/api/count-learned'),
      );

      request.fields['object_name'] = objectName;
      
      // Web-compatible file upload
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: '${objectName}_count.jpg',
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        _showCountResult(data);
      } else {
        setState(() {
          _errorMessage = 'Failed to count objects: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error counting objects: $e';
        _isLoading = false;
      });
    }
  }

  void _showCountResult(Map<String, dynamic> result) {
    setState(() {
      _isLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Count Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Object: ${result['object_name'] ?? 'Unknown'}'),
            Text('Count: ${result['count'] ?? 0}'),
            Text('Confidence: ${(result['confidence'] ?? 0).toStringAsFixed(2)}'),
            if (result['segments_checked'] != null)
              Text('Segments Checked: ${result['segments_checked']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteObject(String objectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Object'),
        content: Text('Are you sure you want to delete "$objectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final response = await http.delete(
          Uri.parse('http://localhost:5001/api/delete-learned-object'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'object_name': objectName}),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted object: $objectName'),
              backgroundColor: Colors.green,
            ),
          );
          _loadLearnedObjects();
        } else {
          setState(() {
            _errorMessage = 'Failed to delete object: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error deleting object: $e';
          _isLoading = false;
        });
      }
    }
  }

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
            
            // Inline Learning Interface
            if (_isLearningMode) ...[
              _buildLearningInterface(),
              SizedBox(height: 24),
            ],
            
            // Error message display
            if (_errorMessage.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _errorMessage = ''),
                      icon: Icon(Icons.close, color: Colors.red[700], size: 16),
                    ),
                  ],
                ),
              ),
            ],
            
            _buildLearnedObjectsList(),
          ],
        ),
      ),
      floatingActionButton: _isLearningMode 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _toggleLearningMode,
              icon: Icon(Icons.add),
              label: Text('Learn New Object'),
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
                Icon(Icons.psychology, size: 32, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  'Few-Shot Learning',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Teach the AI to recognize new object types with just a few examples',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text(
                  'Upload 2-5 images of the same object type to train the model',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningInterface() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, size: 24, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Learn New Object',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: _toggleLearningMode,
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Object Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Object Name',
                hintText: 'e.g., bicycle, chair, lamp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            SizedBox(height: 16),
            
            // Image Selection
            Text(
              'Select 2-5 training images:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _addImages,
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Images'),
                ),
                if (_selectedImages.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _clearImages,
                    icon: Icon(Icons.clear),
                    label: Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
              ],
            ),
            
            // Selected Images Preview
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Selected ${_selectedImages.length} images:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 8),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _selectedImages[index].path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No images selected. Click "Add Images" to select training images.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleLearningMode,
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : (_selectedImages.length >= 2 && _nameController.text.isNotEmpty)
                            ? _processLearning
                            : null,
                    child: _isLoading 
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Learn Object'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnedObjectsList() {
    if (_learnedObjects.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No learned objects yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Tap the + button to learn your first object type',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learned Objects (${_learnedObjects.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _learnedObjects.length,
          itemBuilder: (context, index) {
            final object = _learnedObjects[index];
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.psychology,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            object['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Training images: ${object['training_images_count'] ?? 0}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (object['learned_at'] != null)
                            Text(
                              'Learned: ${object['learned_at'].toString().substring(0, 10)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _countLearnedObject(object['name']),
                          icon: Icon(Icons.search, size: 16),
                          label: Text('Count'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _deleteObject(object['name']),
                          icon: Icon(Icons.delete, size: 16, color: Colors.red),
                          label: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
