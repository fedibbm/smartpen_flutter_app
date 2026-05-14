# LexiPal (DyslexiPen Reader)

A Flutter mobile application that helps **dyslexic readers** by recognizing handwritten text from smart pens (or cameras) and providing **reading assistance** through text simplification, definitions, translation, and text-to-speech.

---

## The Problem

Dyslexia affects **~10-15%** of the population, making reading challenging due to difficulties with:

- **Word recognition** and decoding
- **Reading speed** and fluency
- **Comprehension** of complex text
- **Letter reversals** (b/d, p/q)
- **Spelling** and writing organization

Traditional assistive tools are either too expensive (dedicated hardware), require constant internet (cloud APIs), or lack multi-language support. Students with dyslexia need a tool that:

1. Works with **existing smart pens** or phone cameras
2. **Simplifies text** in real-time
3. **Defines complex words** without leaving the page
4. **Reads text aloud** at adjustable speeds
5. **Translates** to native languages (French/Arabic)
6. Works **offline** for core features

---

## Solution Overview

LexiPal bridges the gap between **handwriting input** and **digital reading assistance**:

```
┌──────────────┐     ┌──────────────────────┐     ┌──────────────────┐
│  Input Mode  │ ──► │  SmartPenProvider    │ ──► │   UI Widgets     │
│ (ESP32-CAM   │     │  (State Manager)     │     │ (Text/Settings)  │
│  / Phone     │     │                      │     └──────────────────┘
│  Camera      │     │  ┌────────────────┐  │
│  / Dummy)    │     │  │ OCR Backend    │──┼──► Python OpenCV Server
└──────────────┘     │  │ Service        │  │    (Azure Container)
                     │  ├────────────────┤  │
                     │  │ ML Kit Trans.  │──┼──► Google On-Device NN
                     │  ├────────────────┤  │
                     │  │ TTS Service    │──┼──► flutter_tts (OS)
                     │  ├────────────────┤  │
                     │  │ Spell Corrector│  │    100% LOCAL
                     │  │ Simple Transl. │  │    100% LOCAL
                     │  │ Image Stitching│  │    Frame panorama
                     │  └────────────────┘  │
                     └──────────────────────┘
```

The user writes on paper with a smart pen. The pen captures strokes and sends them to the app via WiFi/Bluetooth (or the phone camera captures the text). The app processes the image through OCR, corrects spelling, simplifies the text, extracts keywords with definitions, and can read everything aloud — all while offering translation to French or Arabic.

---

## Features

### ✍️ Text Capture (3 Modes)

| Mode | Description | Status |
|------|-------------|--------|
| **ESP32-CAM** | Connects to ESP32 camera module via WiFi, captures MJPEG video stream, extracts frames, stitches panoramas | ⚠️ Implemented but disabled (config flag) |
| **Phone Camera** | Uses device camera to capture frames at 200ms intervals, sends to OCR server for stitching | ✅ Active |
| **Dummy / Mock** | Generates realistic mock handwriting strokes and sample text for testing without hardware | ✅ Active |

### 🔤 OCR Pipeline

1. Image captured (single frame or frame sequence)
2. Sent to **Python OpenCV OCR Server** via HTTP multipart POST
3. Server extracts text, returns confidence score + metadata
4. **Built-in spell correction** fixes 60+ common OCR errors instantly (local)
5. Text is classified by complexity: Simple / Medium / Complex

### 📖 Reading Assistance

- **Text Simplification** — Complex sentences rewritten simply (e.g., "The phenomenon of photosynthesis" → "Plants use sunlight to make food")
- **Keyword Extraction** — Identifies important terms (words > 5 chars, top 5)
- **Definitions** — Built-in dictionary of 20+ educational terms + fallback to Free Dictionary API
- **Complexity Analysis** — Average word length determines readability level

### 🌐 Translation (Hybrid)

Two-tier translation system:

1. **Google ML Kit** (on-device neural translation, ~30MB models)
   - English → French
   - English → Arabic
   - Works **offline** after model download
2. **SimpleTranslator** (built-in fallback)
   - 40+ educational terms translated locally
   - Zero latency, no network needed
   - Word-by-word annotation mode

### 🔊 Text-to-Speech

