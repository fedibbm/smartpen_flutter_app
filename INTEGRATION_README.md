# DyslexiPen Reader - External Service Integration

## 🎯 Project Overview

**DyslexiPen Reader** is a Flutter application designed to assist dyslexic users with text recognition and comprehension. The app integrates with two external services for text processing but maintains a clean separation between active and planned integrations.

### Current Architecture Status

#### ✅ **ACTIVE Integration: Python OpenCV OCR Backend**
- **Status**: Fully implemented and operational
- **Purpose**: Receives images/frames and extracts text via REST API
- **Flow**: Flutter App → HTTP Request → Python OCR Server → Text Response → UI Display
- **Fallback**: Automatically falls back to mock data if server is unreachable

#### 🔧 **PLANNED Integration: ESP32-CAM Video Streaming**
- **Status**: Fully implemented but **DISABLED** (not connected to UI)
- **Purpose**: Stream video frames from ESP32-CAM hardware for real-time OCR
- **Flow**: ESP32-CAM → Video Stream → Flutter App → OCR Backend → Text Display
- **Future**: Will be enabled when hardware is ready

---

## 📁 Project Structure

```
lib/
├── config/
│   ├── network_config.dart       # All URLs, IPs, ports, endpoints
│   └── device_config.dart        # Feature flags, device settings
├── services/
│   ├── ocr_backend_service.dart  # ✅ ACTIVE - OCR REST API client
│   └── esp32_camera_service.dart # 🔧 DISABLED - ESP32 stream handler
├── providers/
│   └── smart_pen_provider.dart   # State management with service integration
├── models/
│   └── smart_pen_models.dart     # Data models
├── screens/
│   ├── home_screen.dart
│   ├── welcome_screen.dart
│   └── accessibility_settings_screen.dart
└── widgets/
    ├── ocr_status_widget.dart    # Shows OCR backend connection status
    └── ...
```

---

## 🔧 Configuration System

### All external endpoints are configured in `/lib/config/network_config.dart`

**Never hardcode URLs in widgets or services!**

```dart
// Python OCR Server
static const String ocrServerHost = 'localhost';
static const int ocrServerPort = 5000;
static String get ocrExtractTextEndpoint => 'http://localhost:5000/extract-text';

// ESP32-CAM (for future use)
static const String esp32CamHost = '192.168.1.100';
static String get esp32CamStreamEndpoint => 'http://192.168.1.100/stream';
```

### Feature flags in `/lib/config/device_config.dart`

```dart
static const bool enableEsp32Integration = false; // DISABLED for now
static const bool enableOcrBackend = true;        // ACTIVE
static const bool enableMockMode = true;          // Fallback enabled
```

---

## 🌐 External Services

### 1. Python OpenCV OCR Server (ACTIVE)

**You must run this server externally** - not part of this Flutter project.

#### Expected API Endpoints:

**Health Check:**
```
GET http://localhost:5000/health
Response: 200 OK
```

**Text Extraction:**
```
POST http://localhost:5000/extract-text
Content-Type: multipart/form-data
Body: image file

Response (JSON):
{
  "text": "extracted text here",
  "confidence": 0.95,
  "success": true,
  "timestamp": "2025-12-07T10:30:00Z",
  "metadata": { ... }
}
```

#### How the Flutter app uses it:
1. App sends image via `OcrBackendService.extractText(imageBytes)`
2. Service calls `/extract-text` endpoint
3. Receives JSON response with extracted text
4. Converts to `RecognizedText` model
5. Displays in UI with accessibility features

#### Automatic Fallback:
- If server is unreachable: Uses mock data
- If request fails: Retries up to 3 times with 2-second delay
- Health check runs on app startup

---

### 2. ESP32-CAM Video Stream (DISABLED - Future Integration)

**Hardware not required yet** - service is scaffolded but inactive.

#### Expected API Endpoints (when enabled):

**Status Check:**
```
GET http://192.168.1.100/status
Response: Device status JSON
```

**Video Stream:**
```
GET http://192.168.1.100/stream
Response: MJPEG stream of video frames
```

**Single Frame Capture:**
```
GET http://192.168.1.100/capture
Response: JPEG image
```

#### Implementation Status:
✅ Full MJPEG stream parsing logic  
✅ Frame extraction from byte stream  
✅ Connection monitoring  
✅ Error handling  
❌ **NOT connected to UI** (disabled by feature flag)  
❌ **NOT used in current workflow**

#### Future Integration Plan:
When `enableEsp32Integration = true`:
1. ESP32-CAM streams video → Flutter app
2. Flutter extracts frames → sends to OCR backend
3. OCR extracts text → displays with simplification
4. Real-time processing pipeline

---

## 🔄 Current Workflow (Active)

```
┌─────────────────┐
│   User opens    │
│   Flutter App   │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  Health check:      │
│  OCR Server running?│
└────────┬────────────┘
         │
    ┌────┴────┐
    │ Yes     │ No
    ▼         ▼
┌───────┐  ┌──────┐
│ Real  │  │ Mock │
│ OCR   │  │ Mode │
└───┬───┘  └──┬───┘
    │         │
    └────┬────┘
         ▼
┌──────────────────┐
│ User triggers    │
│ text recognition │
└────────┬─────────┘
         │
         ▼
┌──────────────────────┐
│ Generate mock image  │◄── (Using mock strokes for now)
│ or use real image    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Send to OCR backend  │
│ /extract-text        │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Receive text + conf. │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Display with:        │
│ - Simplification     │
│ - Keywords           │
│ - Definitions        │
│ - Accessibility      │
└──────────────────────┘
```

---

## 🎨 UI Components

