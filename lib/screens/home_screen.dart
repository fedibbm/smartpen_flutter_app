import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_pen_provider.dart';
import '../models/smart_pen_models.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_list_widget.dart';
import '../widgets/text_recognition_widget.dart';
import '../widgets/ocr_status_widget.dart';
import 'model_download_screen.dart';
import 'scan_history_screen.dart';
import 'phone_camera_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  /// Handle start scanning based on camera mode
  Future<void> _handleStartScanning(BuildContext context, SmartPenProvider provider) async {
    if (provider.cameraMode == CameraMode.phoneCamera) {
      // Navigate to camera screen
      final frames = await Navigator.push<List<Uint8List>>(
        context,
        MaterialPageRoute(
          builder: (context) => const PhoneCameraScreen(),
        ),
      );

      // Process frames if captured
      if (frames != null && frames.isNotEmpty) {
        await provider.processPhoneCameraFrames(frames);
      }
    } else {
      // ESP32 or dummy mode
      await provider.startScanWithCurrentMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          context.tr('appName'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModelDownloadScreen(),
                ),
              );
            },
            icon: const Icon(Icons.download),
            tooltip: context.tr('translationModels'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Consumer<SmartPenProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // OCR Backend Status - HIDDEN
                // const OcrStatusWidget(),
                
                // const SizedBox(height: 24),
                
                // Scan Control Buttons - ALWAYS VISIBLE
                Container(
                  decoration: BoxDecoration(
                    color: provider.isScanning ? Colors.red.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: provider.isScanning ? Colors.red.shade200 : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              provider.isScanning ? Icons.stop_circle : Icons.camera_alt,
                              color: provider.isScanning ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              provider.isScanning ? context.tr('scanningActive') : context.tr('readyToScan'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: provider.isScanning ? Colors.red.shade900 : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.isScanning
                              ? context.tr('capturingFrames')
                              : context.tr('clickStartToScan'),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        
                        // Show error if any
                        if (provider.cameraError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                        color: Colors.red.shade700, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        provider.cameraError!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // Show network scan button if ESP32 is not connected
                                if (provider.cameraMode == CameraMode.esp32 && 
                                    !provider.esp32Connected) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: provider.scanStatus.isNotEmpty 
                                          ? null 
                                          : () async {
                                              await provider.checkEsp32Connection(
                                                performNetworkScan: true,
                                              );
                                            },
                                      icon: provider.scanStatus.isNotEmpty
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(Icons.search, size: 16),
                                      label: Text(
                                        provider.scanStatus.isNotEmpty
                                            ? provider.scanStatus
                                            : context.tr('scanNetworkForESP32'),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.isScanning
                                ? () => provider.stopScanning()
                                : () => _handleStartScanning(context, provider),
                            icon: Icon(
                              provider.isScanning ? Icons.stop : Icons.camera_alt,
                            ),
                            label: Text(
                              provider.isScanning ? context.tr('stopScanning') : context.tr('startScanning'),
                              style: const TextStyle(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider.isScanning
                                  ? Colors.red.shade600
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Text Recognition
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('latestScan'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.recognizedTexts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, size: 20),
                        label: Text('${context.tr('viewAll')} (${provider.recognizedTexts.length})'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                SizedBox(
                  height: 400,
                  child: TextRecognitionWidget(
                    recognizedTexts: provider.recognizedTexts.isNotEmpty 
                        ? [provider.recognizedTexts.first] // Show only the latest (newest is at index 0)
                        : [],
                    recognitionStatus: provider.recognitionStatus,
                    onClear: provider.clearRecognizedTexts,
                    showLatestOnly: true, // New parameter to indicate this is latest-only view
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Device List
                DeviceListWidget(
                  devices: provider.availableDevices,
                  connectionStatus: provider.connectionStatus,
                  onDeviceSelected: (device) {
                    provider.connectToDevice(device);
                  },
                  onScanPressed: provider.scanForDevices,
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                if (provider.connectionStatus == ConnectionStatus.connected) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.clearRecognizedTexts,
                          icon: const Icon(Icons.clear_all),
                          label: Text(context.tr('clearText')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: provider.disconnect,
                          icon: const Icon(Icons.link_off),
                          label: Text(context.tr('disconnect')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Additional accessibility features
                if (provider.connectionStatus == ConnectionStatus.connected) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('accessibilityFeatures'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.tr('fontSizeIncreased')),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.text_increase),
                                  label: Text(context.tr('largeFont')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.tr('highContrastEnabled')),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.contrast),
                                  label: Text(context.tr('highContrast')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
