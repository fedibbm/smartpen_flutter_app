import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

/// On-device text recognition using Google ML Kit
/// Implements frame throttling, bounding box tracking, and smart deduplication
class MLKitTextRecognitionService {
  final TextRecognizer _textRecognizer;
  
  // Frame throttling
  DateTime? _lastProcessedTime;
  static const Duration _throttleDuration = Duration(milliseconds: 400); // 2.5 fps
  
  // Deduplication state
  final List<DetectedTextBlock> _recentBlocks = [];
  static const int _maxRecentBlocks = 30; // Keep last 30 detections (~12 seconds at 2.5 fps)
  static const double _positionOverlapThreshold = 0.80; // 80% overlap
  
  bool _isProcessing = false;
  
  MLKitTextRecognitionService({TextRecognizer? textRecognizer})
      : _textRecognizer = textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  /// Process a camera image with throttling and deduplication
  Future<MLKitOCRResult> processImage(CameraImage image, int imageRotation) async {
    // 1️⃣ THROTTLE: Check if enough time has passed since last processing
    final now = DateTime.now();
    if (_lastProcessedTime != null) {
      final timeSinceLastProcess = now.difference(_lastProcessedTime!);
      if (timeSinceLastProcess < _throttleDuration) {
        return MLKitOCRResult.throttled();
      }
    }
    
    // Prevent concurrent processing
    if (_isProcessing) {
      return MLKitOCRResult.throttled();
    }
    
    _isProcessing = true;
    _lastProcessedTime = now;
    
    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image, imageRotation);
      if (inputImage == null) {
        return MLKitOCRResult.error('Failed to convert camera image');
      }
      
      // Run ML Kit text recognition
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 2️⃣ BOUNDING BOXES: Extract text blocks with positions
      final detectedBlocks = <DetectedTextBlock>[];
      for (final block in recognizedText.blocks) {
        final textBlock = DetectedTextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: 1.0, // ML Kit doesn't provide confidence per block
          detectedAt: now,
        );
        detectedBlocks.add(textBlock);
      }
      
      // 3️⃣ DEDUPLICATE: Remove duplicates based on position + text
      final uniqueBlocks = _deduplicateBlocks(detectedBlocks);
      
      // Update recent blocks for future deduplication
      _updateRecentBlocks(uniqueBlocks);
      
      return MLKitOCRResult.success(
        blocks: uniqueBlocks,
        totalDetected: detectedBlocks.length,
        uniqueCount: uniqueBlocks.length,
        duplicatesRemoved: detectedBlocks.length - uniqueBlocks.length,
      );
      
    } catch (e) {
      debugPrint('ML Kit processing error: $e');
      return MLKitOCRResult.error(e.toString());
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Process a static image (from file or gallery)
  Future<MLKitOCRResult> processStaticImage(InputImage inputImage) async {
    if (_isProcessing) {
      return MLKitOCRResult.throttled();
    }
    
    _isProcessing = true;
    final now = DateTime.now();
    
    try {
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final detectedBlocks = <DetectedTextBlock>[];
      for (final block in recognizedText.blocks) {
        detectedBlocks.add(DetectedTextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          confidence: 1.0, // ML Kit doesn't provide confidence per block
          detectedAt: now,
        ));
      }
      
      return MLKitOCRResult.success(
        blocks: detectedBlocks,
        totalDetected: detectedBlocks.length,
        uniqueCount: detectedBlocks.length,
        duplicatesRemoved: 0,
      );
    } catch (e) {
      return MLKitOCRResult.error(e.toString());
    } finally {
      _isProcessing = false;
    }
  }
  
  /// 3️⃣ DEDUPLICATION LOGIC: Remove duplicates by position + text
  List<DetectedTextBlock> _deduplicateBlocks(List<DetectedTextBlock> newBlocks) {
    final uniqueBlocks = <DetectedTextBlock>[];
    
    for (final newBlock in newBlocks) {
      bool isDuplicate = false;
      
      // Check against recent blocks
      for (final recentBlock in _recentBlocks) {
        // Same text?
        final sameText = _isSimilarText(newBlock.text, recentBlock.text);
        
        // Same position? (80% overlap)
        final overlap = _calculateOverlap(newBlock.boundingBox, recentBlock.boundingBox);
        final samePosition = overlap >= _positionOverlapThreshold;
        
        // Recent? (within last N frames)
        final timeDiff = newBlock.detectedAt.difference(recentBlock.detectedAt);
        final recent = timeDiff.inSeconds < 15; // Last 15 seconds
        
        // If all three conditions met → duplicate
        if (sameText && samePosition && recent) {
          isDuplicate = true;
          debugPrint('  ⊗ Duplicate suppressed: "${newBlock.text.substring(0, newBlock.text.length.clamp(0, 30))}" (overlap: ${(overlap * 100).toStringAsFixed(0)}%)');
          break;
        }
      }
      
      if (!isDuplicate) {
        uniqueBlocks.add(newBlock);
      }
    }
    
    return uniqueBlocks;
  }
  
  /// Update recent blocks cache for deduplication
  void _updateRecentBlocks(List<DetectedTextBlock> newBlocks) {
    _recentBlocks.addAll(newBlocks);
    
    // Keep only recent blocks (FIFO)
    while (_recentBlocks.length > _maxRecentBlocks) {
      _recentBlocks.removeAt(0);
    }
    
    // Remove old blocks (>15 seconds)
    final now = DateTime.now();
    _recentBlocks.removeWhere((block) {
      final age = now.difference(block.detectedAt);
      return age.inSeconds > 15;
    });
  }
  
  /// Calculate overlap between two bounding boxes (IoU - Intersection over Union)
  double _calculateOverlap(Rect box1, Rect box2) {
    // Calculate intersection
    final x1 = box1.left.clamp(box2.left, box2.right);
    final y1 = box1.top.clamp(box2.top, box2.bottom);
    final x2 = box1.right.clamp(box2.left, box2.right);
    final y2 = box1.bottom.clamp(box2.top, box2.bottom);
    
    if (x2 < x1 || y2 < y1) {
      return 0.0; // No overlap
    }
    
    final intersectionArea = (x2 - x1) * (y2 - y1);
    final box1Area = box1.width * box1.height;
    final box2Area = box2.width * box2.height;
    final unionArea = box1Area + box2Area - intersectionArea;
    
    return unionArea > 0 ? intersectionArea / unionArea : 0.0;
  }
  
  /// Check if two text strings are similar (basic comparison)
  bool _isSimilarText(String text1, String text2) {
    final t1 = text1.trim().toLowerCase();
    final t2 = text2.trim().toLowerCase();
    
    // Exact match
    if (t1 == t2) return true;
    
    // Very similar (allow 1-2 char difference for OCR errors)
    if ((t1.length - t2.length).abs() <= 2) {
      int differences = 0;
      final minLen = t1.length < t2.length ? t1.length : t2.length;
      
      for (int i = 0; i < minLen; i++) {
        if (t1[i] != t2[i]) differences++;
        if (differences > 2) return false;
      }
      
      return differences <= 2;
    }
    
    return false;
  }
  
  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, int rotation) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      final imageRotationValue = InputImageRotationValue.fromRawValue(rotation);
      if (imageRotationValue == null) {
        debugPrint('Invalid image rotation: $rotation');
        return null;
      }
      
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) {
        debugPrint('Unsupported image format: ${image.format.raw}');
        return null;
      }
      
      // Use the first plane's metadata
      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotationValue,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }
  
  /// Clear recent blocks cache
  void clearCache() {
    _recentBlocks.clear();
    _lastProcessedTime = null;
  }
  
  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
    _recentBlocks.clear();
  }
}

