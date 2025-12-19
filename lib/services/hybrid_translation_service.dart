import 'package:flutter/foundation.dart';
import '../services/online_translation_service.dart';
import '../services/dictionary_service.dart';
import '../screens/model_download_screen.dart';

/// Translation service using Google ML Kit for on-device neural translation
class HybridTranslationService {
  final OnlineTranslationService _mlKitService;
  final DictionaryService _dictionaryService;
  bool _useOnlineTranslation = true;
  bool _useOnlineDictionary = true;

  HybridTranslationService()
      : _mlKitService = OnlineTranslationService(),
        _dictionaryService = DictionaryService();

  bool get isOnlineTranslationAvailable => _useOnlineTranslation && _mlKitService.isAvailable;
  bool get isOnlineDictionaryAvailable => _useOnlineDictionary && _dictionaryService.isAvailable;

  /// Check availability of services
  Future<void> checkOnlineServices() async {
    try {
      final translationAvailable = await _mlKitService.checkAvailability();
      final dictionaryAvailable = await _dictionaryService.checkAvailability();
      
      debugPrint(' ML Kit translation: ${translationAvailable ? "Available" : "Not available"}');
      debugPrint('📖 Online dictionary: ${dictionaryAvailable ? "Available" : "Offline"}');
    } catch (e) {
      debugPrint('⚠️ Failed to check services: $e');
    }
  }

  /// Translate text using Google ML Kit (on-device neural translation)
  Future<HybridTranslationResult> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'en',
  }) async {
    if (_useOnlineTranslation && _mlKitService.isAvailable) {
      try {
        final result = await _mlKitService.translate(
          text: text,
          sourceLang: sourceLang,
          targetLang: targetLang,
        );

        debugPrint('� ML Kit translation successful');

        return HybridTranslationResult(
          translatedText: result.translatedText,
          sourceLang: sourceLang,
          targetLang: targetLang,
          usedOnline: true,
          coverage: 1.0,
        );
      } catch (e) {
        debugPrint('⚠️ ML Kit translation failed: $e');
        throw Exception('Translation failed: $e');
      }
    }

    throw Exception('ML Kit translation is not available');
  }

  /// Get word definition using hybrid approach
  /// 1. Check offline static definitions
  /// 2. If not found, fetch from Free Dictionary API
  Future<String> getDefinition(String word, {String language = 'en'}) async {
    // Step 1: Check offline definitions (built into OCR service)
    final offlineDefinition = _getOfflineDefinition(word);
    if (offlineDefinition != null) {
      return offlineDefinition;
    }

    // Step 2: Try online dictionary
    if (_useOnlineDictionary && _dictionaryService.isAvailable) {
      try {
        final onlineDefinition = await _dictionaryService.getDefinition(word, language: language);
        return onlineDefinition.getSimpleSummary();
      } catch (e) {
        debugPrint('⚠️ Online dictionary lookup failed for "$word": $e');
      }
    }

    // Fallback
    return '$word: A word (definition not available)';
  }

  /// Get detailed word information
  Future<WordDefinition?> getDetailedDefinition(String word, {String language = 'en'}) async {
    if (_useOnlineDictionary && _dictionaryService.isAvailable) {
      try {
        return await _dictionaryService.getDefinition(word, language: language);
      } catch (e) {
        debugPrint('⚠️ Failed to get detailed definition for "$word": $e');
        return null;
      }
    }
    return null;
  }

  String? _getOfflineDefinition(String word) {
    // Hardcoded educational definitions from OCR service
    const definitions = {
      'photosynthesis': 'Photosynthesis: How plants use sunlight to make food',
      'mitochondria': 'Mitochondria: Small parts in cells that make energy',
      'democracy': 'Democracy: Government where people vote and decide',
      'cellular': 'Cellular: Related to cells in the body',
      'respiration': 'Respiration: How cells use oxygen to make energy',
      'sustainable': 'Sustainable: Can continue without causing harm',
      'biodiversity': 'Biodiversity: The variety of different plants and animals',
      'ecosystem': 'Ecosystems: Communities of living things and their environment',
    };

    return definitions[word.toLowerCase()];
  }

  /// Pre-download translation models for faster first use
  Future<void> preDownloadModels(List<String> languages) async {
    await _mlKitService.preDownloadModels(languages);
  }

  /// Check if a model is downloaded
  Future<ModelDownloadStatus> checkModelStatus(String language) async {
    return await _mlKitService.checkModelStatus(language);
  }

  /// Download a single model
  Future<void> downloadModel(String language, {Function(double)? onProgress}) async {
    await _mlKitService.downloadSingleModel(language, onProgress: onProgress);
  }

  /// Delete a model
  Future<void> deleteModel(String language) async {
    await _mlKitService.deleteModel(language);
  }

  void dispose() {
    _mlKitService.dispose();
    _dictionaryService.dispose();
  }
}

/// Result from hybrid translation
class HybridTranslationResult {
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final bool usedOnline;
  final double coverage;

  HybridTranslationResult({
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.usedOnline,
    required this.coverage,
  });

  String get source => 'On-Device (Google ML Kit)';
}
