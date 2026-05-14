import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';
import '../models/smart_pen_models.dart';

/// Service for communicating with the Python OpenCV OCR backend
/// This service is ACTIVE and used in the current prototype
class OcrBackendService {
  final http.Client _client;
  bool _isConnected = false;
  
  OcrBackendService({http.Client? client}) 
    : _client = client ?? http.Client();

  bool get isConnected => _isConnected;

  /// Check if OCR server is healthy and reachable
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(
            Uri.parse(NetworkConfig.ocrHealthEndpoint),
          )
          .timeout(NetworkConfig.connectionTimeout);

      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Extract text from image bytes
  /// Sends image to Python OpenCV server and receives extracted text
  Future<OcrResponse> extractText(Uint8List imageBytes) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(NetworkConfig.ocrExtractTextEndpoint),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'frame_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        NetworkConfig.readTimeout,
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OcrResponse.fromJson(jsonData);
      } else {
        throw OcrException(
          'OCR server returned status ${response.statusCode}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw OcrException('Request timed out', 408);
    } catch (e) {
      if (e is OcrException) rethrow;
      throw OcrException('Failed to extract text: $e', 500);
    }
  }

  /// Extract text with retry logic
  Future<OcrResponse> extractTextWithRetry(Uint8List imageBytes) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < NetworkConfig.maxRetries) {
      try {
        return await extractText(imageBytes);
      } catch (e) {
        lastException = e as Exception;
        attempts++;
        
        if (attempts < NetworkConfig.maxRetries) {
          await Future.delayed(NetworkConfig.retryDelay);
        }
      }
    }

    throw lastException ?? OcrException('Max retries exceeded', 500);
  }

  /// Process image and extract text (convenience method)
  Future<OcrResponse> processImage(Uint8List imageBytes) async {
    return await extractTextWithRetry(imageBytes);
  }

  /// Extract text from multiple frames with server-side stitching
  /// Sends all frames to the server which stitches them together before OCR
  Future<OcrResponse> extractTextFromFrames(List<Uint8List> frames) async {
    if (frames.isEmpty) {
      throw OcrException('No frames provided', 400);
    }

    // Create defensive copy to prevent concurrent modification
    final framesCopy = List<Uint8List>.from(frames);

    if (framesCopy.length == 1) {
      // Single frame, use regular OCR endpoint
      return await processImage(framesCopy.first);
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(NetworkConfig.ocrStitchEndpoint),
      );

      // Add each frame with sequential field names (file0, file1, file2, ...)
      for (int i = 0; i < framesCopy.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file$i',
            framesCopy[i],
            filename: 'frame_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          ),
        );
      }
      
      // Use segmentation mode by default (avoids LAPACK errors with stitching)
      request.fields['use_segmentation'] = 'true';
      request.fields['auto_detect'] = 'true';
      request.fields['default_lang'] = 'eng';

      final streamedResponse = await request.send().timeout(
        NetworkConfig.readTimeout,
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return OcrResponse.fromJson(jsonData);
      } else {
        // Try to parse error message from server
        try {
          final errorData = json.decode(response.body);
          final errorMsg = errorData['error'] ?? 'Unknown error';
          throw OcrException(
            'Server-side stitching failed: $errorMsg',
            response.statusCode,
          );
        } catch (_) {
          throw OcrException(
            'Server-side stitching failed with status ${response.statusCode}',
            response.statusCode,
          );
        }
      }
    } on TimeoutException {
      throw OcrException('Frame stitching request timed out', 408);
    } catch (e) {
      if (e is OcrException) rethrow;
      throw OcrException('Failed to stitch and extract text: $e', 500);
    }
  }

  /// Batch process multiple images
  Future<List<OcrResponse>> extractTextBatch(List<Uint8List> images) async {
    final results = <OcrResponse>[];
    
    for (final image in images) {
      try {
        final response = await extractTextWithRetry(image);
        results.add(response);
      } catch (e) {
        // Continue processing remaining images even if one fails
        results.add(OcrResponse.error(e.toString()));
      }
    }
    
    return results;
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Response model from OCR backend
class OcrResponse {
  final String extractedText;
  final double confidence;
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final int? frameId;
  final List<Map<String, dynamic>>? regions;
  final String? processingMode;
  final int? totalRegionsDetected;
  final int? uniqueRegions;
  final int? duplicatesSuppressed;

  OcrResponse({
    required this.extractedText,
    required this.confidence,
    required this.success,
    this.error,
    required this.timestamp,
    this.metadata,
    this.frameId,
    this.regions,
    this.processingMode,
    this.totalRegionsDetected,
    this.uniqueRegions,
    this.duplicatesSuppressed,
  });

  factory OcrResponse.fromJson(Map<String, dynamic> json) {
    return OcrResponse(
      extractedText: json['text'] ?? json['extracted_text'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      success: json['success'] ?? true,
      error: json['error'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      metadata: json['metadata'],
      frameId: json['frame_id'],
      regions: json['regions'] != null 
          ? List<Map<String, dynamic>>.from(json['regions'])
          : null,
      processingMode: json['processing_mode'],
      totalRegionsDetected: json['total_regions_detected'],
      uniqueRegions: json['unique_regions'],
      duplicatesSuppressed: json['duplicates_suppressed'],
    );
  }

  factory OcrResponse.error(String errorMessage) {
    return OcrResponse(
      extractedText: '',
      confidence: 0.0,
      success: false,
      error: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extracted_text': extractedText,
      'confidence': confidence,
      'success': success,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Convert OCR response to RecognizedText model
  RecognizedText toRecognizedText() {
    return toRecognizedTextWithCorrected(extractedText);
  }

  /// Convert OCR response with corrected text
  RecognizedText toRecognizedTextWithCorrected(String correctedText) {
    // Extract keywords (simple implementation - can be enhanced)
    final words = correctedText.split(RegExp(r'\s+'));
    final keywords = words
        .where((word) => word.length > 5)
        .take(5)
        .toList();

    return RecognizedText(
      id: timestamp.millisecondsSinceEpoch.toString(),
      originalText: correctedText, // Use corrected text as the main text
      simplifiedText: _simplifyText(correctedText),
      keyWords: keywords,
      complexity: _calculateComplexity(correctedText),
      confidence: confidence,
      timestamp: timestamp,
      definitions: _generateDefinitions(keywords),
      language: 'en', // TODO: Replace with actual language detection if available
    );
  }

  // Helper methods for text processing
  static String _simplifyText(String text) {
    // Basic text simplification for dyslexic users
    // Break down complex sentences and use simpler alternatives
    
    final simplifications = {
      'phenomenon': 'thing that happens',
      'photosynthesis': 'how plants make food',
      'fundamental': 'very important',
      'democracy': 'government by the people',
      'participation': 'taking part',
      'citizens': 'people of a country',
      'mitochondria': 'cell parts that make energy',
      'cellular': 'related to cells',
      'respiration': 'breathing process',
      'sustainable': 'can keep going',
      'development': 'growth',
      'environmental': 'about nature',
      'protection': 'keeping safe',
      'gravity': 'pull toward Earth',
      'attracts': 'pulls together',
      'transmits': 'sends',
      'approximately': 'about',
      'biodiversity': 'variety of life',
      'ecosystems': 'nature systems',
    };
    
    var simplified = text;
    simplifications.forEach((complex, simple) {
      simplified = simplified.replaceAllMapped(
        RegExp(complex, caseSensitive: false),
        (match) => simple,
      );
    });
    
    return simplified;
  }

  static TextComplexity _calculateComplexity(String text) {
    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return TextComplexity.simple;
    
    final avgWordLength = words.fold<int>(0, (sum, word) => sum + word.length) / words.length;
    
    if (avgWordLength < 5) return TextComplexity.simple;
    if (avgWordLength < 7) return TextComplexity.medium;
    return TextComplexity.complex;
  }

  static List<String> _generateDefinitions(List<String> keywords) {
    // Simple definitions for common complex words
    final definitions = {
      'phenomenon': 'Phenomenon: Something interesting that happens in nature',
      'photosynthesis': 'Photosynthesis: How plants use sunlight to make food',
      'fundamental': 'Fundamental: Very important or basic',
      'democracy': 'Democracy: Government where people vote and decide',
      'participation': 'Participation: Taking part in something',
      'citizens': 'Citizens: People who belong to a country',
      'mitochondria': 'Mitochondria: Small parts in cells that make energy',
      'cellular': 'Cellular: Related to cells in the body',
      'respiration': 'Respiration: How cells use oxygen to make energy',
      'sustainable': 'Sustainable: Can continue without causing harm',
      'development': 'Development: Growth and improvement',
      'environmental': 'Environmental: Related to nature and our surroundings',
      'protection': 'Protection: Keeping something safe from harm',
      'gravity': 'Gravity: The force that pulls things toward Earth',
      'transmits': 'Transmits: Sends information from one place to another',
      'nervous': 'Nervous: Related to nerves that send signals in the body',
      'climate': 'Climate: The usual weather in an area over time',
      'renewable': 'Renewable: Can be used again or replaced naturally',
      'approximately': 'Approximately: About or close to a number',
      'biodiversity': 'Biodiversity: The variety of different plants and animals',
      'ecosystems': 'Ecosystems: Communities of living things and their environment',
    };
    
    return keywords
        .map((word) => definitions[word.toLowerCase()] ?? '$word: A complex word')
        .toList();
  }
}

/// Custom exception for OCR errors
class OcrException implements Exception {
  final String message;
  final int statusCode;

  OcrException(this.message, this.statusCode);

  @override
  String toString() => 'OcrException: $message (Status: $statusCode)';
}