- Powered by `flutter_tts` (platform-native TTS engines)
- 3 languages: English (en-US), French (fr-FR), Arabic (ar-SA)
- **Slow default rate** (0.5) optimized for dyslexic readers
- Configurable: Speed (0.1–1.0), Pitch (0.5–2.0), Volume (0–100%)
- Auto-play option for newly recognized text

### ♿ Accessibility

- High contrast mode toggle
- Large font size option
- Auto-simplify text on/off
- Show/hide definitions
- Keyword highlighting
- Learning difficulty profile (letter reversals, comprehension, etc.)

### 📱 User Experience

- **Onboarding** — 3-page intro for first-time users
- **Authentication** — Email/password login or signup with parent/guardian email
- **Email Verification** — 6-digit code verification flow
- **User Profile** — Name, age, school, reading level, font preference, learning challenges
- **Scan History** — Persistent log of all recognized texts with confidence, word/char count, copy/share
- **Parent Notifications** — Session interruptions, daily progress, weekly summaries, milestone achievements

---

## Architecture

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.7+, Dart |
| **State Management** | Provider (`ChangeNotifier`) |
| **OCR Backend** | Python (OpenCV) — deployed on Azure Container Instance |
| **On-Device Translation** | Google ML Kit (`google_mlkit_translation`) |
| **Text-to-Speech** | `flutter_tts` (platform native TTS) |
| **Camera** | `camera` package (phone) + custom HTTP streaming (ESP32) |
| **Image Processing** | `image` Dart package (stitching, decoding) |
| **Networking** | `http` package + `connectivity_plus` |
| **Storage** | `shared_preferences` (onboarding state, auth) |
| **Permissions** | `permission_handler` |
| **Animations** | `lottie`, `animated_text_kit`, `flutter_svg` |

### Project Structure

```
lib/
├── main.dart                          # App entry, routing, theme
│
├── config/
│   ├── device_config.dart             # Feature flags, ESP32 settings, thresholds
│   └── network_config.dart            # All URLs, endpoints, timeouts
│
├── models/
│   └── smart_pen_models.dart          # SmartPenDevice, RecognizedText, PenStroke, enums
│
├── providers/
│   └── smart_pen_provider.dart        # Central state: connection, recognition, scanning, TTS, camera
│
├── screens/
│   ├── onboarding_screen.dart         # 3-page intro with SVG illustrations
│   ├── auth_screen.dart               # Login/signup with parent email field
│   ├── email_verification_screen.dart # 6-digit code verification
│   ├── main_navigation_screen.dart    # 4-tab bottom navigation shell
│   ├── home_screen.dart               # Scan controls, latest text, device list, accessibility
│   ├── scan_history_screen.dart       # All recognized texts with metadata
│   ├── user_profile_screen.dart       # Editable profile, reading preferences
│   ├── accessibility_settings_screen.dart  # Visual, reading, camera, TTS, parent notifications
│   ├── phone_camera_screen.dart       # Live camera with capture overlay
│   └── model_download_screen.dart     # Download/delete ML Kit translation models
│
├── services/
│   ├── ocr_backend_service.dart       # HTTP client for Python OCR server (single + stitch)
│   ├── online_translation_service.dart # Google ML Kit on-device translator
│   ├── hybrid_translation_service.dart # ML Kit fallback chain
│   ├── dictionary_service.dart        # Free Dictionary API client
│   ├── text_to_speech_service.dart    # flutter_tts wrapper with callbacks
│   ├── esp32_camera_service.dart      # ESP32-CAM MJPEG stream parser
│   ├── phone_camera_service.dart      # Camera frame capture service
│   └── image_stitching_service.dart   # Frame panorama stitching (pixel overlap)
│
├── utils/
│   ├── spell_corrector.dart           # 60+ OCR spelling corrections (local)
│   ├── simple_translator.dart         # 40+ educational terms en→fr/ar (local)
│   └── mock_image_generator.dart      # Test image generation from strokes/text
│
└── widgets/
    ├── connection_status_widget.dart   # Connection indicator with battery/signal
    ├── device_list_widget.dart         # Smart pen scan list
    ├── drawing_canvas.dart            # CustomPaint stroke visualization
    ├── text_recognition_widget.dart   # Main text display: simplified, translation, definitions, TTS
    ├── recognized_text_widget.dart    # Alternative text display (expansion tiles)
    ├── ocr_status_widget.dart         # OCR server health indicator
    └── translation_widget.dart        # Language selector + word-by-word view
```

