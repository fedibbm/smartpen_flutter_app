import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/smart_pen_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'services/email_service.dart';
import 'services/user_preferences_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  
  runApp(SmartPenApp(
    showOnboarding: !hasCompletedOnboarding,
    isLoggedIn: isLoggedIn,
  ));
}

class SmartPenApp extends StatefulWidget {
  final bool showOnboarding;
  final bool isLoggedIn;
  
  const SmartPenApp({
    super.key,
    required this.showOnboarding,
    required this.isLoggedIn,
  });

  @override
  State<SmartPenApp> createState() => _SmartPenAppState();
}

class _SmartPenAppState extends State<SmartPenApp> with WidgetsBindingObserver {
  final EmailService _emailService = EmailService();
  final UserPreferencesService _prefsService = UserPreferencesService();
  final LocaleProvider _localeProvider = LocaleProvider();
  final NotificationProvider _notificationProvider = NotificationProvider();
  final NotificationService _notificationService = NotificationService();
  bool _hasNotifiedExit = false;
  bool _localeLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _localeProvider.loadLocale();
    await _notificationService.initialize();
    await _notificationProvider.loadPreferences();
    if (mounted) {
      setState(() {
        _localeLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (!_hasNotifiedExit) {
        _sendAppExitNotification();
        _notificationProvider.onSessionInterrupted('Child');
        _hasNotifiedExit = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      _hasNotifiedExit = false;
      _notificationProvider.onAppForegrounded();
    }
  }

  Future<void> _sendAppExitNotification() async {
    try {
      // Check if email notifications are enabled
      final notificationsEnabled = await _prefsService.areEmailNotificationsEnabled();
      if (!notificationsEnabled) {
        debugPrint('📧 Email notifications disabled - skipping');
        return;
      }

      // Check if profile is complete
      final profileComplete = await _prefsService.isProfileComplete();
      if (!profileComplete) {
        debugPrint('📧 User profile incomplete - skipping email notification');
        return;
      }

      // Get user info
      final parentEmail = await _prefsService.getParentEmail();
      final childName = await _prefsService.getChildName();

      if (parentEmail != null && childName != null) {
        debugPrint('📧 Sending app exit notification to $parentEmail');
        
        // Send email asynchronously (don't wait for completion)
        _emailService.sendAppExitNotification(
          parentEmail: parentEmail,
          childName: childName,
          exitTime: DateTime.now(),
        ).then((success) {
          if (success) {
            debugPrint('✅ Exit notification sent successfully');
          } else {
            debugPrint('❌ Failed to send exit notification');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error in app exit notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ChangeNotifierProvider.value(
      value: _localeProvider,
      child: ChangeNotifierProvider.value(
        value: _notificationProvider,
        child: ChangeNotifierProvider(
          create: (context) => SmartPenProvider(
            notificationProvider: _notificationProvider,
          ),
          child: MaterialApp(
          title: 'LexiPal',
          debugShowCheckedModeBanner: false,
          locale: Locale(_localeProvider.locale),
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9142CF),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            cardTheme: CardTheme(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          initialRoute: widget.showOnboarding
              ? '/onboarding'
              : widget.isLoggedIn
                  ? '/home'
                  : '/auth',
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/auth': (context) => const AuthScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
        ),
      ),
      ),
    );
  }
}


