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
  
  // Learning state
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
          // Clear the form
          _nameController.clear();
          _selectedImages.clear();
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

    final count = result['count'] ?? 0;
    final confidence = (result['confidence'] ?? 0) * 100;
    final segmentsChecked = result['segments_checked'] ?? 0;
    final objectName = result['object_name'] ?? 'Unknown';
    final avgSimilarity = result['avg_similarity'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Counting Results',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Object: ${objectName.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Main Results
              Row(
                children: [
                  Expanded(
                    child: _buildResultCard(
                      'Objects Found',
                      count.toString(),
                      Icons.numbers,
                      count > 0 ? Colors.green[600]! : Colors.grey[600]!,
                      '${count == 1 ? 'object' : 'objects'} detected',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildResultCard(
                      'AI Confidence',
                      '${confidence.toStringAsFixed(1)}%',
                      Icons.psychology,
                      _getConfidenceColor(confidence),
                      _getConfidenceText(confidence),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Detailed Analysis
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.grid_view,
                      'Image Segments Analyzed',
                      '$segmentsChecked segments',
                      'The AI divided your image into $segmentsChecked small regions and checked each one',
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.tune,
                      'Average Similarity',
                      '${(avgSimilarity * 100).toStringAsFixed(1)}%',
                      'How similar the detected objects are to your training examples',
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.tune,
                      'Detection Threshold',
                      '60% similarity',
                      'Objects with >60% similarity to your training data were counted',
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Close', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _countLearnedObject(objectName);
                      },
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Test Another Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
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

  Widget _buildDetailRow(IconData icon, String title, String value, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
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
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green[600]!;
    if (confidence >= 60) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  String _getConfidenceText(double confidence) {
    if (confidence >= 80) return 'High confidence';
    if (confidence >= 60) return 'Medium confidence';
    return 'Low confidence';
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
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 1000 : double.infinity,
            ),
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[600]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                              Icons.psychology_rounded,
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
                                  'Few-Shot Learning',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Teach the AI to recognize new object types',
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Upload 2-5 images of the same object type to train the model',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Learning Interface - Always Visible
                _buildEnhancedLearningInterface(isMediumScreen),
                
                SizedBox(height: 32),
                
                // Error message display
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: isMediumScreen ? 32.0 : 20.0),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[700], size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _errorMessage = ''),
                          icon: Icon(Icons.close, color: Colors.red[700], size: 20),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                ],
                
                // Learned Objects List
                _buildLearnedObjectsList(isMediumScreen),
                
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildEnhancedLearningInterface(bool isMediumScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMediumScreen ? 32.0 : 20.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 28,
                      color: Colors.purple[600],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teach AI a New Object Type',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Upload multiple images of the same object to train the model',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              
              // Object Name Input
              Text(
                'What object do you want to teach?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Object Name',
                  hintText: 'e.g., bicycle, chair, lamp, coffee mug',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.label_outline),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              
              // Image Upload Section
              Text(
                'Upload Training Images (2-5 images recommended)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              
              // Upload Area or Image Preview
              _selectedImages.isNotEmpty 
                  ? _buildImagePreview(isMediumScreen)
                  : _buildUploadArea(isMediumScreen),
              
              SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  if (_selectedImages.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearImages,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear, size: 20),
                            SizedBox(width: 8),
                            Text('Clear Images', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading 
                          ? null 
                          : (_selectedImages.length >= 2 && _nameController.text.isNotEmpty)
                              ? _processLearning
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading 
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Training AI...', style: TextStyle(fontSize: 16)),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.psychology, size: 20),
                                SizedBox(width: 8),
                                Text('Train AI Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea(bool isMediumScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addImages,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: isMediumScreen ? 280 : 240,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.purple[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Colors.purple[50]!.withOpacity(0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 64,
                  color: Colors.purple[600],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Click to select training images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Upload 2-5 images of the same object type\nSupports PNG, JPG, JPEG, GIF, BMP',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Images Grid
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple[300]!),
            borderRadius: BorderRadius.circular(16),
            color: Colors.purple[50]!.withOpacity(0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.purple[600], size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Selected ${_selectedImages.length} training images',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple[600],
                    ),
                  ),
                  Spacer(),
                  TextButton.icon(
                    onPressed: _addImages,
                    icon: Icon(Icons.add, size: 16),
                    label: Text('Add More'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _selectedImages[index].path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearnedObjectsList(bool isMediumScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMediumScreen ? 32.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Trained Objects (${_learnedObjects.length})',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20),
          
          if (_learnedObjects.isEmpty) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No trained objects yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use the form above to teach the AI your first object type',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _learnedObjects.length,
              itemBuilder: (context, index) {
                final object = _learnedObjects[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.psychology,
                            color: Colors.green[600],
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                object['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.image, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    '${object['training_images_count'] ?? 0} training images',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (object['learned_at'] != null) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      'Trained: ${object['learned_at'].toString().substring(0, 10)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              width: 120,
                              child: ElevatedButton.icon(
                                onPressed: () => _countLearnedObject(object['name']),
                                icon: Icon(Icons.analytics_outlined, size: 20),
                                label: Text('Test Count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 120,
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteObject(object['name']),
                                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[600]),
                                label: Text('Delete', style: TextStyle(color: Colors.red[600], fontSize: 14)),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  side: BorderSide(color: Colors.red[300]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
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
        ],
      ),
    );
  }
}