---

## Data Models

### `SmartPenDevice`
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier |
| `name` | `String` | Display name (e.g., "DyslexiPen Pro WiFi") |
| `type` | `ConnectionType` | `wifi` or `bluetooth` |
| `batteryLevel` | `int` | 0–100 |
| `signalStrength` | `double` | 0.0–1.0 |

### `RecognizedText`
| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Timestamp-based unique ID |
| `originalText` | `String` | Raw OCR output (spell-corrected) |
| `simplifiedText` | `String` | Simplified version for dyslexic readers |
| `keyWords` | `List<String>` | Extracted important terms |
| `complexity` | `TextComplexity` | `simple` / `medium` / `complex` |
| `confidence` | `double` | OCR confidence 0.0–1.0 |
| `timestamp` | `DateTime` | When text was recognized |
| `definitions` | `List<String>` | Word definitions |

### `PenStroke`
| Field | Type | Description |
|-------|------|-------------|
| `points` | `List<Offset>` | Coordinate points |
| `timestamp` | `DateTime` | When stroke was made |
| `isProcessed` | `bool` | Whether OCR has been run |
| `strokeWidth` | `double` | Pen thickness |
| `color` | `Color` | Ink color |

### Enums
| Enum | Values | Purpose |
|------|--------|---------|
| `ConnectionType` | `wifi`, `bluetooth` | Smart pen connectivity |
| `ConnectionStatus` | `disconnected`, `connecting`, `connected`, `error` | Connection lifecycle |
| `RecognitionStatus` | `idle`, `processing`, `completed`, `error` | OCR lifecycle |
| `TextComplexity` | `simple`, `medium`, `complex` | Readability level |
| `CameraMode` | `esp32`, `phoneCamera`, `dummy` | Input source |
| `TtsState` | `playing`, `stopped`, `paused`, `continued` | TTS lifecycle |
| `ModelDownloadStatus` | `notStarted`, `downloading`, `downloaded`, `error` | ML Kit model lifecycle |

---

## Services (Detailed)

### 1. OCR Backend Service (`ocr_backend_service.dart`)

Communicates with a **Python OpenCV server** deployed on Azure Container Instance.

**Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/ocr` | POST | Single image OCR (multipart form) |
| `/ocr-stitch` | POST | Multiple frames → server stitches → OCR |
| `/health` | GET | Server health check |

**Server URL:** `http://ocr-demo-enit.francecentral.azurecontainer.io:5000`

**Features:**
- 3 retry attempts with 2s delay between failures
- 10s connection timeout, 30s read timeout
- Batch processing support (`extractTextBatch`)
- Parses OcrResponse: `{ text, confidence, success, error, timestamp, metadata }`
- Built-in text simplification dictionary (20+ word mappings)
- Built-in definition generator (20+ educational terms)

### 2. Online Translation Service (`online_translation_service.dart`)

Google ML Kit on-device neural machine translation. **No API key required.**

- Model size: ~30–40 MB per language
- Model management: download, check status, delete (via `ModelDownloadScreen`)
- Pre-download on startup: English, French, Arabic
- 3-minute download timeout with periodic status checks
- Falls back gracefully on timeout (model may have downloaded despite the error)
- Supports 50+ languages via `TranslateLanguage` enum

### 3. Hybrid Translation Service (`hybrid_translation_service.dart`)

Abstraction layer that chains:
1. Google ML Kit (on-device, best quality, offline)
2. Offline static definitions (built-in dictionary)
3. Free Dictionary API (online, rich definitions)

### 4. Dictionary Service (`dictionary_service.dart`)

Client for the **Free Dictionary API** (`api.dictionaryapi.dev`):
- Fetches definitions, phonetics, examples, synonyms, parts of speech
- Simple summary (dyslexic-friendly) vs detailed explanation modes
- No API key required
- Supports English and French

### 5. TTS Service (`text_to_speech_service.dart`)

Wrapper around `flutter_tts`:
- Initialize with callback handlers (start, complete, cancel, pause, continue, error)
- Loads available voices grouped by language
- Default speech rate: 0.5 (slower for dyslexia)
- Language mapping: `en` → `en-US`, `fr` → `fr-FR`, `ar` → `ar-SA`

