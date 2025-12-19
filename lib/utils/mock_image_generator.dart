import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utility class for generating mock images for OCR testing
/// This simulates image capture before ESP32-CAM integration
class MockImageGenerator {
  /// Generate a mock image from handwriting strokes
  static Future<Uint8List> generateFromStrokes(List<Offset> points) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // White background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 300),
      Paint()..color = Colors.white,
    );

    // Draw strokes
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  /// Generate a simple mock image with placeholder content
  /// Used when no strokes are available
  static Future<Uint8List> generatePlaceholder() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 300),
      Paint()..color = Colors.white,
    );

    // Draw some mock "handwriting" lines
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Simulate wavy handwriting lines
    final path = Path();
    path.moveTo(50, 100);
    
    for (double x = 50; x < 350; x += 5) {
      final y = 100 + sin(x * 0.1) * 10;
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);

    // Second line
    final path2 = Path();
    path2.moveTo(50, 150);
    
    for (double x = 50; x < 300; x += 5) {
      final y = 150 + sin((x + 20) * 0.15) * 8;
      path2.lineTo(x, y);
    }
    
    canvas.drawPath(path2, paint);

    // Third line
    final path3 = Path();
    path3.moveTo(50, 200);
    
    for (double x = 50; x < 320; x += 5) {
      final y = 200 + sin((x + 40) * 0.12) * 12;
      path3.lineTo(x, y);
    }
    
    canvas.drawPath(path3, paint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 300);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  /// Generate mock image from text (renders text as image)
  /// Useful for creating test images with known content
  static Future<Uint8List> generateFromText(String text) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 600, 400),
      Paint()..color = Colors.white,
    );

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 10,
    );

    textPainter.layout(maxWidth: 560);
    textPainter.paint(canvas, const Offset(20, 20));

    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 400);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
