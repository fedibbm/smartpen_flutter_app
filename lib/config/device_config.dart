/// Device configuration for WiFi and Bluetooth settings
/// NEVER hardcode SSIDs or device identifiers in UI code

class DeviceConfig {
  // WiFi Configuration
  static const String defaultWifiSsid = 'DyslexiPen-Network';
  static const String fallbackWifiSsid = 'SmartPen-Guest';
  
  // ESP32-CAM Device Settings
  static const String esp32DevicePrefix = 'ESP32-CAM';
  static const int esp32FrameRate = 10; // FPS for video stream
  static const int esp32ImageQuality = 80; // JPEG quality (1-100)
  static const String esp32ImageFormat = 'jpeg';
  
  // OCR Processing Settings
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB max
  static const int imageCompressionQuality = 85;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'bmp'];
  
  // Feature Flags
  static const bool enableEsp32Integration = false; // DISABLED for now
  static const bool enableMockMode = true; // Keep mock data during development
  static const bool enableOcrBackend = true; // ACTIVE - real OCR service
  static const bool enableTextProcessing = true; // ACTIVE - translation & correction
  
  // Text Processing Settings
  static const String defaultTargetLanguage = 'en';
  static const bool autoCorrectText = true;
  static const bool autoTranslate = false; // Only translate when user requests
  
  // Device Discovery
  static const Duration deviceScanDuration = Duration(seconds: 5);
  static const int maxDevicesInList = 10;
  
  // Battery and Signal
  static const int lowBatteryThreshold = 20;
  static const double weakSignalThreshold = 0.4;
}
