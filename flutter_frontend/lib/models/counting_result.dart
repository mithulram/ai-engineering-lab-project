import 'dart:typed_data';

class CountingResult {
  final String id;
  final String objectType;
  final int count;
  final double confidence;
  final double processingTime;
  final DateTime timestamp;
  final Uint8List imageBytes;
  final String imageName;
  final String? correctedCount;
  final String? userFeedback;

  CountingResult({
    required this.id,
    required this.objectType,
    required this.count,
    required this.confidence,
    required this.processingTime,
    required this.timestamp,
    required this.imageBytes,
    required this.imageName,
    this.correctedCount,
    this.userFeedback,
  });

  factory CountingResult.fromJson(Map<String, dynamic> json, Uint8List imageBytes, String imageName) {
    return CountingResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      objectType: json['item_type'],
      count: json['count'],
      confidence: json['confidence_score'].toDouble(),
      processingTime: json['processing_time'].toDouble(),
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
      imageName: imageName,
    );
  }

  CountingResult copyWith({
    String? correctedCount,
    String? userFeedback,
  }) {
    return CountingResult(
      id: id,
      objectType: objectType,
      count: count,
      confidence: confidence,
      processingTime: processingTime,
      timestamp: timestamp,
      imageBytes: imageBytes,
      imageName: imageName,
      correctedCount: correctedCount ?? this.correctedCount,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }
}