### 6. ESP32-CAM Service (`esp32_camera_service.dart`)

HTTP client for ESP32-CAM module:
- MJPEG stream parsing (JPEG start/end marker detection)
- Frame capture on demand
- Frame sequence capture (configurable count + interval)
- Connection health monitoring (5s interval)
- ⚠️ Currently **disabled** via `DeviceConfig.enableEsp32Integration = false`

### 7. Phone Camera Service (`phone_camera_service.dart`)

Wraps the `camera` package:
- Initializes back camera at medium resolution
- Captures JPEG frames at 200ms intervals
- Frame buffer management (start/stop, get-and-clear)
- Front/back camera switching
- No audio recording during capture

### 8. Image Stitching Service (`image_stitching_service.dart`)

Stitches multiple frames into a **panoramic image** before OCR:
- Decodes frames using `image` Dart package
- Overlap detection via pixel similarity scoring (samples every 5th pixel)
- Alpha blending in overlap regions
- Fallback to single frame if only one frame provided

---

## Built-in Utilities (100% Local, Zero Network)

### Spell Corrector (`spell_corrector.dart`)
- 60+ common OCR errors corrected instantly
- Categories: photosynthesis, mitochondria, democracy, government, environment variations + common typos (teh, recieve, beleive, etc.)
- Preserves original capitalization (ALL CAPS, Title Case, lowercase)
- Returns list of corrections with positions for UI display

### Simple Translator (`simple_translator.dart`)
- 40+ educational terms: English → French, English → Arabic
- Word-by-word annotation with translation pairs
- RTL support for Arabic
- Supports `translate()` (full text) and `translateWithAnnotations()` (word-by-word)

### Mock Image Generator (`mock_image_generator.dart`)
- `generateFromStrokes()` — Renders stroke points as PNG
- `generatePlaceholder()` — Sin-wave mock handwriting lines
- `generateFromText()` — Renders text string as PNG image

---

## Configuration

### `device_config.dart`
```dart
enableEsp32Integration: false    // ESP32-CAM disabled
enableMockMode: true              // Mock data during development
enableOcrBackend: true            // Real OCR service active
enableTextProcessing: true        // Translation & correction active
imageCompressionQuality: 85       // JPEG quality
maxImageSizeBytes: 5MB            // Max upload size
```

### `network_config.dart`
```dart
OCR Server:       http://ocr-demo-enit.francecentral.azurecontainer.io:5000
LibreTranslate:   https://libretranslate.com
Dictionary API:   https://api.dictionaryapi.dev
ESP32-CAM:        http://192.168.1.100 (placeholder)
Timeouts:         10s connect, 30s read
Max Retries:      3
```

---

## Deployment Requirements

### Server (must be running)
```
Python OpenCV OCR Server at port 5000
  - /ocr          (POST) - Single image OCR
  - /ocr-stitch   (POST) - Multi-frame stitch + OCR
  - /health       (GET)  - Health check
```

### No Server Needed (built into app)
- Spell correction ❌
- Basic translation (40+ words) ❌
- Text simplification ❌
- Word definitions (offline subset) ❌
- TTS ❌

### Optional (enhanced experience)
- Google ML Kit models (downloaded on-device, ~30MB each)
- Internet for Free Dictionary API (rich definitions)
- Internet for LibreTranslate (full translation)

---

## Current Status

- ✅ Core reading assistance workflow complete
- ✅ Phone camera capture + OCR pipeline active
- ✅ Built-in spell correction and basic translation
- ✅ Google ML Kit on-device translation (model management UI ready)
- ✅ TTS with 3 languages and full parameter control
- ✅ Scan history with confidence scoring
- ✅ Accessibility settings (visual + reading + TTS)
- ✅ Authentication flow (onboarding → login/signup → email verification → home)
- ✅ User profile with learning difficulty tracking
- ✅ Parent notification preferences
- ⚠️ ESP32-CAM integration implemented but disabled (needs hardware)
- ⚠️ OCR server required for real text recognition (falls back to mock)
- ⚠️ LibreTranslate integration ready but not connected (translation uses ML Kit/mock)

---

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on web
flutter run -d chrome
```

The app starts with an onboarding flow (first launch only), then authentication, then the main home screen. In mock mode, all features work without any hardware or external server.
