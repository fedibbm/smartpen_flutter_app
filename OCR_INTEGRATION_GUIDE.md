# 🎯 OCR Integration - Quick Start Guide

## What Changed

Your Flutter app now **sends mock images to the OCR server** and **receives real text responses**. The text extraction happens through actual API calls, not internal mocks.

---

## 📋 Current Workflow

```
User Action (or Auto-trigger)
    ↓
Generate Mock Image (from handwriting strokes)
    ↓
Send Image to OCR Server (HTTP POST)
    ↓
OCR Server Extracts Text (mock response for now)
    ↓
Flutter App Receives Text Response
    ↓
Display with Simplification + Definitions + Accessibility Features
```

---

## 🚀 How to Test

### Step 1: Start the OCR Server

In a separate terminal/project:

```bash
# Install dependencies
pip install -r requirements.txt

# Run server (default: localhost:5000)
python app.py
```

**Server must be running before starting the Flutter app!**

### Step 2: Run Flutter App

```bash
cd /home/fedi/dev/work/ieee_wie/Smartpen
flutter run -d chrome
```

### Step 3: Check OCR Connection

In the app UI, you'll see an **OCR status card** at the top:

- 🟢 **Green** = Connected to real OCR server
- 🟠 **Orange** = Offline (using internal mock fallback)

If orange, click **"Retry"** to reconnect.

### Step 4: Test OCR

**Option A: Manual Test Button** (Recommended)

1. Look for the **"OCR Testing"** card in the home screen
2. Click **"Send Mock Image to OCR"** button
3. Watch the app:
   - Generate a mock image
   - Send it to `http://localhost:5000/extract-text`
   - Receive text from server
   - Display with simplification

**Option B: Connect to Mock Device**

1. Scroll to **"Available Devices"**
2. Click **"Connect"** on any device
3. App will auto-generate mock handwriting every 3 seconds
4. Each stroke → mock image → OCR server → text display

---

## 🔍 What Happens Behind the Scenes

### Image Generation

```dart
// Mock handwriting strokes are generated
List<Offset> points = [...]; // Simulated pen movements

// Convert strokes to PNG image
Uint8List mockImage = await MockImageGenerator.generateFromStrokes(points);
// OR use placeholder:
Uint8List mockImage = await MockImageGenerator.generatePlaceholder();
```

### API Call

```dart
// Send to OCR server
POST http://localhost:5000/extract-text
Content-Type: multipart/form-data
Body: { image: <PNG bytes> }

// Receive response
{
  "text": "The phenomenon of photosynthesis is fundamental...",
  "confidence": 0.95,
  "success": true,
  "timestamp": "2025-12-07T10:30:00Z"
}
```

### Text Processing

```dart
// Extract text
String originalText = response.text;

// Simplify for dyslexic users
String simplified = "how plants make food is very important...";

// Extract keywords
List<String> keywords = ["photosynthesis", "fundamental"];

// Generate definitions
List<String> definitions = [
  "Photosynthesis: How plants use sunlight to make food",
  "Fundamental: Very important or basic"
];
```

---

## 🎨 UI Features

### OCR Status Widget
- Shows connection status to Python server
- Auto-checks health on app startup
- Manual retry button

### Test OCR Button
- Manually trigger OCR with mock image
- Only enabled when server is connected
- Great for testing without device connection

### Recognized Text Display
- **Original Text**: What OCR server returned
- **Simplified Text**: Easier version for dyslexic readers
- **Keywords**: Important words highlighted
- **Definitions**: Simple explanations
- **Confidence Score**: OCR accuracy (85-99%)

---

## 🔧 Configuration

All settings in `lib/config/network_config.dart`:

```dart
// Change if your OCR server uses different host/port
static const String ocrServerHost = 'localhost';
static const int ocrServerPort = 5000;
```

Feature flags in `lib/config/device_config.dart`:

```dart
static const bool enableOcrBackend = true;  // ✅ Active
static const bool enableMockMode = true;     // Fallback if server offline
```

---

