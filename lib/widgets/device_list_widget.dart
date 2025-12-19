import 'package:flutter/material.dart';
import '../models/smart_pen_models.dart';

class DeviceListWidget extends StatelessWidget {
  final List<SmartPenDevice> devices;
  final ConnectionStatus connectionStatus;
  final Function(SmartPenDevice) onDeviceSelected;
  final VoidCallback onScanPressed;

  const DeviceListWidget({
    Key? key,
    required this.devices,
    required this.connectionStatus,
    required this.onDeviceSelected,
    required this.onScanPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: connectionStatus != ConnectionStatus.connecting
                      ? onScanPressed
                      : null,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Scan'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No devices found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap scan to search for smart pens',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = devices[index];
                return DeviceListTile(
                  device: device,
                  isConnecting: connectionStatus == ConnectionStatus.connecting,
                  onTap: () => onDeviceSelected(device),
                );
              },
            ),
        ],
      ),
    );
  }
}

class DeviceListTile extends StatelessWidget {
  final SmartPenDevice device;
  final bool isConnecting;
  final VoidCallback onTap;

  const DeviceListTile({
    Key? key,
    required this.device,
    required this.isConnecting,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isConnecting ? null : onTap,
      leading: CircleAvatar(
        backgroundColor: device.type == ConnectionType.wifi
            ? Colors.blue.shade100
            : Colors.purple.shade100,
        child: Icon(
          device.type == ConnectionType.wifi ? Icons.wifi : Icons.bluetooth,
          color: device.type == ConnectionType.wifi
              ? Colors.blue.shade700
              : Colors.purple.shade700,
        ),
      ),
      title: Text(
        device.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${(device.signalStrength * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.battery_std,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${device.batteryLevel}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: isConnecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
