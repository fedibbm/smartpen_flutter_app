import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/smart_pen_provider.dart';

/// Screen for capturing text with phone camera
class PhoneCameraScreen extends StatefulWidget {
  const PhoneCameraScreen({Key? key}) : super(key: key);

  @override
  State<PhoneCameraScreen> createState() => _PhoneCameraScreenState();
}

class _PhoneCameraScreenState extends State<PhoneCameraScreen> {
  bool _isCapturing = false;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    if (!provider.phoneCameraInitialized) {
      await provider.initializePhoneCamera();
    }
  }

  Future<void> _startCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _frameCount = 0;
    });

    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    
    // Start capturing frames
    await provider.phoneCameraService.startCapturing();

    // Update frame count every 200ms
    while (_isCapturing && mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _frameCount = provider.phoneCameraService.capturedFrames.length;
        });
      }
    }
  }

  Future<void> _stopCapture() async {
    if (!_isCapturing) return;

    setState(() {
      _isCapturing = false;
    });

    final provider = Provider.of<SmartPenProvider>(context, listen: false);
    provider.phoneCameraService.stopCapturing();

    final frames = provider.phoneCameraService.getFramesAndClear();
    
    if (frames.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No frames captured. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate back and process frames
    if (mounted) {
      Navigator.pop(context, frames);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Text'),
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
              // Camera preview
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              ),

              // Scan guide overlay
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
                          Icons.arrow_forward,
                          color: Colors.white.withOpacity(0.7),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Move camera slowly →',
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

              // Instructions
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
                      Text(
                        _isCapturing 
                            ? '📸 Capturing frames... ($_frameCount captured)' 
                            : '📷 Ready to scan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isCapturing
                            ? 'Move camera slowly across the text from left to right'
                            : 'Tap the button below to start scanning',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Controls
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      // Capture status indicator
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
                              const Text(
                                'RECORDING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Capture button
                      GestureDetector(
                        onTap: _isCapturing ? _stopCapture : _startCapture,
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
                        _isCapturing ? 'Tap to finish' : 'Tap to start',
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
