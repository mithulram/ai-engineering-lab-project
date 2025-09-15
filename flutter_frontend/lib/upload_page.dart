import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'models/counting_result.dart';
import 'services/item_type_service.dart';

class UploadPage extends StatefulWidget {
  final Function(CountingResult) onResultReceived;
  
  const UploadPage({super.key, required this.onResultReceived});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? _selectedObjectType;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isProcessing = false;
  
  final List<String> _objectTypes = ItemTypeService.getAllCanonicalTypes();
  final TextEditingController _itemTypeController = TextEditingController();
  List<String> _suggestions = [];
  bool _showSuggestions = false;

  void _pickImage() {
    try {
      debugPrint('Image picker clicked');
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.multiple = false;
      
      // Add to DOM and trigger click
      html.document.body?.children.add(uploadInput);
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        try {
          debugPrint('File selected, processing...');
          final files = uploadInput.files;
          if (files != null && files.isNotEmpty) {
            final file = files[0];
            debugPrint('File name: ${file.name}, size: ${file.size}');
            
            final reader = html.FileReader();
            
            reader.onLoadEnd.listen((e) {
              try {
                final result = reader.result;
                if (result != null) {
                  setState(() {
                    _selectedImageBytes = Uint8List.fromList((result as List<int>));
                    _selectedImageName = file.name;
                  });
                  debugPrint('Image loaded successfully: ${file.name}');
                  _showSnackBar('Image selected: ${file.name}');
                } else {
                  debugPrint('FileReader result is null');
                  _showSnackBar('Failed to load image');
                }
              } catch (e) {
                debugPrint('Error in onLoadEnd: $e');
                _showSnackBar('Error loading image: $e');
              } finally {
                // Remove from DOM
                uploadInput.remove();
              }
            });
            
            reader.onError.listen((e) {
              debugPrint('FileReader error: $e');
              _showSnackBar('Error reading file: $e');
              uploadInput.remove();
            });
            
            reader.readAsArrayBuffer(file);
          } else {
            debugPrint('No files selected');
            uploadInput.remove();
          }
        } catch (e) {
          debugPrint('Error in onChange: $e');
          _showSnackBar('Error selecting file: $e');
          uploadInput.remove();
        }
      });
      
