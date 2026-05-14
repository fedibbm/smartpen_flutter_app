import 'package:flutter/material.dart';

enum ConnectionType { wifi, bluetooth }

enum ConnectionStatus { disconnected, connecting, connected, error }

enum RecognitionStatus { idle, processing, completed, error }

enum TextComplexity { simple, medium, complex }

class SmartPenDevice {
  final String id;
  final String name;
  final ConnectionType type;
  final int batteryLevel;
  final double signalStrength;

  SmartPenDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.batteryLevel,
    required this.signalStrength,
  });

  SmartPenDevice copyWith({
    String? id,
    String? name,
    ConnectionType? type,
    int? batteryLevel,
    double? signalStrength,
  }) {
    return SmartPenDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }
}

class RecognizedText {
  final String id;
  final String originalText;
  final String simplifiedText;
  final List<String> keyWords;
  final TextComplexity complexity;
  final double confidence;
  final DateTime timestamp;
  final List<String> definitions;
  final int? frameId;
  final List<TextRegion>? regions;
  final String? processingMode;
  final String language; // NEW: language code (e.g., 'en', 'fr', 'ar')

  RecognizedText({
    required this.id,
    required this.originalText,
    required this.simplifiedText,
    required this.keyWords,
    required this.complexity,
    required this.confidence,
    required this.timestamp,
    required this.definitions,
    required this.language,
    this.frameId,
    this.regions,
    this.processingMode,
  });
}

class TextRegion {
  final String regionId;
  final String? trackingId;
  final List<int> bbox; // [x, y, width, height]
  final String text;
  final double confidence;
  final int frameId;

  TextRegion({
    required this.regionId,
    this.trackingId,
    required this.bbox,
    required this.text,
    required this.confidence,
    required this.frameId,
  });

  factory TextRegion.fromJson(Map<String, dynamic> json) {
    return TextRegion(
      regionId: json['region_id'] ?? '',
      trackingId: json['tracking_id'],
      bbox: List<int>.from(json['bbox'] ?? [0, 0, 0, 0]),
      text: json['text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      frameId: json['frame_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region_id': regionId,
      'tracking_id': trackingId,
      'bbox': bbox,
      'text': text,
      'confidence': confidence,
      'frame_id': frameId,
    };
  }
}

class PenStroke {
  final List<Offset> points;
  final DateTime timestamp;
  final bool isProcessed;
  final double strokeWidth;
  final Color color;

  PenStroke({
    required this.points,
    required this.timestamp,
    this.isProcessed = false,
    this.strokeWidth = 1.0,
    this.color = Colors.transparent,
  });

  PenStroke copyWith({
    List<Offset>? points,
    DateTime? timestamp,
    bool? isProcessed,
  }) {
    return PenStroke(
      points: points ?? this.points,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }
}
