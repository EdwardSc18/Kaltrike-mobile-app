import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kaltrike_driver_app/src/features/commuter/auth/presentation/screens/signup_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/progress_dialog.dart';
import 'package:kaltrike_driver_app/src/features/commuter/auth/presentation/screens/auth_loading_screen.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';

import '../../../../../shared/ui/widgets/kal_surface_card.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  bool _secureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    super.dispose();
  }

  // Load saved credentials if Remember Me was enabled
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      final savedPassword = prefs.getString('saved_password');
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
        });
      }

      if (rememberMe && savedEmail != null && savedPassword != null) {
        if (mounted) {
          setState(() {
            emailTextEditingController.text = savedEmail;
            passwordTextEditingController.text = savedPassword;
          });
        }
      }
    } catch (error) {
      print('Error loading saved credentials: $error');
    }
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', emailTextEditingController.text.trim());
        await prefs.setString('saved_password', passwordTextEditingController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (error) {
      print('Error saving credentials: $error');
    }
  }

  // Clear saved credentials
  Future<void> _clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    } catch (error) {
      print('Error clearing credentials: $error');
    }
  }

  // Enhanced error handling for Firebase Auth exceptions
  String _getUserFriendlyErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return "The email address is not valid. Please check your email format.";
      case 'user-disabled':
        return "This account has been disabled. Please contact support.";
      case 'user-not-found':
        return "No account found with this email. Please check your email or sign up.";
      case 'wrong-password':
        return "Incorrect password. Please try again or reset your password.";
      case 'too-many-requests':
        return "Too many failed login attempts. Please try again later or reset your password.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection and try again.";
      case 'invalid-credential':
        return "Invalid login credentials. Please check your email and password.";
      case 'operation-not-allowed':
        return "Email/password sign-in is not enabled. Please contact support.";
      default:
        return "An unexpected error occurred. Please try again. (Error: ${error.code})";
    }
  }

  // Enhanced error handling for general exceptions
  String _getGeneralErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getUserFriendlyErrorMessage(error);
    } else if (error is TimeoutException) {
      return "Request timed out. Please check your connection and try again.";
    } else if (error.toString().contains('socket') ||
        error.toString().contains('network') ||
        error.toString().contains('Connection')) {
      return "Network connection failed. Please check your internet and try again.";
    } else if (error is FirebaseException) {
      return "Database error: ${error.message ?? 'Please try again.'}";
    } else {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // Enhanced form validation with better error messages
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email address is required";
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return "Please enter a valid email address";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  void validateForm() {
    if (_isLoading) return; // Prevent multiple simultaneous login attempts

    if (!_formKey.currentState!.validate()) {
      return;
    }

    loginUserNow();
  }

  // Enhanced toast notification with better styling
  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green[700],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showInfoToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue[700],
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<void> loginUserNow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return const ProgressDialog(
          message: "Signing you in...",
        );
      },
    );

    try {
      final UserCredential userCredential = await fAuth
          .signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      ).timeout(const Duration(seconds: 30));

      if (userCredential.user != null) {
        await userCredential.user!.getIdToken(true);
        await _saveCredentials();

        if (mounted) {
          Navigator.pop(context);
        }

        setState(() {
          _isLoading = false;
        });

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AuthLoadingScreen(firebaseUser: userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) Navigator.pop(context);
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(_getUserFriendlyErrorMessage(error));
    } on TimeoutException catch (_) {
      if (mounted) Navigator.pop(context);
      setState(() {
        _isLoading = false;
      });
      _showErrorToast("Login timeout. Please check your connection and try again.");
    } catch (error) {
      if (mounted) Navigator.pop(context);
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(_getGeneralErrorMessage(error));
    }
  }

  // Enhanced Forgot Password Function
  Future<void> _resetPassword() async {
    final email = emailTextEditingController.text.trim();
    final emailError = _validateEmail(email);

    if (emailError != null) {
      _showErrorToast("Please enter a valid email address to reset your password.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(
          message: "Sending reset instructions...",
        );
      },
    );

    try {
      await fAuth.sendPasswordResetEmail(email: email).timeout(const Duration(seconds: 30));

      if (mounted) Navigator.pop(context); // Close progress dialog
      _showInfoToast("Password reset instructions sent! Check your email inbox and spam folder.");
    } on FirebaseAuthException catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      if (error.code == 'user-not-found') {
        _showErrorToast("No account found with this email address.");
      } else {
        _showErrorToast("Failed to send reset email: ${_getUserFriendlyErrorMessage(error)}");
      }
    } on TimeoutException catch (_) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      _showErrorToast("Request timed out. Please check your connection and try again.");
    } catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      _showErrorToast("Failed to send reset email. Please try again.");
    }
  }

  // Enhanced forgot password dialog
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Reset Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your email address and we'll send you a password reset link.",
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email Address",
                  hintText: "example@gmail.com",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: _validateEmail,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: KalPrimaryButton(
                label: 'Send Reset Link',
                onPressed: () {
                  if (_validateEmail(emailTextEditingController.text) == null) {
                    Navigator.pop(context);
                    _resetPassword();
                  } else {
                    _showErrorToast("Please enter a valid email address");
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double headerHeight =
    (size.height * 0.30).clamp(220.0, 300.0).toDouble();
    final double logoSize =
    (size.width * 0.24).clamp(80.0, 110.0).toDouble();
    final double titleSize =
    (size.width * 0.08).clamp(26.0, 32.0).toDouble();
    final double subtitleSize =
    (size.width * 0.041).clamp(14.0, 16.0).toDouble();
    final double pageGap =
    (size.height * 0.035).clamp(24.0, 40.0).toDouble();
    final double horizontalMargin =
    (size.width * 0.06).clamp(16.0, 28.0).toDouble();
    final double cardPadding =
    (size.width * 0.08).clamp(20.0, 32.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Modern Gradient Header
              Container(
                height: headerHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A), // Deep navy blue
                      Color(0xFF2563EB), // Vibrant blue
                      Color(0xFF60A5FA), // Light blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade900.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "images/Logo.png",
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_bus_rounded,
                                size: 40,
                                color: Colors.blue.shade800,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: pageGap * 0.5),
                      Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: titleSize,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to book your ride",
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: pageGap),

              // Modern Login Form Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                child: KalSurfaceCard(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    children: [
                      // Email Field with enhanced validation
                      TextFormField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          hintText: "example@gmail.com",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.email_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                        ),
                        validator: _validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 20),

                      // Password Field with enhanced validation
                      TextFormField(
                        controller: passwordTextEditingController,
                        obscureText: _secureText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Enter your password",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.lock_rounded,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _secureText
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.grey.shade600,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _secureText = !_secureText;
                              });
                            },
                          ),
                        ),
                        validator: _validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),

                      const SizedBox(height: 16),

                      // Remember Me and Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Remember Me Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: _isLoading
                                    ? null
                                    : (bool? value) {
                                  if (value != null) {
                                    setState(() {
                                      _rememberMe = value;
                                    });
                                    // If unchecking, clear saved credentials
                                    if (!value) {
                                      _clearCredentials();
                                    }
                                  }
                                },
                                activeColor: const Color(0xFF2563EB),
                                checkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                  if (!_rememberMe) {
                                    _clearCredentials();
                                  }
                                },
                                child: Text(
                                  "Remember Me",
                                  style: TextStyle(
                                    color: _isLoading ? Colors.grey : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Forgot Password
                          GestureDetector(
                            onTap: _isLoading ? null : _showForgotPasswordDialog,
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: _isLoading ? Colors.grey : const Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Login Button with loading state
                      SizedBox(
                        width: double.infinity,
                        child: KalPrimaryButton(
                          label: 'Login to Ride',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : validateForm,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Sign Up Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign Up",
                              style: TextStyle(
                                color: _isLoading ? Colors.grey : const Color(0xFF2563EB),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Footer Branding
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Kaltrike Commuter",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
