import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'services/app_state.dart';
import 'models/counting_result.dart';

class ResultsPageWidget extends StatefulWidget {
  const ResultsPageWidget({super.key});

  @override
  State<ResultsPageWidget> createState() => _ResultsPageWidgetState();
}

class _ResultsPageWidgetState extends State<ResultsPageWidget> {
  final AppState _appState = AppState();
  final TextEditingController _correctionController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _correctionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _submitCorrection() {
    if (_appState.currentResult != null) {
      _appState.updateResult(
        _appState.currentResult!.id,
        correctedCount: _correctionController.text.isNotEmpty 
          ? _correctionController.text 
          : null,
        userFeedback: _feedbackController.text.isNotEmpty 
          ? _feedbackController.text 
          : null,
      );
      _correctionController.clear();
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResult = _appState.currentResult;
    
    if (currentResult == null) {
      return _buildEmptyState();
    }

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
              // Image and Results Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Counting Results',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Layout based on screen size
                      isMediumScreen 
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image Section
                              Expanded(
                                flex: 1,
                                child: _buildImageSection(currentResult),
                              ),
                              const SizedBox(width: 32),
                              // Results Section
                              Expanded(
                                flex: 1,
                                child: _buildResultsSection(currentResult),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildImageSection(currentResult),
                              const SizedBox(height: 24),
                              _buildResultsSection(currentResult),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Correction Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
                  child: _buildCorrectionSection(currentResult),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insights_outlined, 
                size: 64, 
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'No Results Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upload an image to see counting results here.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  Widget _buildImageSection(CountingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploaded Image',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              result.imageBytes,
              fit: BoxFit.cover,
              height: 300,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.image,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              result.imageName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection(CountingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildResultCard(
          Icons.category,
          'Object Type',
          result.objectType.toUpperCase(),
          Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        
        _buildResultCard(
          Icons.numbers,
          'Count',
          result.count.toString(),
          Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        
        _buildResultCard(
          Icons.verified,
          'Confidence',
          '${(result.confidence * 100).toStringAsFixed(1)}%',
          _getConfidenceColor(result.confidence),
        ),
        const SizedBox(height: 12),
        
        _buildResultCard(
          Icons.timer,
          'Processing Time',
          '${result.processingTime.toStringAsFixed(2)}s',
          Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(height: 12),
        
        _buildResultCard(
          Icons.schedule,
          'Timestamp',
          _formatDateTime(result.timestamp),
          Theme.of(context).colorScheme.outline,
        ),
        
        if (result.correctedCount != null || result.userFeedback != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User Corrections',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (result.correctedCount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Corrected Count: ${result.correctedCount}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (result.userFeedback != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Feedback: ${result.userFeedback}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionSection(CountingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tune,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'Correct Results',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Help improve our AI by providing corrections and feedback',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _correctionController,
                decoration: InputDecoration(
                  labelText: 'Correct Count',
                  hintText: 'Enter the correct count if different from ${result.count}',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _submitCorrection,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text('Submit'),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            labelText: 'Additional Feedback',
            hintText: 'Any comments about the counting accuracy or suggestions?',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.feedback),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
