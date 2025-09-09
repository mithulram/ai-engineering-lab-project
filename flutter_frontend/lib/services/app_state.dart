import 'package:flutter/foundation.dart';
import '../models/counting_result.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final List<CountingResult> _results = [];
  CountingResult? _currentResult;

  List<CountingResult> get results => List.unmodifiable(_results);
  CountingResult? get currentResult => _currentResult;

  void addResult(CountingResult result) {
    _results.insert(0, result); // Add to beginning for latest first
    _currentResult = result;
    notifyListeners();
  }

  void updateResult(String id, {String? correctedCount, String? userFeedback}) {
    final index = _results.indexWhere((result) => result.id == id);
    if (index != -1) {
      _results[index] = _results[index].copyWith(
        correctedCount: correctedCount,
        userFeedback: userFeedback,
      );
      if (_currentResult?.id == id) {
        _currentResult = _results[index];
      }
      notifyListeners();
    }
  }

  void setCurrentResult(CountingResult result) {
    _currentResult = result;
    notifyListeners();
  }

  void clearCurrentResult() {
    _currentResult = null;
    notifyListeners();
  }
}
