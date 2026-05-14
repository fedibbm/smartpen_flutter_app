/// Network configuration for external services
/// All hostnames, IPs, ports, and endpoints are defined here
/// NEVER hardcode these values in widgets or services

class NetworkConfig {
  // Python OpenCV OCR Server Configuration
  // LOCAL NETWORK: Change to your machine's IP address when testing locally
  static const String ocrServerBaseUrl = 'http://192.168.1.14:5000';
  // AZURE (Production): 'http://ocr-demo-enit.francecentral.azurecontainer.io:5000'
  
  static String get ocrExtractTextEndpoint => '$ocrServerBaseUrl/ocr';
  static String get ocrStitchEndpoint => '$ocrServerBaseUrl/ocr-stitch';
  static String get ocrHealthEndpoint => '$ocrServerBaseUrl/health';
  
  // LibreTranslate API Configuration (Free translation service)
  static const String libreTranslateHost = 'libretranslate.com';
  static const String libreTranslateProtocol = 'https';
  
  static String get libreTranslateBaseUrl => '$libreTranslateProtocol://$libreTranslateHost';
  static String get libreTranslateEndpoint => '$libreTranslateBaseUrl/translate';
  static String get libreTranslateLanguagesEndpoint => '$libreTranslateBaseUrl/languages';
  
  // Free Dictionary API Configuration (No API key needed)
  static const String dictionaryApiHost = 'api.dictionaryapi.dev';
  static const String dictionaryApiProtocol = 'https';
  
  static String get dictionaryApiBaseUrl => '$dictionaryApiProtocol://$dictionaryApiHost';
  static String dictionaryApiEndpoint(String language, String word) => 
      '$dictionaryApiBaseUrl/api/v2/entries/$language/${Uri.encodeComponent(word)}';
  
  // ESP32-CAM Configuration (for future integration)
  static const String esp32CamHost = '192.168.43.50'; // Change to your ESP32-CAM IP
  static const int esp32CamPort = 80;
  static const String esp32CamProtocol = 'http';
  
  static String get esp32CamBaseUrl => '$esp32CamProtocol://$esp32CamHost:$esp32CamPort';
  static String get esp32CamStreamEndpoint => '$esp32CamBaseUrl/stream';
  static String get esp32CamCaptureEndpoint => '$esp32CamBaseUrl/capture';
  static String get esp32CamStatusEndpoint => '$esp32CamBaseUrl/status';
  
  // Connection Settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Network Quality Thresholds
  static const double minSignalStrength = 0.3;
  static const int minBandwidthKbps = 100;
}
