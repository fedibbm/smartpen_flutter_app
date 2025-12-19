import 'package:flutter/material.dart';
import '../models/smart_pen_models.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final ConnectionStatus status;
  final SmartPenDevice? connectedDevice;

  const ConnectionStatusWidget({
    Key? key,
    required this.status,
    this.connectedDevice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        border: Border.all(color: _getStatusColor(), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                if (connectedDevice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    connectedDevice!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        connectedDevice!.type == ConnectionType.wifi
                            ? Icons.wifi
                            : Icons.bluetooth,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(connectedDevice!.signalStrength * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.battery_std,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${connectedDevice!.batteryLevel}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return const Icon(Icons.link_off, color: Colors.grey, size: 24);
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case ConnectionStatus.connected:
        return const Icon(Icons.link, color: Colors.green, size: 24);
      case ConnectionStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 24);
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}