## 📊 What Gets Sent to OCR Server

### Image Format
- **Type**: PNG
- **Size**: 400x300 pixels (mock images)
- **Content**: Black strokes on white background
- **Generated from**: Simulated handwriting points

### Request Details
```
Method: POST
Endpoint: /extract-text
Content-Type: multipart/form-data
Field name: "image"
File size: ~5-50KB (depending on strokes)
```

---

## 🧪 Testing Checklist

Before each test session:

- [ ] OCR server is running (`python app.py`)
- [ ] Server is on `http://localhost:5000`
- [ ] Flutter app shows green status indicator
- [ ] "Send Mock Image to OCR" button is enabled
- [ ] Click test button and verify text appears
- [ ] Check browser console for debug logs:
  ```
  ✅ OCR Backend server is connected and healthy
  🧪 Testing OCR with mock image...
  ✅ Mock image generated: 12345 bytes
  ```

---

## 🐛 Troubleshooting

### OCR Status Shows Orange (Offline)

**Problem**: App can't connect to OCR server

**Solutions**:
1. Verify server is running: `curl http://localhost:5000/health`
2. Check port 5000 is not blocked
3. Ensure no firewall blocking localhost
4. Click "Retry" button in app
5. Check server logs for errors

### "Send Mock Image" Button Disabled

**Reason**: OCR server not connected

**Fix**: Get green status first (see above)

### No Text Appears After Sending Image

**Check**:
1. Browser console for errors (F12 → Console)
2. OCR server logs for incoming requests
3. Network tab for failed requests
4. Verify server returns correct JSON format

### CORS Errors in Browser

**Problem**: Cross-origin request blocked

**Fix**: OCR server must enable CORS headers
```python
# In Flask app
from flask_cors import CORS
CORS(app)
```

---

## 📁 New Files Added

```
lib/
├── utils/
│   └── mock_image_generator.dart    # ✨ NEW - Generates test images
├── services/
│   ├── ocr_backend_service.dart     # Updated with better text processing
│   └── esp32_camera_service.dart    # Unchanged (still disabled)
├── widgets/
│   └── ocr_status_widget.dart       # ✨ NEW - Shows connection status
└── providers/
    └── smart_pen_provider.dart      # Updated with OCR integration
```

---

## 🔮 Next Steps

### Current State
✅ Mock images generated from strokes  
✅ Images sent to OCR server via HTTP  
✅ Text received and processed  
✅ Text simplified for dyslexic users  
✅ Definitions generated  
✅ Full UI integration  

### Future Integration (ESP32-CAM)
When you're ready to use real camera:

1. Change flag: `enableEsp32Integration = true`
2. Configure ESP32 IP in `network_config.dart`
3. Connect to ESP32 stream
4. Frames → OCR server → Text (same pipeline)

The infrastructure is ready, just swap mock images for real camera frames!

---

## 💡 Key Points

1. **OCR Server is External** - Not part of Flutter project
2. **Mock Images for Now** - Simulates ESP32-CAM frames
3. **Real API Calls** - Actual HTTP requests to server
4. **Automatic Fallback** - Uses internal mocks if server down
5. **Text Processing** - Simplification + definitions happen in Flutter
6. **Ready for Real Camera** - Just flip a switch when hardware ready

---

## 📞 Debug Commands

```bash
# Check if server is running
curl http://localhost:5000/health

# Test OCR endpoint manually
curl -X POST -F "image=@test.jpg" http://localhost:5000/extract-text

# Check Flutter logs
flutter run -d chrome -v

# View server logs
# (should see incoming requests when you click test button)
```

---

## ✅ Success Indicators

You know it's working when:

1. ✅ Green status indicator in app
2. ✅ Server logs show: `POST /extract-text`
3. ✅ Text appears in recognition widget
4. ✅ Simplified version shows below original
5. ✅ Definitions appear for keywords
6. ✅ Confidence score shows 85-99%

---

**Ready to test!** Start the OCR server, run the Flutter app, and click "Send Mock Image to OCR" 🚀