/// Detected text block with position and metadata
class DetectedTextBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final DateTime detectedAt;
  
  DetectedTextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
    required this.detectedAt,
  });
  
  @override
  String toString() {
    return 'DetectedTextBlock(text: "$text", bbox: $boundingBox, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}

/// Result from ML Kit OCR processing
class MLKitOCRResult {
  final bool success;
  final List<DetectedTextBlock> blocks;
  final int totalDetected;
  final int uniqueCount;
  final int duplicatesRemoved;
  final String? error;
  final bool wasThrottled;
  
  MLKitOCRResult._({
    required this.success,
    required this.blocks,
    required this.totalDetected,
    required this.uniqueCount,
    required this.duplicatesRemoved,
    this.error,
    this.wasThrottled = false,
  });
  
  factory MLKitOCRResult.success({
    required List<DetectedTextBlock> blocks,
    required int totalDetected,
    required int uniqueCount,
    required int duplicatesRemoved,
  }) {
    return MLKitOCRResult._(
      success: true,
      blocks: blocks,
      totalDetected: totalDetected,
      uniqueCount: uniqueCount,
      duplicatesRemoved: duplicatesRemoved,
    );
  }
  
  factory MLKitOCRResult.error(String error) {
    return MLKitOCRResult._(
      success: false,
      blocks: [],
      totalDetected: 0,
      uniqueCount: 0,
      duplicatesRemoved: 0,
      error: error,
    );
  }
  
  factory MLKitOCRResult.throttled() {
    return MLKitOCRResult._(
      success: false,
      blocks: [],
      totalDetected: 0,
      uniqueCount: 0,
      duplicatesRemoved: 0,
      wasThrottled: true,
    );
  }
  
  /// Get combined text from all blocks
  String get combinedText => blocks.map((b) => b.text).join('\n');
  
  /// Get statistics summary
  String get summary {
    if (wasThrottled) return 'Throttled';
    if (!success) return 'Error: $error';
    return 'Detected: $totalDetected, Unique: $uniqueCount, Removed: $duplicatesRemoved';
  }
}
