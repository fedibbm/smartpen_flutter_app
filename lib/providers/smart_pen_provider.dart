import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as mlkit;
import '../models/smart_pen_models.dart';
import '../services/ocr_backend_service.dart';
import '../services/esp32_camera_service.dart';
import '../services/phone_camera_service.dart';
import '../services/image_stitching_service.dart';
import '../services/hybrid_translation_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/mlkit_text_recognition_service.dart';
import '../providers/notification_provider.dart';
import '../config/device_config.dart';
import '../config/network_config.dart';
import '../utils/mock_image_generator.dart';
import '../utils/spell_corrector.dart';
import '../utils/text_overlap_detector.dart';

/// Camera mode for capturing text
enum CameraMode {
  esp32, // ESP32-CAM smart pen
  phoneCamera, // Device camera
  dummy, // Mock data for testing
}

class SmartPenProvider extends ChangeNotifier {
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  RecognitionStatus _recognitionStatus = RecognitionStatus.idle;
  SmartPenDevice? _connectedDevice;
  final List<SmartPenDevice> _availableDevices = [];
  final List<PenStroke> _strokes = [];
  final List<RecognizedText> _recognizedTexts = [];
  Timer? _mockDataTimer;
  Timer? _connectionTimer;
  Timer? _recognitionTimer;
  
  // External services
  late final OcrBackendService _ocrService;
  late final Esp32CameraService _esp32Service;
  late final PhoneCameraService _phoneCameraService;
  late final ImageStitchingService _stitchingService;
  late final HybridTranslationService _translationService;
  late final TextToSpeechService _ttsService;
  late final MLKitTextRecognitionService _mlKitService;
  bool _useRealOcr = DeviceConfig.enableOcrBackend;
  bool _ocrServerConnected = false;
  bool _textProcessingEnabled = DeviceConfig.enableTextProcessing;
  bool _onlineTranslationAvailable = false;
  bool _onlineDictionaryAvailable = false;
  
  // OCR mode: 'mlkit' (default, on-device) or 'backend' (Python server)
  String _ocrMode = 'mlkit';
  
  // Camera mode state
  CameraMode _cameraMode = CameraMode.esp32; // Default to ESP32
  bool _esp32Connected = false;
  bool _phoneCameraInitialized = false;
  String? _cameraError;
  String _scanStatus = ''; // Status message during network scanning
  
  // TTS state
  TtsState _ttsState = TtsState.stopped;
  bool _ttsEnabled = true; // TTS feature enabled by default
  bool _ttsAutoPlay = false; // Auto-play new text (disabled by default)
  String _ttsLanguage = 'en'; // Default language
  double _ttsSpeechRate = 0.5; // Slower for dyslexic readers
  double _ttsPitch = 1.0;
  double _ttsVolume = 0.8;
  
  // Scanning state
  bool _isScanning = false;
  final List<Offset> _currentScanStrokes = [];

  // Getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  RecognitionStatus get recognitionStatus => _recognitionStatus;
  SmartPenDevice? get connectedDevice => _connectedDevice;
  List<SmartPenDevice> get availableDevices => List.unmodifiable(_availableDevices);
  List<PenStroke> get strokes => List.unmodifiable(_strokes);
  List<RecognizedText> get recognizedTexts => List.unmodifiable(_recognizedTexts);
  bool get isUsingRealOcr => _useRealOcr && _ocrServerConnected;
  bool get isOcrServerConnected => _ocrServerConnected;
  String get ocrMode => _ocrMode;
  bool get isScanning => _isScanning;
  bool get isOnlineTranslationAvailable => _onlineTranslationAvailable;
  bool get isOnlineDictionaryAvailable => _onlineDictionaryAvailable;
  HybridTranslationService get translationService => _translationService;
  TextToSpeechService get ttsService => _ttsService;
  MLKitTextRecognitionService get mlKitService => _mlKitService;
  
  // TTS getters
  TtsState get ttsState => _ttsState;
  bool get ttsEnabled => _ttsEnabled;
  bool get ttsAutoPlay => _ttsAutoPlay;
  String get ttsLanguage => _ttsLanguage;
  double get ttsSpeechRate => _ttsSpeechRate;
  double get ttsPitch => _ttsPitch;
  double get ttsVolume => _ttsVolume;
  
  // Camera mode getters
  CameraMode get cameraMode => _cameraMode;
  bool get esp32Connected => _esp32Connected;
  bool get phoneCameraInitialized => _phoneCameraInitialized;
  String? get cameraError => _cameraError;
  String get scanStatus => _scanStatus;
  PhoneCameraService get phoneCameraService => _phoneCameraService;

