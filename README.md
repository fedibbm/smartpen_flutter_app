# DyslexiPen Reader

A Flutter app that helps dyslexic users by recognizing handwritten text from smart pens and providing reading assistance through text simplification, definitions, and accessibility features. This is a mock implementation that demonstrates the user interface without requiring actual hardware.

## Features

- 🖊️ **Smart Pen Connectivity**: Mock WiFi and Bluetooth connectivity to smart pens
- 📝 **Text Recognition**: Simulated handwriting-to-text conversion with confidence scoring
- 🧠 **Reading Assistance**: 
  - Text simplification for complex passages
  - Word definitions and explanations
  - Keyword highlighting and extraction
  - Text complexity analysis
- 🎯 **Accessibility Features**:
  - High contrast mode support
  - Large font options
  - Text-to-speech functionality (mock)
  - Screen reader compatibility
- 📱 **Dyslexia-Friendly UI**: Clean, accessible interface following WCAG guidelines
- 🔋 **Device Management**: Battery levels, signal strength, and connection status
- 📊 **Text Processing**: Real-time analysis of text complexity and readability

## Screenshots

The app includes:
- Connection status display with device information
- Interactive drawing canvas showing mock pen input
- Device list with scan functionality
- Battery and signal strength indicators
- Clean, modern Material Design UI

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- A web browser or mobile device/emulator for testing

### Installation

1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd smartpen
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   # For web
   flutter run -d chrome
   
   # For mobile (with device/emulator connected)
   flutter run
   ```

### Development

To run in development mode with hot reload:

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── smart_pen_models.dart   # Data models for devices and strokes
├── providers/
│   └── smart_pen_provider.dart # State management for pen connectivity
├── screens/
│   └── home_screen.dart        # Main application screen
└── widgets/
    ├── connection_status_widget.dart  # Connection status display
    ├── device_list_widget.dart       # Smart pen device list
    └── drawing_canvas.dart           # Drawing canvas for pen input
```

## Mock Features

Since this is a demonstration app, all connectivity features are simulated:

- **Device Discovery**: Shows mock WiFi and Bluetooth smart pen devices
- **Connection Process**: Simulates connection delays and occasional failures
- **Drawing Input**: Generates random pen strokes to simulate real input
- **Battery/Signal**: Displays mock battery levels and signal strength
- **Device Types**: Supports both WiFi and Bluetooth pen types

## Technologies Used

- **Flutter**: Cross-platform UI toolkit
- **Provider**: State management
- **Material Design**: UI components and theming
- **Custom Painting**: Drawing canvas implementation

## Future Enhancements

When real hardware integration is needed:

- Integrate with actual smart pen APIs
- Add real WiFi/Bluetooth connectivity
- Implement pressure sensitivity
- Add ink color and stroke width controls
- Save/export drawing functionality
- Multi-device support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
