import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service for capturing frames from phone camera
class PhoneCameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  final List<Uint8List> _capturedFrames = [];

  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  List<Uint8List> get capturedFrames => List.unmodifiable(_capturedFrames);
  CameraController? get controller => _controller;

  /// Initialize camera
  Future<bool> initialize() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        debugPrint('❌ No cameras available');
        return false;
      }

      // Use back camera by default
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      
      debugPrint('✅ Phone camera initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Camera initialization failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start capturing frames at regular intervals
  Future<void> startCapturing({Duration interval = const Duration(milliseconds: 500)}) async {
    if (!_isInitialized || _controller == null) {
      debugPrint('⚠️ Camera not initialized');
      return;
    }

    if (_isCapturing) {
      debugPrint('⚠️ Already capturing');
      return;
    }

    _isCapturing = true;
    _capturedFrames.clear();
    
    debugPrint('📸 Started capturing frames (interval: ${interval.inMilliseconds}ms)');

    // Start continuous capture loop in background
    _captureLoop(interval);
  }

  /// Continuous capture loop - properly awaits each capture
  Future<void> _captureLoop(Duration interval) async {
    while (_isCapturing && _controller != null && _controller!.value.isInitialized) {
      try {
        final image = await _controller!.takePicture();
        final bytes = await image.readAsBytes();
        _capturedFrames.add(bytes);
        
        debugPrint('📸 Captured frame ${_capturedFrames.length}');
        
        // Wait for interval before next capture
        if (_isCapturing) {
          await Future.delayed(interval);
        }
      } catch (e) {
        debugPrint('❌ Frame capture failed: $e');
        // Small delay before retry
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    debugPrint('🛑 Capture loop ended');
  }

  /// Stop capturing frames
  Future<void> stopCapturing() async {
    if (!_isCapturing) return;

    _isCapturing = false;
    
    // Wait a bit for the capture loop to finish cleanly
    await Future.delayed(const Duration(milliseconds: 100));
    
    debugPrint('🛑 Stopped capturing (${_capturedFrames.length} frames captured)');
  }

  /// Get captured frames and clear buffer
  List<Uint8List> getFramesAndClear() {
    // Stop capturing first to prevent concurrent modification
    if (_isCapturing) {
      _isCapturing = false;
    }
    
    // Create a defensive copy
    final frames = List<Uint8List>.from(_capturedFrames);
    _capturedFrames.clear();
    return frames;
  }

  /// Clear captured frames
  void clearFrames() {
    _capturedFrames.clear();
  }



  /// Dispose camera resources
  Future<void> dispose() async {
    stopCapturing();
    
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    
    _isInitialized = false;
    debugPrint('🗑️ Phone camera service disposed');
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) {
      debugPrint('⚠️ No other camera available');
      return false;
    }

    final currentLens = _controller?.description.lensDirection;
    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentLens,
      orElse: () => _cameras.first,
    );

    await dispose();
    
    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    _isInitialized = true;
    
    debugPrint('🔄 Switched to ${newCamera.lensDirection} camera');
    return true;
  }
}
