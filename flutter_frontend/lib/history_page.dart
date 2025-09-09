import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/app_state.dart';

class HistoryPageWidget extends StatefulWidget {
  const HistoryPageWidget({super.key});

  @override
  State<HistoryPageWidget> createState() => _HistoryPageWidgetState();
}

class _HistoryPageWidgetState extends State<HistoryPageWidget> {
  final AppState _appState = AppState();
  String _filterObjectType = 'All';
  List<Map<String, dynamic>> _serverResults = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onStateChanged);
    _scrollController.addListener(_onScroll);
    _loadHistoryFromServer();
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreResults();
    }
  }

  Future<void> _loadHistoryFromServer() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/results?page=1&per_page=$_itemsPerPage'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _serverResults = List<Map<String, dynamic>>.from(data['results']);
          _hasMore = data['has_more'] ?? false;
          _currentPage = 1;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await http.get(
        Uri.parse('http://localhost:5001/api/results?page=$nextPage&per_page=$_itemsPerPage'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _serverResults.addAll(List<Map<String, dynamic>>.from(data['results']));
          _hasMore = data['has_more'] ?? false;
          _currentPage = nextPage;
        });
      }
    } catch (e) {
      debugPrint('Error loading more results: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshHistory() async {
    _currentPage = 1;
    _hasMore = true;
    _serverResults.clear();
    await _loadHistoryFromServer();
  }

  List<Map<String, dynamic>> get _allResults {
    // Combine local app state results with server results
    List<Map<String, dynamic>> combined = [];
    
    // Add local results first (most recent)
    for (var result in _appState.results) {
      combined.add({
        'id': result.id,
        'item_type': result.objectType,
        'count': result.count,
        'confidence_score': result.confidence,
        'processing_time': result.processingTime,
        'timestamp': result.timestamp.toIso8601String(),
        'corrected_count': result.correctedCount,
        'user_feedback': result.userFeedback,
        'image_bytes': result.imageBytes,
        'image_name': result.imageName,
        'is_local': true,
      });
    }
    
    // Add server results
    combined.addAll(_serverResults.map((r) => {...r, 'is_local': false}));
    
    return combined;
  }

  List<Map<String, dynamic>> get _filteredResults {
    if (_filterObjectType == 'All') {
      return _allResults;
    }
    return _allResults
        .where((result) => result['item_type'].toString().toLowerCase() == _filterObjectType.toLowerCase())
        .toList();
  }

  Set<String> get _availableObjectTypes {
    final types = _allResults.map((r) => r['item_type'].toString()).toSet();
    return {'All', ...types};
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;
    
    if (_allResults.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLargeScreen ? 1200 : double.infinity,
            ),
            child: Column(
              children: [
              // Header Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMediumScreen ? 32.0 : 20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Counting History',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          _buildStatsChip('Total', _allResults.length.toString()),
                          const SizedBox(width: 8),
                          _buildStatsChip('Local', _appState.results.length.toString()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Filter Section
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter by object type:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _filterObjectType,
                              items: _availableObjectTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type == 'All' ? type : type.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _filterObjectType = value!;
                                });
                              },
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
                // Results List
                if (results.isEmpty && !_isLoading)
                  _buildNoResultsForFilter()
                else ...[
                  ...results.map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildResultCard(result, isMediumScreen),
                  )),
                  
                  // Loading indicator at bottom
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  
                  // Load more button if there are more results
                  if (_hasMore && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: _loadMoreResults,
                          child: const Text('Load More'),
                        ),
                      ),
                    ),
                  
                  // End of results indicator
                  if (!_hasMore && _serverResults.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'All results loaded',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
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
                Icons.history, 
                size: 64, 
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'No History Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your counting history will appear here after you process some images.',
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

  Widget _buildNoResultsForFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off, 
              size: 48, 
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_filterObjectType"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different object type filter.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, bool isMediumScreen) {
    return Card(
      child: InkWell(
        onTap: () {
          if (result['is_local'] == true) {
            // Find the local result and set it as current
            final localResult = _appState.results.firstWhere(
              (r) => r.id == result['id'],
            );
            _appState.setCurrentResult(localResult);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['is_local'] == true 
                  ? 'Local result loaded! Switch to Results tab to view details.'
                  : 'Server result - image not available for viewing.',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMediumScreen ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: result['is_local'] == true 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          result['is_local'] == true ? Icons.phone_android : Icons.cloud,
                          size: 12,
                          color: result['is_local'] == true 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          result['is_local'] == true ? 'Local' : 'Server',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: result['is_local'] == true 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatServerDateTime(result['timestamp']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Main content
              isMediumScreen
                ? Row(
                    children: [
                      // Image thumbnail (only for local results)
                      if (result['is_local'] == true)
                        _buildImageThumbnail(result),
                      if (result['is_local'] == true)
                        const SizedBox(width: 24),
                      // Details
                      Expanded(child: _buildResultDetails(result)),
                      const SizedBox(width: 16),
                      // Action button
                      _buildActionButton(result),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (result['is_local'] == true)
                        _buildImageThumbnail(result),
                      if (result['is_local'] == true)
                        const SizedBox(height: 16),
                      _buildResultDetails(result),
                      const SizedBox(height: 16),
                      _buildActionButton(result),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(Map<String, dynamic> result) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: result['image_bytes'] != null
          ? Image.memory(
              result['image_bytes'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.broken_image,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_not_supported,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
      ),
    );
  }

  Widget _buildResultDetails(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatsChip(
              result['item_type'].toString().toUpperCase(), 
              result['count'].toString(),
            ),
            const SizedBox(width: 8),
            _buildConfidenceChip(result['confidence_score'].toDouble()),
          ],
        ),
        const SizedBox(height: 12),
        
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
                result['image_name']?.toString() ?? result['image_path']?.toString() ?? 'No image name',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Icon(
              Icons.timer,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${result['processing_time']?.toStringAsFixed(2) ?? '0.00'}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        if (result['corrected_count'] != null || result['user_feedback'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'User Corrected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(Map<String, dynamic> result) {
    return FilledButton.tonal(
      onPressed: result['is_local'] == true 
        ? () {
            final localResult = _appState.results.firstWhere(
              (r) => r.id == result['id'],
            );
            _appState.setCurrentResult(localResult);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Result loaded! Switch to Results tab to view details.')),
            );
          }
        : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            result['is_local'] == true ? Icons.visibility : Icons.cloud_off, 
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(result['is_local'] == true ? 'View Details' : 'Server Only'),
        ],
      ),
    );
  }

  Widget _buildStatsChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(double confidence) {
    final color = _getConfidenceColor(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  String _formatServerDateTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown time';
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }
}
