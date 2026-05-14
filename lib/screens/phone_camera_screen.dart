import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/smart_pen_provider.dart';
import '../l10n/app_localizations.dart';

/// Screen for capturing text with phone camera
class PhoneCameraScreen extends StatefulWidget {
  const PhoneCameraScreen({Key? key}) : super(key: key);

  @override
  State<PhoneCameraScreen> createState() => _PhoneCameraScreenState();
}

class _PhoneCameraScreenState extends State<PhoneCameraScreen> {
  bool _isCapturing = false;
  int _frameCount = 0;
  bool _isInitializing = false;
  final List<Uint8List> _capturedFrameBytes = [];
  int _captureSessionId = 0;
  Timer? _captureTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _isInitializing) return;
    
    _isInitializing = true;
    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    
    try {
      if (!provider.phoneCameraInitialized) {
        final success = await provider.initializePhoneCamera();
        if (!success || !mounted) {
          _isInitializing = false;
          return;
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) {
        _isInitializing = false;
        return;
      }
      
      debugPrint('✅ Camera ready - waiting for user to start capture');
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
    } finally {
      _isInitializing = false;
    }
  }
  
  @override
  void deactivate() {
    _captureTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCapture() async {
    _captureSessionId++;
    final sessionId = _captureSessionId;
    
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🎬 START CAPTURE - Session #$sessionId');
    debugPrint('═══════════════════════════════════════════');
    
    if (_isCapturing) {
      debugPrint('❌ Already capturing - ignoring');
      return;
    }

    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    final controller = provider.phoneCameraService.controller;
    
    if (controller == null || !controller.value.isInitialized) {
      debugPrint('❌ Camera not ready');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cameraNotReady')),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    _capturedFrameBytes.clear();
    
    setState(() {
      _isCapturing = true;
      _frameCount = 0;
    });
    
    debugPrint('📸 Starting frame capture every 400ms...');
    
    _captureTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) async {
      if (!_isCapturing || !mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final image = await controller.takePicture();
        final bytes = await image.readAsBytes();
        _capturedFrameBytes.add(bytes);
        
        if (mounted) {
          setState(() {
            _frameCount = _capturedFrameBytes.length;
          });
        }
        
        debugPrint('📷 Captured frame ${_capturedFrameBytes.length} (${bytes.length} bytes)');
        
        if (_capturedFrameBytes.length >= 30) {
          debugPrint('⚠️ Reached 30 frames limit - stopping automatically');
          if (mounted) {
            _stopCapture();
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error capturing frame: $e');
      }
    });
  }

  Future<void> _stopCapture() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('🛑 STOP CAPTURE - Session #$_captureSessionId');
    debugPrint('═══════════════════════════════════════════');
    
    if (!_isCapturing) {
      debugPrint('❌ Not capturing - ignoring stop request');
      return;
    }

    _captureTimer?.cancel();
    _captureTimer = null;
    
    setState(() {
      _isCapturing = false;
    });
    
    final frameBytes = List<Uint8List>.from(_capturedFrameBytes);
    
    debugPrint('🔄 Processing ${frameBytes.length} captured frames...');
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.tr('processingFrames')),
            ],
          ),
        ),
      );
    }
    
    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    
    try {
      await provider.processFramesWithMLKit(frameBytes, source: 'Phone Camera');
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Processed ${frameBytes.length} frames successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error processing images: $e');
      
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(context.tr('scanText')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Consumer<SmartPenProvider>(
        builder: (context, provider, child) {
          final controller = provider.phoneCameraService.controller;

          if (!provider.phoneCameraInitialized || controller == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),

              if (!_isCapturing)
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Colors.white.withOpacity(0.7),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('pointCameraAtText'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '⚡ ML Kit OCR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCapturing 
                            ? '📸 Capturing frames... ($_frameCount frames)' 
                            : context.tr('cameraReady'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCapturing
                            ? context.tr('tapToFinish')
                            : context.tr('tapToStart'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      if (_isCapturing)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('capturing'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      GestureDetector(
                        onTap: () {
                          debugPrint('');
                          debugPrint('👆 Button tapped!');
                          debugPrint('   Current _isCapturing: $_isCapturing');
                          debugPrint('   Will call: ${_isCapturing ? "_stopCapture" : "_startCapture"}');
                          
                          if (_isCapturing) {
                            _stopCapture();
                          } else {
                            _startCapture();
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? Colors.red : Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Icon(
                            _isCapturing ? Icons.stop : Icons.fiber_manual_record,
                            color: _isCapturing ? Colors.white : Colors.red,
                            size: 40,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        _isCapturing ? context.tr('tapToFinish') : context.tr('tapToStart'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
