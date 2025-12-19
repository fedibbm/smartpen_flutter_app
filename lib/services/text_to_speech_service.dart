import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service supporting English, French, and Arabic
/// Designed for dyslexic readers with customizable speech parameters
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Speech state
  bool _isInitialized = false;
  TtsState _ttsState = TtsState.stopped;
  String _currentLanguage = 'en-US';
  
  // Speech parameters (configurable)
  double _speechRate = 0.5; // Slower for dyslexic readers (0.0 to 1.0)
  double _pitch = 1.0; // Normal pitch (0.5 to 2.0)
  double _volume = 0.8; // Volume (0.0 to 1.0)
  
  // Available languages
  static const Map<String, String> supportedLanguages = {
    'en': 'en-US',
    'fr': 'fr-FR',
    'ar': 'ar-SA',
  };

  // Available voices per language (will be populated dynamically)
  Map<String, List<Map<String, String>>> _availableVoices = {};

  // Getters
  TtsState get ttsState => _ttsState;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  Map<String, List<Map<String, String>>> get availableVoices => _availableVoices;

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up callbacks
      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
        print('🔊 TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.stopped;
        print('✅ TTS completed');
      });

      _flutterTts.setCancelHandler(() {
        _ttsState = TtsState.stopped;
        print('🛑 TTS cancelled');
      });

      _flutterTts.setPauseHandler(() {
        _ttsState = TtsState.paused;
        print('⏸️ TTS paused');
      });

      _flutterTts.setContinueHandler(() {
        _ttsState = TtsState.continued;
        print('▶️ TTS continued');
      });

      _flutterTts.setErrorHandler((msg) {
        _ttsState = TtsState.stopped;
        print('❌ TTS error: $msg');
      });

      // Set initial parameters
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setLanguage(_currentLanguage);

      // Get available voices
      await _loadAvailableVoices();

      _isInitialized = true;
      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Load available voices for all supported languages
  Future<void> _loadAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null && voices is List) {
        _availableVoices.clear();
        
        for (var voice in voices) {
          if (voice is Map) {
            final locale = voice['locale']?.toString() ?? '';
            final name = voice['name']?.toString() ?? '';
            
            // Group by language code
            for (var entry in supportedLanguages.entries) {
              if (locale.startsWith(entry.key)) {
                if (!_availableVoices.containsKey(entry.key)) {
                  _availableVoices[entry.key] = [];
                }
                _availableVoices[entry.key]!.add({
                  'name': name,
                  'locale': locale,
                });
              }
            }
          }
        }
        
        print('📢 Available voices: ${_availableVoices.length} languages');
        for (var entry in _availableVoices.entries) {
          print('  ${entry.key}: ${entry.value.length} voices');
        }
      }
    } catch (e) {
      print('⚠️ Could not load voices: $e');
    }
  }

  /// Speak the given text in the current language
  Future<bool> speak(String text, {String? languageCode}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) {
      print('⚠️ Cannot speak empty text');
      return false;
    }

    try {
      // Stop any ongoing speech
      await stop();

      // Set language if specified
      if (languageCode != null) {
        await setLanguage(languageCode);
      }

      // Speak the text
      await _flutterTts.speak(text);
      print('🔊 Speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      return true;
    } catch (e) {
      print('❌ Speak failed: $e');
      return false;
    }
  }

  /// Pause the current speech
  Future<void> pause() async {
    if (_ttsState == TtsState.playing) {
      await _flutterTts.pause();
      print('⏸️ Speech paused');
    }
  }

  /// Resume paused speech
  Future<void> resume() async {
    if (_ttsState == TtsState.paused) {
      await _flutterTts.speak(''); // Resume by speaking empty (some platforms)
      print('▶️ Speech resumed');
    }
  }

  /// Stop the current speech
  Future<void> stop() async {
    if (_ttsState != TtsState.stopped) {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      print('🛑 Speech stopped');
    }
  }

  /// Set the speech language
  Future<bool> setLanguage(String languageCode) async {
    final locale = supportedLanguages[languageCode];
    if (locale == null) {
      print('⚠️ Unsupported language: $languageCode');
      return false;
    }

    try {
      final result = await _flutterTts.setLanguage(locale);
      if (result == 1) {
        _currentLanguage = locale;
        print('🌍 Language set to: $locale');
        return true;
      } else {
        print('⚠️ Language not available: $locale');
        return false;
      }
    } catch (e) {
      print('❌ Set language failed: $e');
      return false;
    }
  }

  /// Set the speech rate (0.0 to 1.0, default 0.5 for dyslexic readers)
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      print('⚠️ Invalid speech rate: $rate (must be 0.0-1.0)');
      return;
    }

    try {
      await _flutterTts.setSpeechRate(rate);
      _speechRate = rate;
      print('🎚️ Speech rate set to: $rate');
    } catch (e) {
      print('❌ Set speech rate failed: $e');
    }
  }

  /// Set the pitch (0.5 to 2.0, default 1.0)
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0) {
      print('⚠️ Invalid pitch: $pitch (must be 0.5-2.0)');
      return;
    }

    try {
      await _flutterTts.setPitch(pitch);
      _pitch = pitch;
      print('🎵 Pitch set to: $pitch');
    } catch (e) {
      print('❌ Set pitch failed: $e');
    }
  }

  /// Set the volume (0.0 to 1.0, default 0.8)
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      print('⚠️ Invalid volume: $volume (must be 0.0-1.0)');
      return;
    }

    try {
      await _flutterTts.setVolume(volume);
      _volume = volume;
      print('🔊 Volume set to: $volume');
    } catch (e) {
      print('❌ Set volume failed: $e');
    }
  }

  /// Set a specific voice by name (platform-specific)
  Future<bool> setVoice(String voiceName, String locale) async {
    try {
      await _flutterTts.setVoice({"name": voiceName, "locale": locale});
      print('🎤 Voice set to: $voiceName ($locale)');
      return true;
    } catch (e) {
      print('❌ Set voice failed: $e');
      return false;
    }
  }

  /// Check if a language is available
  Future<bool> isLanguageAvailable(String languageCode) async {
    final locale = supportedLanguages[languageCode];
    if (locale == null) return false;

    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        return languages.contains(locale);
      }
      return false;
    } catch (e) {
      print('❌ Check language availability failed: $e');
      return false;
    }
  }

  /// Get available languages on this device
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List) {
        return languages.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get available languages failed: $e');
      return [];
    }
  }

  /// Dispose of resources
  void dispose() {
    stop();
    _isInitialized = false;
    print('🗑️ TTS service disposed');
  }
}

/// TTS state enum
enum TtsState {
  playing,
  stopped,
  paused,
  continued,
}