  NotificationProvider? notificationProvider;

  SmartPenProvider({this.notificationProvider}) {
    _ocrService = OcrBackendService();
    _esp32Service = Esp32CameraService();
    _phoneCameraService = PhoneCameraService();
    _stitchingService = ImageStitchingService();
    _translationService = HybridTranslationService();
    _ttsService = TextToSpeechService();
    _mlKitService = MLKitTextRecognitionService();
    _initializeMockDevices();
    _checkOcrServerHealth();
    _checkOnlineServices();
    _preDownloadTranslationModels(); // Pre-download models on startup
    _initializeTts(); // Initialize TTS on startup
  }

  void _initializeMockDevices() {
    _availableDevices.addAll([
      SmartPenDevice(
        id: 'pen_001',
        name: 'DyslexiPen Pro WiFi',
        type: ConnectionType.wifi,
        batteryLevel: 85,
        signalStrength: 0.8,
      ),
      SmartPenDevice(
        id: 'pen_002',
        name: 'TextReader Bluetooth',
        type: ConnectionType.bluetooth,
        batteryLevel: 92,
        signalStrength: 0.7,
      ),
      SmartPenDevice(
        id: 'pen_003',
        name: 'AccessiPen Ultra',
        type: ConnectionType.wifi,
        batteryLevel: 67,
        signalStrength: 0.9,
      ),
    ]);
  }

  /// Check if OCR backend server is available
  Future<void> _checkOcrServerHealth() async {
    if (!DeviceConfig.enableOcrBackend) {
      _ocrServerConnected = false;
      return;
    }

    try {
      _ocrServerConnected = await _ocrService.checkHealth();
      if (_ocrServerConnected) {
        debugPrint('✅ OCR Backend server is connected and healthy');
      } else {
        debugPrint('⚠️ OCR Backend server health check failed, using mock mode');
      }
    } catch (e) {
      debugPrint('❌ OCR Backend server connection failed: $e');
      _ocrServerConnected = false;
    }
    notifyListeners();
  }

