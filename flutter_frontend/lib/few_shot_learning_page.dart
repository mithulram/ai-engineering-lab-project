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

  Future<void> _learnNewObject() async {
    final TextEditingController nameController = TextEditingController();
    List<XFile> selectedImages = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Learn New Object'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Object Name',
                    hintText: 'e.g., bicycle, chair, lamp',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
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
                      onPressed: () async {
                        final images = await _picker.pickMultiImage();
                        setDialogState(() {
                          selectedImages.addAll(images);
                        });
                      },
                      icon: Icon(Icons.add_photo_alternate),
                      label: Text('Add Images'),
                    ),
                    if (selectedImages.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            selectedImages.clear();
                          });
                        },
                        icon: Icon(Icons.clear),
                        label: Text('Clear'),
                      ),
                  ],
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Selected ${selectedImages.length} images',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
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
                            child: Image.file(
                              File(selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedImages.length >= 2 && nameController.text.isNotEmpty
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: Text('Learn Object'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _performLearning(nameController.text, selectedImages);
    }
  }

  Future<void> _performLearning(String objectName, List<XFile> images) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5001/api/learn'),
      );

      request.fields['object_name'] = objectName;
      
      for (int i = 0; i < images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            images[i].path,
            filename: '${objectName}_$i.jpg',
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
              content: Text('Successfully learned object: $objectName'),
              backgroundColor: Colors.green,
            ),
          );
          _loadLearnedObjects();
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Learning failed';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to learn object: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error learning object: $e';
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
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
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
                        onPressed: _loadLearnedObjects,
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
                      _buildLearnedObjectsList(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _learnNewObject,
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