### OCR Status Indicator
Shows real-time connection status to Python OCR backend:
- 🟢 **Green**: Connected to real OCR server
- 🟠 **Orange**: Offline, using mock data
- **Retry Button**: Manually reconnect to server

### Connection Status
Shows smart pen device connection (simulated for now)

### Text Recognition Display
Shows extracted text with:
- Original text
- Simplified version
- Highlighted keywords
- Word definitions
- Complexity indicators

---

## 🚀 Getting Started

### Prerequisites
```bash
# Flutter SDK 3.7.2+
flutter --version

# Dependencies installed
flutter pub get
```

### Running the App (Mock Mode)
```bash
# App runs with mock data if OCR server not available
flutter run -d chrome
```

### Running with Real OCR Backend

1. **Start Python OCR Server** (external project):
```bash
# Example (adjust to your server)
python ocr_server.py
# Server must run on http://localhost:5000
```

2. **Configure endpoints** in `lib/config/network_config.dart`:
```dart
static const String ocrServerHost = 'localhost'; // Change if needed
static const int ocrServerPort = 5000;
```

3. **Run Flutter app**:
```bash
flutter run -d chrome
```

4. **Verify connection**: Check green status indicator in app UI

---

## 🔌 Service API Reference

### OcrBackendService (Active)

```dart
final ocrService = OcrBackendService();

// Check server health
bool isHealthy = await ocrService.checkHealth();

// Extract text from image
OcrResponse response = await ocrService.extractText(imageBytes);

// With automatic retry
OcrResponse response = await ocrService.extractTextWithRetry(imageBytes);

// Batch processing
List<OcrResponse> results = await ocrService.extractTextBatch([img1, img2]);
```

### Esp32CameraService (Disabled)

```dart
final esp32Service = Esp32CameraService();

// Check if enabled (returns false for now)
bool enabled = esp32Service.isEnabled;

// Future usage when enabled:
// await esp32Service.connectToStream();
// esp32Service.frameStream?.listen((frame) { ... });
```

---

## ⚙️ Configuration Reference

### Network Configuration (`network_config.dart`)

| Setting | Default | Description |
|---------|---------|-------------|
| `ocrServerHost` | `localhost` | OCR server hostname/IP |
| `ocrServerPort` | `5000` | OCR server port |
| `esp32CamHost` | `192.168.1.100` | ESP32-CAM IP address |
| `esp32CamPort` | `80` | ESP32-CAM port |
| `connectionTimeout` | `10 seconds` | Connection timeout |
| `maxRetries` | `3` | Max retry attempts |

### Device Configuration (`device_config.dart`)

| Flag | Default | Description |
|------|---------|-------------|
| `enableEsp32Integration` | `false` | ⚠️ ESP32-CAM disabled |
| `enableOcrBackend` | `true` | ✅ OCR backend active |
| `enableMockMode` | `true` | Fallback enabled |

---

## 🧪 Testing

### Test OCR Integration
1. Ensure Python OCR server is running
2. Check health endpoint: `curl http://localhost:5000/health`
3. Launch app and verify green status indicator
4. Trigger text recognition and observe real OCR responses

### Test Mock Fallback
1. Stop Python OCR server
2. Launch app
3. Status should show orange (offline)
4. App should continue working with mock data

### Test ESP32 Service (Unit Tests)
```bash
flutter test test/services/esp32_camera_service_test.dart
```

---

## 📦 Dependencies

```yaml
dependencies:
  provider: ^6.1.2          # State management
  http: ^1.2.0              # REST API client
  animated_text_kit: ^4.2.2 # UI animations
  lottie: ^3.1.2           # Lottie animations
  flutter_colorpicker: ^1.1.0
```

---

## 🔮 Future Enhancements

1. **Enable ESP32-CAM Integration**
   - Set `enableEsp32Integration = true`
   - Connect service to UI
   - Real-time video stream processing

2. **Enhanced Text Processing**
   - Real text simplification algorithms
   - Dictionary API integration
   - Multi-language support

3. **Persistent Storage**
   - Save recognized texts
   - User preferences
   - History and favorites

4. **Text-to-Speech**
   - Functional TTS (currently UI-only)
   - Adjustable reading speed

---

## 📝 Architecture Notes

### Why ESP32 Service is Implemented but Disabled?

✅ **Clean architecture**: Service ready when hardware arrives  
✅ **No refactoring needed**: Just flip feature flag  
✅ **Testing ready**: Can unit test without hardware  
✅ **Documentation**: Future developers understand the plan  

### Configuration Philosophy

❌ **NEVER** hardcode URLs in widgets  
✅ **ALWAYS** use config files  
✅ **Centralized** configuration management  
✅ **Environment-specific** settings support  

---

## 👥 Contributing

When adding external services:
1. Create service class in `lib/services/`
2. Add configuration to `lib/config/`
3. Add feature flag to `device_config.dart`
4. Integrate into provider
5. Update this README

---

## 📄 License

This project is part of IEEE WIE Smart Pen initiative for dyslexic users.

---

## 🆘 Troubleshooting

### "OCR Server Offline" Status
- Verify Python server is running: `curl http://localhost:5000/health`
- Check `network_config.dart` has correct host/port
- Check firewall settings
- Click "Retry" button in app

### App Not Connecting to ESP32
- ESP32 integration is **disabled by design**
- To enable: Set `enableEsp32Integration = true` in `device_config.dart`
- Ensure ESP32-CAM is on same network
- Verify ESP32-CAM IP address matches configuration

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

---

**Last Updated**: December 7, 2025  
**Flutter Version**: 3.7.2+  
**Architecture Status**: OCR Active, ESP32 Scaffolded