  /// Check availability of online translation and dictionary services
  Future<void> _checkOnlineServices() async {
    try {
      await _translationService.checkOnlineServices();
      _onlineTranslationAvailable = _translationService.isOnlineTranslationAvailable;
      _onlineDictionaryAvailable = _translationService.isOnlineDictionaryAvailable;
      
      if (_onlineTranslationAvailable) {
        debugPrint('✅ On-device translation (Google ML Kit) is available');
      } else {
        debugPrint('📴 ML Kit translation offline, using local dictionaries');
      }
      
      if (_onlineDictionaryAvailable) {
        debugPrint('✅ Online dictionary is available');
      } else {
        debugPrint('📴 Online dictionary offline, using basic definitions');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to check online services: $e');
      _onlineTranslationAvailable = false;
      _onlineDictionaryAvailable = false;
    }
    notifyListeners();
  }

  /// Pre-download translation models for French and Arabic on app startup
  Future<void> _preDownloadTranslationModels() async {
    try {
      debugPrint('📦 Pre-downloading translation models...');
      await _translationService.preDownloadModels(['fr', 'ar']);
      debugPrint('✅ Translation models ready');
    } catch (e) {
      debugPrint('⚠️ Failed to pre-download models: $e');
    }
  }

  /// Retry checking online services
  Future<void> retryOnlineServices() async {
    await _checkOnlineServices();
  }

  /// Process image with real OCR backend or fallback to mock
  Future<RecognizedText> processImageWithOcr(Uint8List imageBytes) async {
    if (_useRealOcr && _ocrServerConnected) {
      try {
        // Step 1: Extract text from image via OCR
        final ocrResponse = await _ocrService.extractTextWithRetry(imageBytes);
        String extractedText = ocrResponse.extractedText;
        
        // Step 2: Apply built-in spell correction if enabled
        if (_textProcessingEnabled && extractedText.isNotEmpty) {
          final corrections = SpellCorrector.getCorrections(extractedText);
          if (corrections.isNotEmpty) {
            extractedText = SpellCorrector.correctText(extractedText);
            
            debugPrint('📝 Text corrected: ${corrections.length} changes');
            for (final correction in corrections) {
              debugPrint('  - "${correction.original}" → "${correction.corrected}" (${correction.type})');
            }
          }
        }
        
        // Convert to RecognizedText with corrected text
        return ocrResponse.toRecognizedTextWithCorrected(extractedText);
      } catch (e) {
        debugPrint('OCR processing failed: $e, falling back to mock');
        // Fallback to mock if OCR fails
        return _generateMockRecognizedText();
      }
    } else {
      // Use mock data when OCR is disabled or not connected
      return _generateMockRecognizedText();
    }
  }

  /// Toggle between real OCR and mock mode
  void toggleOcrMode() {
    _useRealOcr = !_useRealOcr;
    debugPrint('OCR mode: ${_useRealOcr ? "Real" : "Mock"}');
    notifyListeners();
  }
  
  /// Switch OCR processing mode
  void setOcrMode(String mode) {
    if (mode != 'mlkit' && mode != 'backend') {
      debugPrint('⚠️ Invalid OCR mode: $mode, using mlkit');
      mode = 'mlkit';
    }
    _ocrMode = mode;
    debugPrint('🔄 OCR mode set to: $_ocrMode');
    notifyListeners();
  }

  /// Manually retry OCR server connection
  Future<void> retryOcrConnection() async {
    await _checkOcrServerHealth();
  }

  /// Manual test: Send a mock image to OCR server
  Future<void> testOcrWithMockImage() async {
    debugPrint('🧪 Testing OCR with mock image...');
    
    try {
      // Generate a placeholder mock image
      final mockImage = await MockImageGenerator.generatePlaceholder();
      debugPrint('✅ Mock image generated: ${mockImage.length} bytes');
      
      // Send to OCR server
      _processTextRecognitionWithImage(mockImage);
    } catch (e) {
      debugPrint('❌ OCR test failed: $e');
      _recognitionStatus = RecognitionStatus.error;
      notifyListeners();
      
      Timer(const Duration(seconds: 2), () {
        _recognitionStatus = RecognitionStatus.idle;
        notifyListeners();
      });
    }
  }

  Future<void> connectToDevice(SmartPenDevice device) async {
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    // Simulate connection delay
    _connectionTimer = Timer(const Duration(seconds: 2), () {
      final random = Random();
      if (random.nextDouble() > 0.1) { // 90% success rate
        _connectionStatus = ConnectionStatus.connected;
        _connectedDevice = device;
        // Don't auto-start scanning anymore
      } else {
        _connectionStatus = ConnectionStatus.error;
      }
      notifyListeners();
    });
  }

  void disconnect() {
    _connectionStatus = ConnectionStatus.disconnected;
    _connectedDevice = null;
    stopScanning(); // Stop scanning if active
    notifyListeners();
  }

  /// Start scanning/capturing handwriting strokes
  void startScanning() {
    if (_isScanning) return;
    
    _isScanning = true;
    _currentScanStrokes.clear();
    _strokes.clear();
    
    debugPrint('📝 Started scanning...');
    
    // Start generating mock strokes periodically
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isScanning) {
        _generateMockStroke();
      }
    });
    
    notifyListeners();
  }

  /// Stop scanning and send collected strokes to OCR
  Future<void> stopScanning() async {
    if (!_isScanning) return;
    
    _isScanning = false;
    _mockDataTimer?.cancel();
    _mockDataTimer = null;
    
    debugPrint('🛑 Stopped scanning. Processing ${_currentScanStrokes.length} stroke points...');
    
    notifyListeners();
    
    // Generate image from collected strokes and send to OCR
    if (_currentScanStrokes.isNotEmpty) {
      try {
        final mockImage = await MockImageGenerator.generateFromStrokes(_currentScanStrokes);
        debugPrint('✅ Generated image from strokes: ${mockImage.length} bytes');
        _processTextRecognitionWithImage(mockImage);
      } catch (e) {
        debugPrint('❌ Failed to process scanned strokes: $e');
      }
    } else {
      debugPrint('⚠️ No strokes captured during scan');
    }
    
    _currentScanStrokes.clear();
  }

  /// Generate a single mock stroke point
  void _generateMockStroke() {
    final random = Random();
    
    // Add points to simulate continuous writing
    if (_currentScanStrokes.isEmpty) {
      // Start point
      final startX = random.nextDouble() * 200 + 100;
      final startY = random.nextDouble() * 150 + 75;
      _currentScanStrokes.add(Offset(startX, startY));
    } else {
      // Continue from last point with slight variation
      final lastPoint = _currentScanStrokes.last;
      final x = lastPoint.dx + random.nextDouble() * 20 - 5;
      final y = lastPoint.dy + sin(_currentScanStrokes.length * 0.2) * 8 + random.nextDouble() * 4 - 2;
      _currentScanStrokes.add(Offset(x, y));
    }
    
    // Add to visual strokes for display
    if (_strokes.isEmpty || _strokes.last.points.length > 20) {
      _strokes.add(PenStroke(
        points: [_currentScanStrokes.last],
        timestamp: DateTime.now(),
      ));
    } else {
      final updatedPoints = [..._strokes.last.points, _currentScanStrokes.last];
      _strokes[_strokes.length - 1] = PenStroke(
        points: updatedPoints,
        timestamp: _strokes.last.timestamp,
      );
    }
    
    notifyListeners();
  }

  // Remove old _generateMockWriting method - replaced by startScanning/stopScanning

  /// Process text recognition with actual image data sent to OCR server
  void _processTextRecognitionWithImage(Uint8List imageBytes) async {
    _recognitionStatus = RecognitionStatus.processing;
    notifyListeners();

    try {
      // Send image to OCR backend and get text
      final recognizedText = await processImageWithOcr(imageBytes);
      
      _recognizedTexts.insert(0, recognizedText);
      
      // Limit to last 10 texts
      if (_recognizedTexts.length > 10) {
        _recognizedTexts.removeLast();
      }
      
      _recognitionStatus = RecognitionStatus.completed;
      notifyListeners();

      // Reset status after a delay
      Timer(const Duration(seconds: 1), () {
        _recognitionStatus = RecognitionStatus.idle;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Text recognition failed: $e');
      _recognitionStatus = RecognitionStatus.error;
      notifyListeners();
      
      Timer(const Duration(seconds: 2), () {
        _recognitionStatus = RecognitionStatus.idle;
        notifyListeners();
      });
    }
  }
  /// Generate mock recognized text (used as fallback when OCR not available)
  Future<RecognizedText> _generateMockRecognizedText() async {
    final random = Random();
    
    // Mock complex texts for dyslexic users
    final mockTexts = [
      {
        'original': 'The phenomenon of photosynthesis is fundamental to life on Earth.',
        'simplified': 'Plants use sunlight to make food. This helps all life on Earth.',
        'keywords': ['photosynthesis', 'fundamental', 'phenomenon'],
        'definitions': [
          'Photosynthesis: How plants make food from sunlight',
          'Fundamental: Very important or basic',
          'Phenomenon: Something that happens in nature'
        ]
      },
      {
        'original': 'Democracy requires active participation from citizens.',
        'simplified': 'People need to take part in their government.',
        'keywords': ['democracy', 'participation', 'citizens'],
        'definitions': [
          'Democracy: Government by the people',
          'Participation: Taking part in something',
          'Citizens: People who belong to a country'
        ]
      },
      {
        'original': 'The mitochondria is responsible for cellular respiration.',
        'simplified': 'Cell parts help make energy for the body.',
        'keywords': ['mitochondria', 'cellular', 'respiration'],
        'definitions': [
          'Mitochondria: Parts of cells that make energy',
          'Cellular: Related to cells',
          'Respiration: How cells use oxygen to make energy'
        ]
      },
      {
        'original': 'Sustainable development balances economic growth with environmental protection.',
        'simplified': 'Growing the economy while keeping nature safe.',
        'keywords': ['sustainable', 'development', 'environmental'],
        'definitions': [
          'Sustainable: Can keep going without harm',
          'Development: Growth and improvement',
          'Environmental: Related to nature and surroundings'
        ]
      },
    ];

    final selectedText = mockTexts[random.nextInt(mockTexts.length)];
    
    final recognizedText = RecognizedText(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: selectedText['original'] as String,
      simplifiedText: selectedText['simplified'] as String,
      keyWords: selectedText['keywords'] as List<String>,
      complexity: _calculateComplexity(selectedText['original'] as String),
      confidence: 0.85 + random.nextDouble() * 0.14, // 85-99% confidence
      timestamp: DateTime.now(),
      definitions: selectedText['definitions'] as List<String>,
      language: 'en', // or detect if needed
    );
    
    // Auto-play if enabled
    _autoPlayTextIfEnabled(recognizedText.originalText, _ttsLanguage);
    
    return recognizedText;
  }

  TextComplexity _calculateComplexity(String text) {
    final words = text.split(' ');
    final avgWordLength = words.fold<int>(0, (sum, word) => sum + word.length) / words.length;
    
    if (avgWordLength < 5) return TextComplexity.simple;
    if (avgWordLength < 7) return TextComplexity.medium;
    return TextComplexity.complex;
  }

  void clearCanvas() {
    _strokes.clear();
    _currentScanStrokes.clear();
    notifyListeners();
  }

  void clearRecognizedTexts() {
    _recognizedTexts.clear();
    notifyListeners();
  }

  void deleteRecognizedText(String id) {
    _recognizedTexts.removeWhere((text) => text.id == id);
    notifyListeners();
  }

  // ==================== Text-to-Speech Methods ====================

  /// Initialize TTS service
  Future<void> _initializeTts() async {
    try {
      await _ttsService.initialize();
      
      // Set initial parameters
      await _ttsService.setSpeechRate(_ttsSpeechRate);
      await _ttsService.setPitch(_ttsPitch);
      await _ttsService.setVolume(_ttsVolume);
      await _ttsService.setLanguage(_ttsLanguage);
      
      // Update state based on service callbacks
      _updateTtsStateFromService();
      
      debugPrint('✅ TTS service initialized');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
    }
  }

  /// Update TTS state from service
  void _updateTtsStateFromService() {
    _ttsState = _ttsService.ttsState;
    notifyListeners();
  }

  /// Speak the given text
  Future<bool> speakText(String text, {String? languageCode}) async {
    if (!_ttsEnabled) {
      debugPrint('⚠️ TTS is disabled');
      return false;
    }

    final success = await _ttsService.speak(
      text,
      languageCode: languageCode ?? _ttsLanguage,
    );
    
    _updateTtsStateFromService();
    return success;
  }

  /// Pause current speech
  Future<void> pauseSpeech() async {
    await _ttsService.pause();
    _updateTtsStateFromService();
  }

  /// Resume paused speech
  Future<void> resumeSpeech() async {
    await _ttsService.resume();
    _updateTtsStateFromService();
  }

  /// Stop current speech
  Future<void> stopSpeech() async {
    await _ttsService.stop();
    _updateTtsStateFromService();
  }

  /// Toggle TTS enabled state
  void toggleTtsEnabled() {
    _ttsEnabled = !_ttsEnabled;
    if (!_ttsEnabled) {
      stopSpeech(); // Stop any ongoing speech
    }
    notifyListeners();
  }

  /// Toggle TTS auto-play (secretly also toggles mock mode)
  void toggleTtsAutoPlay() {
    _ttsAutoPlay = !_ttsAutoPlay;
    
    // Secret: Auto-play on = Mock mode on
    if (_ttsAutoPlay) {
      _cameraMode = CameraMode.dummy;
    } else {
      // When auto-play is off, switch to ESP32 if not using phone camera
      if (_cameraMode == CameraMode.dummy) {
        _cameraMode = CameraMode.esp32;
      }
    }
    
    notifyListeners();
  }

  /// Set TTS language
  Future<void> setTtsLanguage(String languageCode) async {
    final success = await _ttsService.setLanguage(languageCode);
    if (success) {
      _ttsLanguage = languageCode;
      notifyListeners();
    }
  }

  /// Set TTS speech rate
  Future<void> setTtsSpeechRate(double rate) async {
    await _ttsService.setSpeechRate(rate);
    _ttsSpeechRate = rate;
    notifyListeners();
  }

  /// Set TTS pitch
  Future<void> setTtsPitch(double pitch) async {
    await _ttsService.setPitch(pitch);
    _ttsPitch = pitch;
    notifyListeners();
  }

  /// Set TTS volume
  Future<void> setTtsVolume(double volume) async {
    await _ttsService.setVolume(volume);
    _ttsVolume = volume;
    notifyListeners();
  }

  /// Check if a language is available
  Future<bool> isTtsLanguageAvailable(String languageCode) async {
    return await _ttsService.isLanguageAvailable(languageCode);
  }

  /// Auto-play text if enabled (called after recognition)
  void _autoPlayTextIfEnabled(String text, String languageCode) {
    if (_ttsEnabled && _ttsAutoPlay && text.isNotEmpty) {
      debugPrint('🔊 Auto-playing recognized text');
      speakText(text, languageCode: languageCode);
    }
  }

  void scanForDevices() {
    // Simulate device scanning by updating signal strength
    final random = Random();
    for (int i = 0; i < _availableDevices.length; i++) {
      _availableDevices[i] = _availableDevices[i].copyWith(
        signalStrength: random.nextDouble(),
        batteryLevel: random.nextInt(40) + 60, // 60-100%
      );
    }
    notifyListeners();
  }

  // ============================================================================
  // CAMERA MODE MANAGEMENT
  // ============================================================================

  /// Set camera mode (ESP32, phone camera, or dummy)
  Future<void> setCameraMode(CameraMode mode) async {
    if (_cameraMode == mode) return;

    final oldMode = _cameraMode;
    _cameraMode = mode;
    _cameraError = null;
    notifyListeners();

    debugPrint('📷 Camera mode changed: $oldMode → $mode');

    // Initialize phone camera if switching to it
    if (mode == CameraMode.phoneCamera && !_phoneCameraInitialized) {
      await initializePhoneCamera();
    }

    // Check ESP32 connection if switching to it
    if (mode == CameraMode.esp32) {
      await checkEsp32Connection();
    }
  }

  /// Initialize phone camera
  Future<bool> initializePhoneCamera() async {
    try {
      _cameraError = null;
      notifyListeners();

      final success = await _phoneCameraService.initialize();
      _phoneCameraInitialized = success;

      if (!success) {
        _cameraError = 'Failed to initialize phone camera';
      }

      notifyListeners();
      debugPrint(_phoneCameraInitialized 
          ? '✅ Phone camera initialized' 
          : '❌ Phone camera initialization failed');
      
      return success;
    } catch (e) {
      _cameraError = 'Camera error: $e';
      _phoneCameraInitialized = false;
      notifyListeners();
      debugPrint('❌ Phone camera error: $e');
      return false;
    }
  }

  /// Check ESP32 connection status
  Future<void> checkEsp32Connection({bool performNetworkScan = false}) async {
    try {
      _cameraError = null;
      if (performNetworkScan) {
        _scanStatus = 'Searching for ESP32-CAM...';
        notifyListeners();
      }
      
      // Try to connect to ESP32 stream
      final connected = await _esp32Service.testConnection(
        performNetworkScan: performNetworkScan,
        onScanProgress: performNetworkScan ? (message) {
          _scanStatus = message;
          notifyListeners();
        } : null,
        onScanStep: performNetworkScan ? (current, total) {
          _scanStatus = 'Scanning network: $current/$total devices checked';
          notifyListeners();
        } : null,
      );
      
      _esp32Connected = connected;

      if (connected) {
        _scanStatus = performNetworkScan 
            ? 'ESP32-CAM connected at ${_esp32Service.currentIp}'
            : '';
      } else if (_cameraMode == CameraMode.esp32) {
        _cameraError = performNetworkScan
            ? 'ESP32-CAM not found on network. Please check the device or switch to phone camera mode.'
            : 'ESP32-CAM not connected at ${NetworkConfig.esp32CamHost}. Try network scan or switch to phone camera mode.';
        _scanStatus = '';
      }

      notifyListeners();
      debugPrint(_esp32Connected 
          ? '✅ ESP32-CAM connected at ${_esp32Service.currentIp}' 
          : '⚠️ ESP32-CAM not connected');
    } catch (e) {
      _esp32Connected = false;
      if (_cameraMode == CameraMode.esp32) {
        _cameraError = 'Cannot reach ESP32-CAM: $e';
      }
      _scanStatus = '';
      notifyListeners();
      debugPrint('❌ ESP32 connection check failed: $e');
    }
  }

  /// Clear camera error
  void clearCameraError() {
    _cameraError = null;
    notifyListeners();
  }

  /// Start scanning with current camera mode
  Future<void> startScanWithCurrentMode() async {
    if (_isScanning) return;

    _cameraError = null;
    
    switch (_cameraMode) {
      case CameraMode.esp32:
        if (!_esp32Connected) {
          _cameraError = 'ESP32-CAM not connected. Please connect the device or switch to phone camera mode.';
          notifyListeners();
          return;
        }
        await _startEsp32Scan();
        break;
        
      case CameraMode.phoneCamera:
        if (!_phoneCameraInitialized) {
          final success = await initializePhoneCamera();
          if (!success) {
            _cameraError = 'Failed to initialize phone camera';
            notifyListeners();
            return;
          }
        }
        await _startPhoneCameraScan();
        break;
        
      case CameraMode.dummy:
        _startDummyScan();
        break;
    }
  }

  /// Start ESP32-CAM scan
  Future<void> _startEsp32Scan() async {
    _isScanning = true;
    _recognitionStatus = RecognitionStatus.processing;
    notifyListeners();

    try {
      debugPrint('📸 Starting ESP32-CAM scan...');
      
      // Capture frames from ESP32 stream (5 frames over 1 second)
      final frames = await _esp32Service.captureFrameSequence(
        frameCount: 5,
        interval: const Duration(milliseconds: 200),
      );

      if (frames.isEmpty) {
        throw Exception('No frames captured from ESP32');
      }

      debugPrint('✅ Captured ${frames.length} frames from ESP32');
      
      // Process frames using unified ML Kit pipeline (same as phone camera)
      await processFramesWithMLKit(frames, source: 'ESP32-CAM');
      
    } catch (e) {
      debugPrint('❌ ESP32 scan failed: $e');
      _cameraError = 'ESP32 scan failed: $e';
      _recognitionStatus = RecognitionStatus.error;
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Start phone camera scan
  /// Note: This should be called after frames are captured from UI
  Future<void> _startPhoneCameraScan() async {
    // Phone camera mode requires UI interaction
    // The actual scanning is handled by PhoneCameraScreen
    // This method will be called after frames are returned from the screen
    debugPrint('📱 Phone camera mode - open camera screen first');
    _cameraError = 'Please use the camera screen to capture frames';
    notifyListeners();
  }

  /// Process a single camera frame with ML Kit (real-time)
  Future<void> processCameraFrame(CameraImage image, int rotation) async {
    if (_ocrMode != 'mlkit') return;
    
    try {
      final result = await _mlKitService.processImage(image, rotation);
      
      if (result.wasThrottled) {
        // Frame was throttled, skip silently
        return;
      }
      
      if (!result.success) {
        debugPrint('ML Kit error: ${result.error}');
        return;
      }
      
      // Process unique text blocks
      if (result.uniqueCount > 0) {
        final combinedText = result.combinedText;
        
        // Apply spell correction if enabled
        String processedText = combinedText;
        if (_textProcessingEnabled && combinedText.isNotEmpty) {
          final corrections = SpellCorrector.getCorrections(combinedText);
          if (corrections.isNotEmpty) {
            processedText = SpellCorrector.correctText(combinedText);
            debugPrint('📝 Text corrected: ${corrections.length} changes');
          }
        }
        
        // Add recognized text
        _addRecognizedText(
          processedText,
          'en', // TODO: Add language detection
          confidence: 0.95,
        );
        
        debugPrint('✅ ML Kit: ${result.summary}');
      }
    } catch (e) {
      debugPrint('❌ ML Kit processing error: $e');
    }
  }

  /// Process frames captured from phone camera
  Future<void> processPhoneCameraFrames(List<Uint8List> frames) async {
    // Delegate to unified processing pipeline
    await processFramesWithMLKit(frames, source: 'Phone Camera');
  }

  /// Unified frame processing with ML Kit + overlap detection
  /// Used by both phone camera and ESP32 modes for consistent results
  Future<void> processFramesWithMLKit(List<Uint8List> frames, {String source = 'Camera'}) async {
    _isScanning = true;
    _recognitionStatus = RecognitionStatus.processing;
    _cameraError = null;
    notifyListeners();

    try {
      debugPrint('📱 Processing ${frames.length} frames from $source with ML Kit...');

      if (frames.isEmpty) {
        throw Exception('No frames provided');
      }

      final List<String> frameTexts = [];

      // Process each frame with ML Kit
      for (int i = 0; i < frames.length; i++) {
        try {
          // Create InputImage from bytes
          final inputImage = mlkit.InputImage.fromBytes(
            bytes: frames[i],
            metadata: mlkit.InputImageMetadata(
              size: Size(640, 480), // Approximate, ML Kit handles various sizes
              rotation: mlkit.InputImageRotation.rotation0deg,
              format: mlkit.InputImageFormat.yuv420,
              bytesPerRow: 640,
            ),
          );

          // Process with ML Kit
          final result = await _mlKitService.processStaticImage(inputImage);

          // Collect text from this frame (combine all blocks)
          if (result.success && result.blocks.isNotEmpty) {
            final frameText = result.blocks
                .map((block) => block.text.trim())
                .where((text) => text.isNotEmpty)
                .join(' ');

            if (frameText.isNotEmpty) {
              frameTexts.add(frameText);
              debugPrint('   Frame ${i + 1}: ${result.blocks.length} blocks');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing frame ${i + 1}: $e');
          // Continue with other frames
        }
      }

      if (frameTexts.isEmpty) {
        throw Exception('No text detected in any frame');
      }

      // Merge frame texts with overlap detection
      debugPrint('🔍 Detecting and removing overlaps between ${frameTexts.length} frames...');
      final mergedText = TextOverlapDetector.mergeTexts(frameTexts, similarityThreshold: 0.75);

      // Add to recognized texts
      _addRecognizedText(
        mergedText,
        'en',
        confidence: 0.85, // ML Kit confidence
      );

      _recognitionStatus = RecognitionStatus.completed;
      debugPrint('✅ Processing complete: Merged ${frameTexts.length} frames');
      debugPrint('   Original length: ${frameTexts.map((t) => t.length).reduce((a, b) => a + b)} chars');
      debugPrint('   Merged length: ${mergedText.length} chars');
    } catch (e) {
      debugPrint('❌ Frame processing failed: $e');

      _cameraError = e.toString().contains('No text detected')
          ? 'No text detected in frames. Try scanning clearer text.'
          : 'Processing failed: $e';

      _recognitionStatus = RecognitionStatus.error;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Start dummy scan (mock data)
  void _startDummyScan() {
    _isScanning = true;
    _recognitionStatus = RecognitionStatus.processing;
    notifyListeners();

    debugPrint('🎭 Starting dummy scan...');
    
    // Simulate processing delay
    Future.delayed(const Duration(seconds: 2), () {
      _isScanning = false;
      _recognitionStatus = RecognitionStatus.completed;

      // Generate mock text
      final mockTexts = [
        'The quick brown fox jumps over the lazy dog.', // en
        'Flutter is an open source framework by Google.', // en
        'Accessibility features help everyone use technology.', // en
        'La technologie rend le monde plus accessible.', // fr
        'Les livres sont une porte vers de nouveaux mondes.', // fr
        'Chaque jour apporte de nouvelles opportunités.', // fr
        'التكنولوجيا تجعل العالم أكثر سهولة.', // ar
        'الكتب هي بوابة إلى عوالم جديدة.', // ar
        'كل يوم يجلب فرصا جديدة.', // ar
        'كان الجوّ هادئًا، والناسُ يسيرون ببطءٍ في الشارع', // ar
      ];
      final random = Random();
      final mockText = mockTexts[random.nextInt(mockTexts.length)];

      // Detect language based on content
      String language;
      if (mockText.contains(RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]'))) {
        language = 'ar';
      } else if (mockText.contains(RegExp(r'^[A-Za-z]'))) {
        // crude: if it starts with a Latin letter, check for French keywords
        if (mockText.contains('La technologie') ||
            mockText.contains('Les livres') ||
            mockText.contains('Chaque jour')) {
          language = 'fr';
        } else {
          language = 'en';
        }
      } else if (mockText.contains('La technologie') ||
                 mockText.contains('Les livres') ||
                 mockText.contains('Chaque jour')) {
        language = 'fr';
      } else {
        // fallback: check for Arabic characters
        if (mockText.contains(RegExp(r'[\u0600-\u06FF]'))) {
          language = 'ar';
        } else {
          language = 'en';
        }
      }

      _addRecognizedText(mockText, language, confidence: 0.95);
      notifyListeners();
    });
  }

  /// Process stitched image with OCR
  Future<void> _processStitchedImage(Uint8List imageBytes) async {
    try {
      debugPrint('🔍 Processing stitched image (${imageBytes.length} bytes)');
      
      // Send to OCR API
      final ocrResult = await _ocrService.processImage(imageBytes);
      
      if (ocrResult.extractedText.isEmpty) {
        throw Exception('No text recognized in image');
      }

      // Add to recognized texts (assume English for now)
      _addRecognizedText(
        ocrResult.extractedText,
        'en',
        confidence: ocrResult.confidence,
      );
      
      _recognitionStatus = RecognitionStatus.completed;
      debugPrint('✅ OCR completed: "${ocrResult.extractedText}"');
    } catch (e) {
      debugPrint('❌ OCR processing failed: $e');
      throw Exception('OCR failed: $e');
    }
  }

  /// Add recognized text to history
  void addRecognizedText(String text, String language, {double confidence = 1.0}) {
    _addRecognizedText(text, language, confidence: confidence);
  }
  
  /// Add recognized text to history (internal)
  void _addRecognizedText(String text, String language, {double confidence = 1.0}) {
    final recognizedText = RecognizedText(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalText: text,
      simplifiedText: text, // TODO: Add text simplification
      keyWords: [], // TODO: Extract keywords
      complexity: TextComplexity.simple,
      confidence: confidence,
      timestamp: DateTime.now(),
      definitions: [], // TODO: Add word definitions
      language: language,
    );

    _recognizedTexts.insert(0, recognizedText);
    notifyListeners();

    // Auto-play if enabled
    _autoPlayTextIfEnabled(text, language);

    // Fire notification for scan completion
    notificationProvider?.onScanComplete(text);
  }

  @override
  void dispose() {
    _mockDataTimer?.cancel();
    _connectionTimer?.cancel();
    _recognitionTimer?.cancel();
    _ocrService.dispose();
    _esp32Service.dispose();
    _phoneCameraService.dispose();
    _translationService.dispose();
    _ttsService.dispose();
    _mlKitService.dispose();
    super.dispose();
  }
}
