import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_verification_screen.dart';
import '../services/user_preferences_service.dart';
import '../l10n/app_localizations.dart';

/// Login/Signup screen shown after onboarding
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        
        if (_isLogin) {
          // Login - check if user exists
          final savedEmail = prefs.getString('user_email');
          final savedPassword = prefs.getString('user_password');
          
          if (savedEmail == _emailController.text && 
              savedPassword == _passwordController.text) {
            // Login successful
            await prefs.setBool('is_logged_in', true);
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // Login failed
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('invalidEmailPassword')),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Sign up - check if email already exists
          final savedEmail = prefs.getString('user_email');
          
          if (savedEmail == _emailController.text) {
            // Email already registered
            setState(() {
              _isLoading = false;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('emailAlreadyRegistered')),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            // Sign up successful - save credentials and user profile
            await prefs.setString('user_email', _emailController.text);
            await prefs.setString('user_password', _passwordController.text);
            await prefs.setString('user_name', _nameController.text);
            await prefs.setBool('is_logged_in', true);
            
            // Save parent email for notifications
            final userPrefs = UserPreferencesService();
            await userPrefs.saveChildName(_nameController.text);
            await userPrefs.saveParentEmail(_parentEmailController.text);
            
            setState(() {
              _isLoading = false;
            });
            
            // Show success message and go to home
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('accountCreated')),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pushReplacementNamed('/home');
            }
          }
        }
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.edit_note,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Name
                  Text(
                    'LexiPal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isLogin ? context.tr('welcomeBack') : context.tr('createAccount'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isLogin
                        ? context.tr('signInToContinue')
                        : context.tr('startReadingJourney'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Name field (only for signup)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: context.tr('fullName'),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.isEmpty)) {
                          return context.tr('pleaseEnterName');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        labelText: context.tr('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('pleaseEnterEmail');
                      }
                      if (!value.contains('@')) {
                        return context.tr('validEmailRequired');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Parent Email field (only for signup)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _parentEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.tr('parentEmail'),
                        prefixIcon: const Icon(Icons.supervisor_account),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        helperText: context.tr('parentEmailHelper'),
                        helperMaxLines: 2,
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.isEmpty)) {
                          return context.tr('pleaseEnterEmail');
                        }
                        if (!_isLogin && !value!.contains('@')) {
                          return context.tr('validEmailRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                        labelText: context.tr('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('pleaseEnterPassword');
                      }
                      if (value.length < 6) {
                        return context.tr('passwordMinLength');
                      }
                      return null;
                    },
                  ),

                  // Forgot password (only for login)
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('passwordResetComingSoon')),
                            ),
                          );
                        },
                        child: Text(
                          context.tr('forgotPassword'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? context.tr('signIn') : context.tr('signUp'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.tr('or'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social login buttons
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('googleSignInComingSoon')),
                        ),
                      );
                    },
                    icon: Icon(Icons.g_mobiledata, color: Colors.grey[700]),
                    label: Text(
                      context.tr('continueWithGoogle'),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('facebookSignInComingSoon')),
                        ),
                      );
                    },
                    icon: Icon(Icons.facebook, color: Colors.grey[700]),
                    label: Text(
                      context.tr('continueWithFacebook'),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle between login and signup
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? context.tr('dontHaveAccount')
                            : context.tr('alreadyHaveAccount'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          _isLogin ? context.tr('signUp') : context.tr('signIn'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Skip for now button
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_logged_in', false);
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                    child: Text(
                      context.tr('skipForNow'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
