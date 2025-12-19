import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../screens/model_download_screen.dart';

/// Service for on-device translation using Google ML Kit
/// Completely offline, no API required, runs on device
class OnlineTranslationService {
  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, bool> _downloadedModels = {};
  bool _isAvailable = true; // ML Kit is always available

  OnlineTranslationService();

  bool get isAvailable => _isAvailable;

  /// Check if ML Kit translation is available (always true)
  Future<bool> checkAvailability() async {
    _isAvailable = true;
    return true;
  }

  /// Get or create translator for language pair
  Future<OnDeviceTranslator> _getTranslator(String sourceLang, String targetLang) async {
    final key = '${sourceLang}_$targetLang';
    
    if (_translators.containsKey(key)) {
      return _translators[key]!;
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == sourceLang,
        orElse: () => TranslateLanguage.english,
      ),
      targetLanguage: TranslateLanguage.values.firstWhere(
        (lang) => lang.bcpCode == targetLang,
        orElse: () => TranslateLanguage.french,
      ),
    );

    _translators[key] = translator;
    return translator;
  }

  /// Download language model if not already downloaded
  Future<bool> _ensureModelDownloaded(OnDeviceTranslator translator, String key) async {
    if (_downloadedModels[key] == true) {
      return true;
    }

    try {
      final modelManager = OnDeviceTranslatorModelManager();
      
      // Check and download source language model with timeout
      final isDownloaded = await modelManager.isModelDownloaded(
        translator.sourceLanguage.bcpCode,
      ).timeout(Duration(seconds: 10));
      
      if (!isDownloaded) {
        debugPrint('📥 Downloading translation model for ${translator.sourceLanguage.bcpCode} (1-2 minutes)...');
        await modelManager.downloadModel(translator.sourceLanguage.bcpCode)
            .timeout(Duration(minutes: 5));
        debugPrint('✅ Source model downloaded successfully');
      }

      // Check and download target language model with timeout
      final isTargetDownloaded = await modelManager.isModelDownloaded(
        translator.targetLanguage.bcpCode,
      ).timeout(Duration(seconds: 10));
      
      if (!isTargetDownloaded) {
        debugPrint('📥 Downloading translation model for ${translator.targetLanguage.bcpCode} (1-2 minutes)...');
        await modelManager.downloadModel(translator.targetLanguage.bcpCode)
            .timeout(Duration(minutes: 5));
        debugPrint('✅ Target model downloaded successfully');
      }

      _downloadedModels[key] = true;
      return true;
    } on TimeoutException {
      debugPrint('⚠️ Model download timed out - please check your internet connection');
      return false;
    } catch (e) {
      debugPrint('⚠️ Failed to download translation model: $e');
      return false;
    }
  }

  /// Translate text using Google ML Kit (on-device)
  /// Supports: en, fr, ar, es, de, it, pt, ru, zh, ja, ko, and 50+ more
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final key = '${sourceLang}_$targetLang';
      final translator = await _getTranslator(sourceLang, targetLang);
      
      // Ensure model is downloaded
      final modelReady = await _ensureModelDownloaded(translator, key);
      if (!modelReady) {
        throw TranslationException('Translation model not available', 503);
      }

      // Translate
      final translatedText = await translator.translateText(text);

      return TranslationResult(
        translatedText: translatedText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        success: true,
      );
    } on TimeoutException {
      throw TranslationException('Translation request timed out', 408);
    } catch (e) {
      if (e is TranslationException) rethrow;
      throw TranslationException('Translation failed: $e', 500);
    }
  }

  /// Get available languages
  Future<List<LanguageInfo>> getAvailableLanguages() async {
    return TranslateLanguage.values.map((lang) {
      return LanguageInfo(
        code: lang.bcpCode,
        name: _getLanguageName(lang.bcpCode),
      );
    }).toList();
  }

  String _getLanguageName(String code) {
    final names = {
      'en': 'English',
      'fr': 'French',
      'ar': 'Arabic',
      'es': 'Spanish',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
    };
    return names[code] ?? code.toUpperCase();
  }

  /// Pre-download models for specified languages (for faster first use)
  Future<void> preDownloadModels(List<String> targetLanguages) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      
      // Always download English (source language)
      final enDownloaded = await modelManager.isModelDownloaded('en').timeout(Duration(seconds: 10));
      if (!enDownloaded) {
        debugPrint('📥 Pre-downloading English model (this may take 1-2 minutes)...');
        await modelManager.downloadModel('en').timeout(Duration(minutes: 5));
        debugPrint('✅ English model downloaded');
      } else {
        debugPrint('✅ English model already downloaded');
      }
      
      // Download each target language
      for (final lang in targetLanguages) {
        final isDownloaded = await modelManager.isModelDownloaded(lang).timeout(Duration(seconds: 10));
        if (!isDownloaded) {
          debugPrint('📥 Pre-downloading $lang model (this may take 1-2 minutes)...');
          await modelManager.downloadModel(lang).timeout(Duration(minutes: 5));
          debugPrint('✅ $lang model downloaded');
          
          // Mark as downloaded
          final key = 'en_$lang';
          _downloadedModels[key] = true;
        } else {
          debugPrint('✅ $lang model already downloaded');
        }
      }
      
      debugPrint('🎉 All translation models ready!');
    } on TimeoutException {
      debugPrint('⚠️ Model pre-download timed out - will download on first use');
    } catch (e) {
      debugPrint('⚠️ Failed to pre-download models: $e');
    }
  }

  /// Check if a model is downloaded
  Future<ModelDownloadStatus> checkModelStatus(String language) async {
    try {
      debugPrint('🔍 Checking model status for: $language');
      final modelManager = OnDeviceTranslatorModelManager();
      final isDownloaded = await modelManager.isModelDownloaded(language).timeout(Duration(seconds: 10));
      debugPrint('📊 Model $language status: ${isDownloaded ? "DOWNLOADED" : "NOT DOWNLOADED"}');
      return isDownloaded ? ModelDownloadStatus.downloaded : ModelDownloadStatus.notStarted;
    } catch (e) {
      debugPrint('❌ Failed to check model status for $language: $e');
      return ModelDownloadStatus.error;
    }
  }

  /// Download a single model with progress tracking
  Future<void> downloadSingleModel(String language, {Function(double)? onProgress}) async {
    debugPrint('🚀 downloadSingleModel called for: $language');
    try {
      debugPrint('📋 Step 1: Creating model manager...');
      final modelManager = OnDeviceTranslatorModelManager();
      
      debugPrint('📋 Step 2: Checking if model already exists...');
      final isDownloaded = await modelManager.isModelDownloaded(language).timeout(Duration(seconds: 10));
      
      if (isDownloaded) {
        debugPrint('✅ $language model already downloaded - skipping');
        return;
      }

      debugPrint('📋 Step 3: Starting download for $language model...');
      debugPrint('⏰ This will timeout after 3 minutes');
      
      // ML Kit doesn't provide granular progress, so we simulate it
      if (onProgress != null) {
        debugPrint('📊 Progress callback: 10%');
        onProgress(0.1);
      }
      
      // Try to download with a shorter timeout first
      debugPrint('🌐 Attempting download with 3-minute timeout...');
      bool downloadSuccess = false;
      
      // Create a periodic checker to monitor download status
      int checkCount = 0;
      final checkTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
        checkCount++;
        debugPrint('⏱️ Download check #$checkCount for $language (${checkCount * 10} seconds elapsed)');
        try {
          final status = await modelManager.isModelDownloaded(language).timeout(Duration(seconds: 5));
          if (status) {
            debugPrint('✅ Model $language detected as downloaded during check!');
            timer.cancel();
          }
        } catch (e) {
          debugPrint('⚠️ Check failed: $e');
        }
      });
      
      try {
        await modelManager.downloadModel(language).timeout(
          Duration(minutes: 3),
          onTimeout: () {
            checkTimer.cancel();
            debugPrint('⏱️ TIMEOUT: Download exceeded 3 minutes for $language');
            throw TimeoutException('Download exceeded 3 minutes');
          },
        );
        checkTimer.cancel();
        downloadSuccess = true;
        debugPrint('✅ Download API call completed for $language');
      } catch (e) {
        checkTimer.cancel();
        debugPrint('❌ Download attempt failed: $e');
        
        // Check if it actually downloaded despite the error
        debugPrint('🔍 Verifying if model was downloaded anyway...');
        final isNowDownloaded = await modelManager.isModelDownloaded(language).timeout(Duration(seconds: 10));
        
        if (isNowDownloaded) {
          debugPrint('✅ Model $language is now available despite error!');
          downloadSuccess = true;
        } else {
          debugPrint('❌ Model $language is still not available');
          rethrow;
        }
      }
      
      if (downloadSuccess) {
        if (onProgress != null) {
          debugPrint('📊 Progress callback: 100%');
          onProgress(1.0);
        }
        
        debugPrint('💾 Marking $language as downloaded in cache');
        _downloadedModels['en_$language'] = true;
        
        debugPrint('🎉 Successfully completed download for $language model');
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ TIMEOUT EXCEPTION: $e');
      debugPrint('⚠️ Model download timed out for $language');
      debugPrint('💡 Try checking your internet connection or waiting a few minutes');
      throw Exception('Download timed out after 3 minutes. The model may be too large or your connection is slow. Please try again later.');
    } catch (e) {
      debugPrint('❌ EXCEPTION during download: ${e.runtimeType}');
      debugPrint('❌ Exception message: $e');
      debugPrint('❌ Failed to download $language model: $e');
      rethrow;
    }
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String language) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      await modelManager.deleteModel(language).timeout(Duration(seconds: 30));
      
      // Remove from cache
      _downloadedModels.removeWhere((key, value) => key.contains(language));
      
      debugPrint('🗑️ Deleted $language model');
    } catch (e) {
      debugPrint('⚠️ Failed to delete $language model: $e');
      rethrow;
    }
  }

  /// Close all translators
  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}

/// Translation result model
class TranslationResult {
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final bool success;
  final String? error;

  TranslationResult({
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.success,
    this.error,
  });

  factory TranslationResult.error(String errorMessage) {
    return TranslationResult(
      translatedText: '',
      sourceLang: '',
      targetLang: '',
      success: false,
      error: errorMessage,
    );
  }
}

/// Language information from LibreTranslate
class LanguageInfo {
  final String code;
  final String name;

  LanguageInfo({required this.code, required this.name});

  factory LanguageInfo.fromJson(Map<String, dynamic> json) {
    return LanguageInfo(
      code: json['code'] ?? json['bcpCode'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

/// Translation exception
class TranslationException implements Exception {
  final String message;
  final int statusCode;

  TranslationException(this.message, this.statusCode);

  @override
  String toString() => 'TranslationException: $message (Status: $statusCode)';
}
