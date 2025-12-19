import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_pen_provider.dart';
import '../services/text_to_speech_service.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  bool _highContrastMode = false;
  bool _largeFontSize = false;
  bool _autoSimplifyText = true;
  bool _showDefinitions = true;
  bool _highlightKeywords = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Visual Accessibility
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Visual Accessibility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('High Contrast Mode'),
                    subtitle: const Text('Increase contrast for better readability'),
                    value: _highContrastMode,
                    onChanged: (value) {
                      setState(() {
                        _highContrastMode = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Large Font Size'),
                    subtitle: const Text('Use larger text throughout the app'),
                    value: _largeFontSize,
                    onChanged: (value) {
                      setState(() {
                        _largeFontSize = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reading Assistance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Reading Assistance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Auto-Simplify Text'),
                    subtitle: const Text('Automatically show simplified versions of complex text'),
                    value: _autoSimplifyText,
                    onChanged: (value) {
                      setState(() {
                        _autoSimplifyText = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Show Definitions'),
                    subtitle: const Text('Display word definitions automatically'),
                    value: _showDefinitions,
                    onChanged: (value) {
                      setState(() {
                        _showDefinitions = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Highlight Keywords'),
                    subtitle: const Text('Emphasize important words in text'),
                    value: _highlightKeywords,
                    onChanged: (value) {
                      setState(() {
                        _highlightKeywords = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Camera Mode Settings
          Consumer<SmartPenProvider>(
            builder: (context, provider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Camera Mode',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Camera mode selection
                      RadioListTile<CameraMode>(
                        title: const Text('ESP32-CAM (Smart Pen)'),
                        subtitle: const Text('Connect smart pen for text scanning'),
                        value: CameraMode.esp32,
                        groupValue: provider.cameraMode,
                        onChanged: (value) {
                          if (value != null) {
                            provider.setCameraMode(value);
                          }
                        },
                      ),
                      
                      RadioListTile<CameraMode>(
                        title: const Text('Phone Camera'),
                        subtitle: Text(
                          provider.phoneCameraInitialized 
                              ? '✓ Ready' 
                              : 'Tap to initialize',
                          style: TextStyle(
                            color: provider.phoneCameraInitialized 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                        ),
                        value: CameraMode.phoneCamera,
                        groupValue: provider.cameraMode,
                        onChanged: (value) {
                          if (value != null) {
                            provider.setCameraMode(value);
                          }
                        },
                      ),
                      
                      // Error display
                      if (provider.cameraError != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, 
                                  color: Colors.red.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.cameraError!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red.shade700,
                                onPressed: provider.clearCameraError,
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      Text(
                        'Select how you want to capture text for recognition.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Text-to-Speech Settings
          Consumer<SmartPenProvider>(
            builder: (context, provider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Text-to-Speech',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Enable/Disable TTS
                      SwitchListTile(
                        title: const Text('Enable Text-to-Speech'),
                        subtitle: const Text('Read text aloud when recognized'),
                        value: provider.ttsEnabled,
                        onChanged: (value) {
                          provider.toggleTtsEnabled();
                        },
                      ),
                      
                      // Auto-play toggle
                      SwitchListTile(
                        title: const Text('Auto-Play'),
                        subtitle: const Text('Automatically read new text'),
                        value: provider.ttsAutoPlay,
                        onChanged: provider.ttsEnabled
                            ? (value) {
                                provider.toggleTtsAutoPlay();
                              }
                            : null,
                      ),
                      
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // Language Selection
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Language',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: provider.ttsLanguage,
                              onChanged: provider.ttsEnabled
                                  ? (value) async {
                                      if (value != null) {
                                        await provider.setTtsLanguage(value);
                                      }
                                    }
                                  : null,
                              items: const [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('🇬🇧 English'),
                                ),
                                DropdownMenuItem(
                                  value: 'fr',
                                  child: Text('🇫🇷 French'),
                                ),
                                DropdownMenuItem(
                                  value: 'ar',
                                  child: Text('🇸🇦 Arabic'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      // Speech Rate Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.speed, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Speed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: provider.ttsSpeechRate,
                                min: 0.1,
                                max: 1.0,
                                divisions: 9,
                                label: '${(provider.ttsSpeechRate * 100).round()}%',
                                onChanged: provider.ttsEnabled
                                    ? (value) async {
                                        await provider.setTtsSpeechRate(value);
                                      }
                                    : null,
                              ),
                            ),
                            Text(
                              '${(provider.ttsSpeechRate * 100).round()}%',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      // Pitch Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Pitch',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: provider.ttsPitch,
                                min: 0.5,
                                max: 2.0,
                                divisions: 15,
                                label: provider.ttsPitch.toStringAsFixed(1),
                                onChanged: provider.ttsEnabled
                                    ? (value) async {
                                        await provider.setTtsPitch(value);
                                      }
                                    : null,
                              ),
                            ),
                            Text(
                              provider.ttsPitch.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      // Volume Slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_down, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Volume',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: provider.ttsVolume,
                                min: 0.0,
                                max: 1.0,
                                divisions: 10,
                                label: '${(provider.ttsVolume * 100).round()}%',
                                onChanged: provider.ttsEnabled
                                    ? (value) async {
                                        await provider.setTtsVolume(value);
                                      }
                                    : null,
                              ),
                            ),
                            Text(
                              '${(provider.ttsVolume * 100).round()}%',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      // Test TTS Button
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: provider.ttsEnabled
                              ? () async {
                                  final testText = {
                                    'en': 'Hello! This is a test of the text-to-speech feature.',
                                    'fr': 'Bonjour! Ceci est un test de la synthèse vocale.',
                                    'ar': 'مرحباً! هذا اختبار لميزة تحويل النص إلى كلام.',
                                  };
                                  
                                  await provider.speakText(
                                    testText[provider.ttsLanguage] ?? testText['en']!,
                                  );
                                }
                              : null,
                          icon: Icon(
                            provider.ttsState == TtsState.playing
                                ? Icons.stop
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            provider.ttsState == TtsState.playing
                                ? 'Stop Test'
                                : 'Test Voice',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Parent Notification Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Parent Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Session Interruptions'),
                    subtitle: const Text('Alert when reading session is interrupted'),
                    value: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Daily Progress Reports'),
                    subtitle: const Text('Receive daily reading activity summary'),
                    value: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Weekly Summaries'),
                    subtitle: const Text('Get weekly progress and achievement updates'),
                    value: true,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Milestone Achievements'),
                    subtitle: const Text('Notify when learning milestones are reached'),
                    value: false,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Low Engagement Alerts'),
                    subtitle: const Text('Alert if app hasn\'t been used recently'),
                    value: false,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Support Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'DyslexiPen Reader is designed to help users with dyslexia and reading difficulties. These settings can be adjusted to provide the best reading experience.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening tutorial...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.school),
                          label: const Text('Tutorial'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening help center...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.support),
                          label: const Text('Help'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Save Settings Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Clear user session
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/auth',
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
