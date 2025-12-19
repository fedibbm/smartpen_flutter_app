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

  RecognizedText({
    required this.id,
    required this.originalText,
    required this.simplifiedText,
    required this.keyWords,
    required this.complexity,
    required this.confidence,
    required this.timestamp,
    required this.definitions,
  });
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
