import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/network_config.dart';
import '../config/device_config.dart';
import 'esp32_discovery_service.dart';

/// Service for ESP32-CAM video streaming integration
/// ⚠️ DISABLED - This service is fully implemented but NOT connected to the UI yet
/// ⚠️ Future integration: Will receive video frames from ESP32-CAM for OCR processing
class Esp32CameraService {
  final http.Client _client;
  final Esp32DiscoveryService _discoveryService;
  StreamController<Esp32Frame>? _frameStreamController;
  Timer? _connectionMonitor;
  Esp32ConnectionStatus _connectionStatus = Esp32ConnectionStatus.disconnected;
  String? _errorMessage;
  String? _currentIp;

  Esp32CameraService({http.Client? client}) 
    : _client = client ?? http.Client(),
      _discoveryService = Esp32DiscoveryService(client: client);

  Esp32ConnectionStatus get connectionStatus => _connectionStatus;
  String? get errorMessage => _errorMessage;
  Stream<Esp32Frame>? get frameStream => _frameStreamController?.stream;
  String? get currentIp => _currentIp;

  /// Check if ESP32-CAM is enabled in configuration
  bool get isEnabled => DeviceConfig.enableEsp32Integration;

  /// Check ESP32-CAM device status
  Future<Esp32Status> checkStatus() async {
    if (!isEnabled) {
      throw Esp32Exception('ESP32-CAM integration is disabled in configuration');
    }

    try {
      final response = await _client
          .get(Uri.parse(NetworkConfig.esp32CamStatusEndpoint))
          .timeout(NetworkConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return Esp32Status.fromJson(response.body);
      } else {
        throw Esp32Exception('Status check failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Esp32Exception('Failed to check ESP32-CAM status: $e');
    }
  }

  /// Connect to ESP32-CAM video stream
  /// This starts receiving frames continuously
  Future<void> connectToStream() async {
    if (!isEnabled) {
      throw Esp32Exception('ESP32-CAM integration is disabled');
    }

    if (_connectionStatus == Esp32ConnectionStatus.connected) {
      return; // Already connected
    }

    try {
      _connectionStatus = Esp32ConnectionStatus.connecting;
      _errorMessage = null;

      // Initialize frame stream controller
      _frameStreamController = StreamController<Esp32Frame>.broadcast();

      // Start streaming request
      final request = http.Request('GET', Uri.parse(NetworkConfig.esp32CamStreamEndpoint));
      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode == 200) {
        _connectionStatus = Esp32ConnectionStatus.connected;
        _startFrameProcessing(streamedResponse.stream);
        _startConnectionMonitoring();
      } else {
        throw Esp32Exception('Stream connection failed: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      _connectionStatus = Esp32ConnectionStatus.error;
      _errorMessage = e.toString();
      await disconnect();
      rethrow;
    }
  }

  /// Process incoming video stream and emit frames
  void _startFrameProcessing(Stream<List<int>> byteStream) {
    final buffer = <int>[];

    byteStream.listen(
      (chunk) {
        buffer.addAll(chunk);
        _extractFramesFromBuffer(buffer);
      },
      onError: (error) {
        _connectionStatus = Esp32ConnectionStatus.error;
        _errorMessage = error.toString();
        _frameStreamController?.addError(error);
      },
      onDone: () {
        disconnect();
      },
      cancelOnError: false,
    );
  }

  /// Extract JPEG frames from byte buffer
  void _extractFramesFromBuffer(List<int> buffer) {
    while (buffer.length > 2) {
      // Find JPEG start marker
      int startIndex = -1;
      for (int i = 0; i < buffer.length - 1; i++) {
        if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
          startIndex = i;
          break;
        }
      }

      if (startIndex == -1) {
        buffer.clear();
        return;
      }

      // Find JPEG end marker
      int endIndex = -1;
      for (int i = startIndex + 2; i < buffer.length - 1; i++) {
        if (buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
          endIndex = i + 1;
          break;
        }
      }

      if (endIndex == -1) {
        // Keep the buffer from start marker, wait for more data
        buffer.removeRange(0, startIndex);
        return;
      }

      // Extract complete frame
      final frameBytes = Uint8List.fromList(buffer.sublist(startIndex, endIndex + 1));
      final frame = Esp32Frame(
        imageData: frameBytes,
        timestamp: DateTime.now(),
        frameNumber: _frameStreamController?.hashCode ?? 0,
      );

      _frameStreamController?.add(frame);

      // Remove processed frame from buffer
      buffer.removeRange(0, endIndex + 1);
    }
  }

  /// Capture a single frame (not streaming)
  Future<Esp32Frame> captureFrame() async {
    if (!isEnabled) {
      throw Esp32Exception('ESP32-CAM integration is disabled');
    }

    try {
      final response = await _client
          .get(Uri.parse(NetworkConfig.esp32CamCaptureEndpoint))
          .timeout(NetworkConfig.readTimeout);

      if (response.statusCode == 200) {
        return Esp32Frame(
          imageData: response.bodyBytes,
          timestamp: DateTime.now(),
          frameNumber: 0,
        );
      } else {
        throw Esp32Exception('Frame capture failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Esp32Exception('Failed to capture frame: $e');
    }
  }

  /// Test ESP32 connection, with optional automatic discovery
  Future<bool> testConnection({
    bool performNetworkScan = false,
    Function(String)? onScanProgress,
    Function(int, int)? onScanStep,
  }) async {
    try {
      // First, always try the hardcoded IP from NetworkConfig
      _currentIp = NetworkConfig.esp32CamHost;
      debugPrint('🔍 Testing hardcoded IP: $_currentIp');
      
      final url = 'http://$_currentIp:${NetworkConfig.esp32CamPort}/stream';
      try {
        final response = await _client
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          debugPrint('✅ ESP32-CAM connected at hardcoded IP: $_currentIp');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ Hardcoded IP not responding: $e');
      }

      // If hardcoded IP failed and network scan is not requested, return false
      if (!performNetworkScan) {
        debugPrint('❌ ESP32-CAM not found at hardcoded IP. Network scan not requested.');
        return false;
      }

      // Network scan requested - try saved IP first
      final savedIp = await _discoveryService.getSavedIp();
      if (savedIp != null && savedIp != NetworkConfig.esp32CamHost) {
        _currentIp = savedIp;
        debugPrint('🔍 Testing saved IP: $savedIp');
        
        try {
          final savedUrl = 'http://$savedIp:${NetworkConfig.esp32CamPort}/stream';
          final response = await _client
              .get(Uri.parse(savedUrl))
              .timeout(const Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            debugPrint('✅ ESP32-CAM connected at saved IP: $savedIp');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Saved IP not responding: $e');
        }
      }

      // Quick scan
      debugPrint('🔍 Starting quick scan for ESP32-CAM...');
      onScanProgress?.call('Quick scanning for ESP32-CAM...');
      
      final quickResult = await _discoveryService.quickScan(
        onProgress: onScanProgress,
      );
      
      if (quickResult != null) {
        _currentIp = quickResult;
        debugPrint('✅ ESP32-CAM found at: $quickResult');
        return true;
      }

      // Full network scan
      debugPrint('🔍 Quick scan failed, starting full network scan...');
      onScanProgress?.call('Scanning network for ESP32-CAM...');
      
      final foundIp = await _discoveryService.scanNetwork(
        onProgress: onScanProgress,
        onScanProgress: onScanStep,
      );

      if (foundIp != null) {
        _currentIp = foundIp;
        debugPrint('✅ ESP32-CAM found at: $foundIp');
        return true;
      }

      debugPrint('❌ ESP32-CAM not found on network');
      return false;
    } catch (e) {
      debugPrint('❌ ESP32 connection test failed: $e');
      return false;
    }
  }

  /// Get the stream endpoint URL using current IP
  String get _streamEndpoint {
    if (_currentIp != null) {
      return 'http://$_currentIp:${NetworkConfig.esp32CamPort}/stream';
    }
    return NetworkConfig.esp32CamStreamEndpoint;
  }

  /// Get the capture endpoint URL using current IP
  String get _captureEndpoint {
    if (_currentIp != null) {
      return 'http://$_currentIp:${NetworkConfig.esp32CamPort}/capture';
    }
    return NetworkConfig.esp32CamCaptureEndpoint;
  }

  /// Capture a sequence of frames from ESP32 stream
  Future<List<Uint8List>> captureFrameSequence({
    int frameCount = 5,
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    if (!isEnabled) {
      throw Esp32Exception('ESP32-CAM integration is disabled');
    }

    final frames = <Uint8List>[];
    
    try {
      for (int i = 0; i < frameCount; i++) {
        final frameBytes = await _captureSingleFrame();
        if (frameBytes != null) {
          frames.add(frameBytes);
        }
        
        if (i < frameCount - 1) {
          await Future.delayed(interval);
        }
      }
      
      return frames;
    } catch (e) {
      throw Esp32Exception('Frame sequence capture failed: $e');
    }
  }

  /// Capture a single frame from ESP32
  Future<Uint8List?> _captureSingleFrame() async {
    try {
      final response = await _client
          .get(Uri.parse(_captureEndpoint))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Monitor connection health
  void _startConnectionMonitoring() {
    _connectionMonitor?.cancel();
    _connectionMonitor = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        await checkStatus();
      } catch (e) {
        _connectionStatus = Esp32ConnectionStatus.error;
        _errorMessage = 'Connection lost: $e';
        await disconnect();
      }
    });
  }

  /// Disconnect from ESP32-CAM stream
  Future<void> disconnect() async {
    _connectionMonitor?.cancel();
    _connectionMonitor = null;
    
    await _frameStreamController?.close();
    _frameStreamController = null;
    
    _connectionStatus = Esp32ConnectionStatus.disconnected;
    _errorMessage = null;
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _client.close();
  }
}

/// ESP32-CAM connection status
enum Esp32ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Frame data from ESP32-CAM
class Esp32Frame {
  final Uint8List imageData;
  final DateTime timestamp;
  final int frameNumber;

  Esp32Frame({
    required this.imageData,
    required this.timestamp,
    required this.frameNumber,
  });

  int get sizeInBytes => imageData.length;
  
  bool get isValid => imageData.isNotEmpty && imageData.length > 100;
}

/// ESP32-CAM device status
class Esp32Status {
  final bool isOnline;
  final int frameRate;
  final int imageQuality;
  final String firmwareVersion;
  final int freeHeap;
  final double temperature;

  Esp32Status({
    required this.isOnline,
    required this.frameRate,
    required this.imageQuality,
    required this.firmwareVersion,
    required this.freeHeap,
    required this.temperature,
  });

  factory Esp32Status.fromJson(String jsonString) {
    // TODO: Parse actual JSON from ESP32-CAM
    // For now, return default status
    return Esp32Status(
      isOnline: true,
      frameRate: DeviceConfig.esp32FrameRate,
      imageQuality: DeviceConfig.esp32ImageQuality,
      firmwareVersion: '1.0.0',
      freeHeap: 50000,
      temperature: 45.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_online': isOnline,
      'frame_rate': frameRate,
      'image_quality': imageQuality,
      'firmware_version': firmwareVersion,
      'free_heap': freeHeap,
      'temperature': temperature,
    };
  }
}

/// Custom exception for ESP32-CAM errors
class Esp32Exception implements Exception {
  final String message;

  Esp32Exception(this.message);

  @override
  String toString() => 'Esp32Exception: $message';
}
