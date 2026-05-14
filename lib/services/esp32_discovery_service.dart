import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/network_config.dart';

/// Service to discover ESP32-CAM on local network
class Esp32DiscoveryService {
  static const String _savedIpKey = 'esp32_saved_ip';
  final http.Client _client;

  Esp32DiscoveryService({http.Client? client}) 
    : _client = client ?? http.Client();

  /// Get saved ESP32 IP address
  Future<String?> getSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedIpKey);
  }

  /// Save ESP32 IP address
  Future<void> saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedIpKey, ip);
    debugPrint('💾 Saved ESP32 IP: $ip');
  }

  /// Clear saved ESP32 IP address
  Future<void> clearSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedIpKey);
    debugPrint('🗑️ Cleared saved ESP32 IP');
  }

  /// Test if ESP32-CAM is available at a specific IP
  Future<bool> testIp(String ip) async {
    try {
      final url = 'http://$ip:${NetworkConfig.esp32CamPort}/stream';
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Scan local network for ESP32-CAM
  /// Returns the IP address if found, null otherwise
  Future<String?> scanNetwork({
    Function(String)? onProgress,
    Function(int, int)? onScanProgress,
  }) async {
    debugPrint('🔍 Starting network scan for ESP32-CAM...');
    
    // Try saved IP first
    final savedIp = await getSavedIp();
    if (savedIp != null) {
      debugPrint('🔍 Testing saved IP: $savedIp');
      onProgress?.call('Testing saved IP: $savedIp');
      if (await testIp(savedIp)) {
        debugPrint('✅ ESP32-CAM found at saved IP: $savedIp');
        return savedIp;
      } else {
        debugPrint('⚠️ Saved IP not responding, clearing...');
        await clearSavedIp();
      }
    }

    // Get device's local IP to determine network subnet
    // For now, we'll scan common private network ranges
    final subnets = [
      '192.168.1',   // Most common router default
      '192.168.0',   // Another common default
      '192.168.43',  // Android hotspot default
      '10.0.0',      // Some routers use this
    ];

    int totalIps = subnets.length * 254;
    int scannedIps = 0;

    for (final subnet in subnets) {
      debugPrint('🔍 Scanning subnet: $subnet.x');
      onProgress?.call('Scanning $subnet.x...');

      // Scan IPs in parallel batches for speed
      const batchSize = 20;
      for (int startIp = 1; startIp <= 254; startIp += batchSize) {
        final futures = <Future<String?>>[];
        
        for (int i = startIp; i < startIp + batchSize && i <= 254; i++) {
          final ip = '$subnet.$i';
          futures.add(_testIpWithResult(ip));
          scannedIps++;
        }

        // Wait for batch to complete
        final results = await Future.wait(futures);
        onScanProgress?.call(scannedIps, totalIps);
        
        // Check if any IP in this batch found the ESP32
        for (final result in results) {
          if (result != null) {
            debugPrint('✅ ESP32-CAM found at: $result');
            await saveIp(result);
            return result;
          }
        }
      }
    }

    debugPrint('❌ ESP32-CAM not found on network');
    return null;
  }

  /// Test IP and return the IP if successful, null otherwise
  Future<String?> _testIpWithResult(String ip) async {
    try {
      final url = 'http://$ip:${NetworkConfig.esp32CamPort}/stream';
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        return ip;
      }
    } catch (e) {
      // Silently fail for each IP
    }
    return null;
  }

  /// Quick scan of most likely IPs first
  Future<String?> quickScan({Function(String)? onProgress}) async {
    debugPrint('⚡ Starting quick scan...');
    
    // Try saved IP first
    final savedIp = await getSavedIp();
    if (savedIp != null) {
      onProgress?.call('Testing saved IP...');
      if (await testIp(savedIp)) {
        return savedIp;
      }
      await clearSavedIp();
    }

    // Try most common ESP32 default IPs
    final commonIps = [
      '192.168.1.100',
      '192.168.1.1',
      '192.168.0.100',
      '192.168.43.50',
      '192.168.4.1',  // ESP32 AP mode default
    ];

    onProgress?.call('Checking common IPs...');
    for (final ip in commonIps) {
      if (await testIp(ip)) {
        debugPrint('✅ ESP32-CAM found at: $ip');
        await saveIp(ip);
        return ip;
      }
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
