import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_pen_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../services/text_to_speech_service.dart';
import '../l10n/app_localizations.dart';

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

  Widget _buildLangButton(LocaleProvider provider, String code, String label) {
    final isActive = provider.locale == code;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => provider.setLocale(code),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.indigo : Colors.grey.shade200,
          foregroundColor: isActive ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('accessibilitySettings')),
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
                        context.tr('visualAccessibility'),
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
                    title: Text(context.tr('highContrastMode')),
                    subtitle: Text(context.tr('highContrastSubtitle')),
                    value: _highContrastMode,
                    onChanged: (value) {
                      setState(() {
                        _highContrastMode = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: Text(context.tr('largeFontSize')),
                    subtitle: Text(context.tr('largeFontSubtitle')),
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
          
          // App Language
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language, color: Colors.indigo.shade700),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('appLanguage'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('appLanguageSubtitle'),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildLangButton(localeProvider, 'en', '🇬🇧 ${context.tr('english')}'),
                          const SizedBox(width: 8),
                          _buildLangButton(localeProvider, 'fr', '🇫🇷 ${context.tr('french')}'),
                          const SizedBox(width: 8),
                          _buildLangButton(localeProvider, 'ar', '🇸🇦 ${context.tr('arabic')}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
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
                        context.tr('readingAssistance'),
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
                    title: Text(context.tr('autoSimplifyText')),
                    subtitle: Text(context.tr('autoSimplifySubtitle')),
                    value: _autoSimplifyText,
                    onChanged: (value) {
                      setState(() {
                        _autoSimplifyText = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: Text(context.tr('showDefinitions')),
                    subtitle: Text(context.tr('showDefinitionsSubtitle')),
                    value: _showDefinitions,
                    onChanged: (value) {
                      setState(() {
                        _showDefinitions = value;
                      });
                    },
                  ),
                  
                  SwitchListTile(
                    title: Text(context.tr('highlightKeywords')),
                    subtitle: Text(context.tr('highlightKeywordsSubtitle')),
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
                            context.tr('cameraMode'),
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
                        title: Text(context.tr('esp32Cam')),
                        subtitle: Text(context.tr('esp32CamSubtitle')),
                        value: CameraMode.esp32,
                        groupValue: provider.cameraMode,
                        onChanged: (value) {
                          if (value != null) {
                            provider.setCameraMode(value);
                          }
                        },
                      ),
                      
                      RadioListTile<CameraMode>(
                        title: Text(context.tr('phoneCamera')),
                        subtitle: Text(
                          provider.phoneCameraInitialized 
                              ? context.tr('ready') 
                              : context.tr('tapToInitialize'),
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
                        context.tr('cameraModeDescription'),
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
                            context.tr('textToSpeech'),
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
                        title: Text(context.tr('enableTts')),
                        subtitle: Text(context.tr('enableTtsSubtitle')),
                        value: provider.ttsEnabled,
                        onChanged: (value) {
                          provider.toggleTtsEnabled();
                        },
                      ),
                      
                      // Auto-play toggle
                      SwitchListTile(
                        title: Text(context.tr('autoPlay')),
                        subtitle: Text(context.tr('autoPlaySubtitle')),
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
                            Text(
                              context.tr('language'),
                              style: const TextStyle(
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
                              items: [
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('🇬🇧 ${context.tr('english')}'),
                                ),
                                DropdownMenuItem(
                                  value: 'fr',
                                  child: Text('🇫🇷 ${context.tr('french')}'),
                                ),
                                DropdownMenuItem(
                                  value: 'ar',
                                  child: Text('🇸🇦 ${context.tr('arabic')}'),
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
                            Text(
                              context.tr('speed'),
                              style: const TextStyle(
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
                            Text(
                              context.tr('pitch'),
                              style: const TextStyle(
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
                            Text(
                              context.tr('volume'),
                              style: const TextStyle(
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
                                    'en': context.tr('ttsTestEn'),
                                    'fr': context.tr('ttsTestFr'),
                                    'ar': context.tr('ttsTestAr'),
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
                                ? context.tr('stopTest')
                                : context.tr('testVoice'),
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
          
          // Notification Preferences
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              return Card(
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
                            context.tr('parentNotifications'),
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
                        title: Text(context.tr('sessionInterruptions')),
                        subtitle: Text(context.tr('sessionInterruptionsSubtitle')),
                        value: notifProvider.sessionInterruptions,
                        onChanged: (value) => notifProvider.setSessionInterruptions(value),
                      ),
                      
                      SwitchListTile(
                        title: Text(context.tr('dailyProgressReports')),
                        subtitle: Text(context.tr('dailyProgressSubtitle')),
                        value: notifProvider.dailyProgressReports,
                        onChanged: (value) => notifProvider.setDailyProgressReports(value),
                      ),
                      
                      SwitchListTile(
                        title: Text(context.tr('weeklySummaries')),
                        subtitle: Text(context.tr('weeklySummariesSubtitle')),
                        value: notifProvider.weeklySummaries,
                        onChanged: (value) => notifProvider.setWeeklySummaries(value),
                      ),
                      
                      SwitchListTile(
                        title: Text(context.tr('milestoneAchievements')),
                        subtitle: Text(context.tr('milestoneAchievementsSubtitle')),
                        value: notifProvider.milestoneAchievements,
                        onChanged: (value) => notifProvider.setMilestoneAchievements(value),
                      ),
                      
                      SwitchListTile(
                        title: Text(context.tr('lowEngagementAlerts')),
                        subtitle: Text(context.tr('lowEngagementSubtitle')),
                        value: notifProvider.lowEngagementAlerts,
                        onChanged: (value) => notifProvider.setLowEngagementAlerts(value),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                        context.tr('support'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    context.tr('supportDescription'),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('openingTutorial')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.school),
                          label: Text(context.tr('tutorial')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('openingHelpCenter')),
                              ),
                            );
                          },
                          icon: const Icon(Icons.support),
                          label: Text(context.tr('help')),
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
                  SnackBar(
                    content: Text(context.tr('settingsSaved')),
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
              child: Text(
                context.tr('saveSettings'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    title: Text(context.tr('logout')),
                    content: Text(context.tr('logoutConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.tr('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          // Clear user session
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/auth',
                            (route) => false,
                          );
                        },
                        child: Text(
                          context.tr('logout'),
                          style: const TextStyle(color: Colors.red),
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
              label: Text(
                context.tr('logout'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
