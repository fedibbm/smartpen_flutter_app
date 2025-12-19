import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_pen_provider.dart';
import '../config/device_config.dart';

/// Widget showing OCR backend connection status
class OcrStatusWidget extends StatelessWidget {
  const OcrStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartPenProvider>(
      builder: (context, provider, child) {
        final isConnected = provider.isOcrServerConnected;
        final isUsingReal = provider.isUsingRealOcr;

        return Card(
          color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isConnected ? 'OCR Server Connected' : 'OCR Server Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isConnected ? Colors.green.shade900 : Colors.orange.shade900,
                        ),
                      ),
                      Text(
                        isUsingReal ? 'Using real OCR backend' : 'Using mock data',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isConnected && DeviceConfig.enableOcrBackend)
                  TextButton(
                    onPressed: () => provider.retryOcrConnection(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