      // Handle cancel case
      uploadInput.onInput.listen((e) {
        if (uploadInput.files?.isEmpty ?? true) {
          debugPrint('File selection cancelled');
          uploadInput.remove();
        }
      });
      
    } catch (e) {
      debugPrint('Error in _pickImage: $e');
      _showSnackBar('Error opening file picker: $e');
    }
  }

  Future<void> _countObjects() async {
    if (_selectedImageBytes == null || _selectedObjectType == null) {
      _showSnackBar('Please select an image and object type');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5001/api/count'),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: _selectedImageName,
        ),
      );
      
      request.fields['item_type'] = _selectedObjectType!;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final result = json.decode(responseData);
        final countingResult = CountingResult.fromJson(
          result, 
          _selectedImageBytes!, 
          _selectedImageName!,
        );
        widget.onResultReceived(countingResult);
      } else if (response.statusCode == 403) {
        // Handle blocked response
        final blockedData = json.decode(responseData);
        _showBlockedDialog(blockedData);
      } else {
        final error = json.decode(responseData);
        _showSnackBar('Error: ${error['error']}');
      }
    } catch (e) {
      _showSnackBar('Failed to process image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          title: const Text('Counting Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultRow(
                Icons.category, 
                'Object Type', 
                result['item_type'].toString().toUpperCase(),
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                Icons.numbers, 
                'Count', 
                result['count'].toString(),
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                Icons.verified, 
                'Confidence', 
                '${(result['confidence_score'] * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              _buildResultRow(
                Icons.timer, 
                'Processing Time', 
                '${result['processing_time'].toStringAsFixed(2)}s',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon, 
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showBlockedDialog(Map<String, dynamic> blockedData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.block,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          title: const Text('Request Blocked'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your request was blocked by the safety system.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (blockedData['reasons'] != null) ...[
                Text(
                  'Reasons:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...((blockedData['reasons'] as List?) ?? []).map((reason) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text('• $reason'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (blockedData['evidence'] != null && blockedData['evidence']['violations'] != null) ...[
                Text(
                  'Evidence:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...((blockedData['evidence']['violations'] as List?) ?? []).map((violation) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text('• ${violation['reason'] ?? 'Unknown violation'}'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (blockedData['evidence'] != null && blockedData['evidence']['violations'] != null) ...[
                ElevatedButton.icon(
                  onPressed: () => _showEvidenceDetails(blockedData['evidence']),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Evidence Details'),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showEvidenceDetails(Map<String, dynamic> evidence) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Evidence Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Violation Details:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...((evidence['violations'] as List?) ?? []).map((violation) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type: ${violation['type'] ?? 'Unknown'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (violation['reason'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Reason: ${violation['reason']}'),
                        ],
                        if (violation['details'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Details: ${violation['details']}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;
    
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 1000 : double.infinity,
          ),
          child: Column(
            children: [
            // Upload Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Image for Object Counting',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Object Type Selection
                  Text(
                    'What objects do you want to count?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _itemTypeController,
                        decoration: InputDecoration(
                          hintText: 'Type object type (e.g., car, person, tree...)',
                          border: const OutlineInputBorder(),
                          suffixIcon: _itemTypeController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _itemTypeController.clear();
                                    setState(() {
                                      _selectedObjectType = null;
                                      _showSuggestions = false;
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedObjectType = ItemTypeService.normalizeItemType(value);
                            _suggestions = ItemTypeService.getSuggestions(value);
                            _showSuggestions = value.isNotEmpty && _suggestions.isNotEmpty;
                          });
                        },
                        onTap: () {
                          if (_itemTypeController.text.isEmpty) {
                            setState(() {
                              _suggestions = ItemTypeService.getAllCanonicalTypes();
                              _showSuggestions = true;
                            });
                          }
                        },
                      ),
                      if (_showSuggestions && _suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return ListTile(
                                dense: true,
                                title: Text(suggestion),
                                onTap: () {
                                  _itemTypeController.text = suggestion;
                                  setState(() {
                                    _selectedObjectType = suggestion;
                                    _showSuggestions = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      if (_selectedObjectType != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selected: ${_selectedObjectType!.toUpperCase()}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Image Upload Area
                  _selectedImageBytes != null 
                    ? _buildImagePreview(isMediumScreen)
                    : _buildUploadArea(isMediumScreen),
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: (_selectedImageBytes != null && 
                                 _selectedObjectType != null && 
                                 !_isProcessing) 
                        ? _countObjects 
                        : null,
                      child: _isProcessing 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Processing Image...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome),
                              const SizedBox(width: 8),
                              const Text('Count Objects'),
                            ],
                          ),
                    ),
                  ),
                  
                  // Clear/Reset button for when image is selected
                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedImageBytes = null;
                            _selectedImageName = null;
                            _selectedObjectType = null;
                          });
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear),
                            SizedBox(width: 8),
                            Text('Start Over'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
            // How It Works Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How It Works',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    isMediumScreen 
                      ? Row(
                          children: [
                            Expanded(
                              child: _buildStep(
                                '1',
                                'Segment',
                                'SAM identifies and separates objects in your image',
                                Icons.auto_fix_high,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStep(
                                '2',
                                'Classify',
                                'ResNet-50 determines what each object is',
                                Icons.category,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStep(
                                '3',
                                'Refine',
                                'DistilBERT standardizes and counts your target objects',
                                Icons.tune,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildStep(
                              '1',
                              'Segment',
                              'SAM identifies and separates objects in your image',
                              Icons.auto_fix_high,
                            ),
                            const SizedBox(height: 24),
                            _buildStep(
                              '2',
                              'Classify',
                              'ResNet-50 determines what each object is',
                              Icons.category,
                            ),
                            const SizedBox(height: 24),
                            _buildStep(
                              '3',
                              'Refine',
                              'DistilBERT standardizes and counts your target objects',
                              Icons.tune,
                            ),
                          ],
                        ),
                  ],
                ),
              ),
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
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: isMediumScreen ? 240 : 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined, 
                size: 64, 
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Drop your image here, or click to browse',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Supports PNG, JPG, JPEG, GIF, BMP up to 16MB',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        // Image preview container
        Container(
          width: double.infinity,
          height: isMediumScreen ? 400 : 300,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _selectedImageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image could not be displayed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Image details and actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Success icon
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              
              // Image details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image Ready!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedImageName ?? 'Selected Image',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_selectedImageBytes!.length / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Change image button
              FilledButton.tonal(
                onPressed: _pickImage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 16),
                    SizedBox(width: 8),
                    Text('Change'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String title, String description, IconData icon) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
