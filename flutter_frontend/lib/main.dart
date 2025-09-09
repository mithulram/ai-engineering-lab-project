import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'upload_page.dart';
import 'results_page.dart';
import 'history_page.dart';
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

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5001/api/health'));
      if (response.statusCode == 200) {
        setState(() {
          _backendStatus = 'healthy';
        });
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
