import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/splash_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/progress_dialog.dart';
import '../../../../../shared/ui/widgets/kal_surface_card.dart';
import 'login_screen.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController lastNameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController otpController = TextEditingController();

  bool _secureText = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _showOtpField = false;
  bool _isOtpVerified = false;
  bool _isSendingOtp = false;
  bool _allowPhoneEdit = false; // New flag to allow phone editing
  String _verificationId = '';
  int? _resendToken;
  final _formKey = GlobalKey<FormState>();
  Timer? _resendTimer;
  int _resendCountdown = 60;
  String _currentPhoneForOtp = ''; // Store phone number used for current OTP

  @override
  void initState() {
    super.initState();
    _setupFirebaseAuth();
  }

  @override
  void dispose() {
    nameTextEditingController.dispose();
    lastNameTextEditingController.dispose();
    emailTextEditingController.dispose();
    phoneTextEditingController.dispose();
    passwordTextEditingController.dispose();
    otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _setupFirebaseAuth() {
    fAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        print("User is signed in: ${user.uid}");
      }
    });
  }

  // Enhanced error handling for Firebase Auth exceptions
  String _getUserFriendlyErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return "The phone number format is invalid. Please enter a valid Philippine number.";
      case 'too-many-requests':
        return "Too many OTP requests. Please try again later.";
      case 'quota-exceeded':
        return "SMS quota exceeded. Please try again later.";
      case 'invalid-verification-code':
        return "Invalid OTP code. Please check and try again.";
      case 'session-expired':
        return "OTP session expired. Please request a new code.";
      case 'invalid-email':
        return "The email address is not valid. Please check your email format.";
      case 'email-already-in-use':
        return "An account already exists with this email. Please log in or use a different email.";
      case 'weak-password':
        return "Password is too weak. Please use at least 6 characters with a mix of letters and numbers.";
      case 'operation-not-allowed':
        return "Email/password accounts are not enabled. Please contact support.";
      case 'network-request-failed':
        return "Network error. Please check your internet connection and try again.";
      case 'invalid-credential':
        return "Invalid registration credentials. Please check your information.";
      case 'user-disabled':
        return "This account has been disabled. Please contact support.";
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
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "First name is required";
    }
    if (value.length < 2) {
      return "First name must be at least 2 characters";
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "First name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return "Last name is required";
    }
    if (value.length < 2) {
      return "Last name must be at least 2 characters";
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Last name can only contain letters and spaces";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required.";
    }

    // Basic email format check
    String pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$';
    RegExp regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      return "Please enter a valid Gmail address (e.g., example@gmail.com)";
    }

    return null; // valid
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number is required";
    }
    // Philippine phone number format (09XXXXXXXXX)
    if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
      return "Please enter a valid Philippine phone number (09XXXXXXXXX)";
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
    if (value.length > 50) {
      return "Password is too long (max 50 characters)";
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return "OTP is required";
    }
    if (value.length != 6) {
      return "OTP must be 6 digits";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "OTP must contain only numbers";
    }
    return null;
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
      toastLength: Toast.LENGTH_LONG,
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

  // Show dialog to confirm changing phone number
  void _showChangePhoneDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Change Phone Number?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          content: const Text(
            "Are you sure you want to change your phone number? The current OTP will be invalidated and a new one will be sent to the new number.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetOtpAndAllowPhoneEdit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("Change Number"),
            ),
          ],
        );
      },
    );
  }

  // Reset OTP state and allow phone editing
  void _resetOtpAndAllowPhoneEdit() {
    setState(() {
      _showOtpField = false;
      _isOtpVerified = false;
      _allowPhoneEdit = true;
      otpController.clear();
      _verificationId = '';
      _resendToken = null;
      _resendTimer?.cancel();
      _resendCountdown = 60;
      _currentPhoneForOtp = '';
    });
    _showInfoToast("You can now edit your phone number. Enter the correct number and send OTP again.");
  }

  // Send OTP to phone number
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showErrorToast("Please agree to the Terms of Service to continue.");
      return;
    }

    // Check if phone number has changed from previous OTP
    final currentPhone = phoneTextEditingController.text.trim();
    if (_currentPhoneForOtp.isNotEmpty && _currentPhoneForOtp != currentPhone) {
      _showInfoToast("Sending OTP to new phone number...");
    }

    setState(() {
      _isSendingOtp = true;
      _allowPhoneEdit = false; // Disable editing while sending OTP
    });

    final phoneNumber = "+63${currentPhone.substring(1)}";

    try {
      _showInfoToast("Sending OTP to $phoneNumber...");

      await fAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification on Android devices
          setState(() {
            _isOtpVerified = true;
            _currentPhoneForOtp = currentPhone;
          });
          _showSuccessToast("Phone number automatically verified!");
          _completeSignUp();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isSendingOtp = false;
            _allowPhoneEdit = true; // Allow editing if OTP sending failed
          });
          _showErrorToast(_getUserFriendlyErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _showOtpField = true;
            _isSendingOtp = false;
            _currentPhoneForOtp = currentPhone;
            _startResendTimer();
          });
          _showSuccessToast("OTP sent successfully!");
          _showInfoToast("Enter the 6-digit code sent to your phone.");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (error) {
      setState(() {
        _isSendingOtp = false;
        _allowPhoneEdit = true; // Allow editing on error
      });
      _showErrorToast(_getGeneralErrorMessage(error));
    }
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      _showErrorToast("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(
          message: "Verifying OTP...",
        );
      },
    );

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otpController.text.trim(),
      );

      await fAuth.signInWithCredential(credential);

      setState(() {
        _isOtpVerified = true;
      });

      if (mounted) Navigator.pop(context); // Close progress dialog
      _showSuccessToast("Phone number verified successfully!");
      _completeSignUp();
    } on FirebaseAuthException catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });

      // If OTP is invalid, allow phone number change
      if (error.code == 'invalid-verification-code' ||
          error.code == 'session-expired') {
        _showErrorToast(_getUserFriendlyErrorMessage(error));

        // Show option to change phone number
        Future.delayed(const Duration(milliseconds: 500), () {
          _showChangePhoneDialog();
        });
      } else {
        _showErrorToast(_getUserFriendlyErrorMessage(error));
      }
    } catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(_getGeneralErrorMessage(error));
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isSendingOtp = true;
    });

    final currentPhone = phoneTextEditingController.text.trim();
    final phoneNumber = "+63${currentPhone.substring(1)}";

    try {
      await fAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() {
            _isOtpVerified = true;
            _currentPhoneForOtp = currentPhone;
          });
          _showSuccessToast("Phone number automatically verified!");
          _completeSignUp();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isSendingOtp = false;
          });
          _showErrorToast(_getUserFriendlyErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isSendingOtp = false;
            _currentPhoneForOtp = currentPhone;
            _startResendTimer();
          });
          _showSuccessToast("New OTP sent successfully!");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
      );
    } catch (error) {
      setState(() {
        _isSendingOtp = false;
      });
      _showErrorToast(_getGeneralErrorMessage(error));
    }
  }

  // Start resend timer
  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Complete sign up after OTP verification
  Future<void> _completeSignUp() async {
    if (!_isOtpVerified) {
      _showErrorToast("Please verify your phone number first");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(
          message: "Creating your account...",
        );
      },
    );

    try {
      final UserCredential userCredential = await fAuth
          .createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      ).timeout(const Duration(seconds: 30));

      if (userCredential.user != null) {
        await _saveUserToDatabase(userCredential.user!);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(_getUserFriendlyErrorMessage(error));
    } on TimeoutException catch (_) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      _showErrorToast("Sign-up timeout. Please check your connection and try again.");
    } catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      _showErrorToast(_getGeneralErrorMessage(error));
    }
  }

  Future<void> _saveUserToDatabase(User firebaseUser) async {
    try {
      Map userMap = {
        "id": firebaseUser.uid,
        "name": nameTextEditingController.text.trim(),
        "lastName": lastNameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "password": passwordTextEditingController.text.trim(),
        "phoneVerified": true,
        "phoneVerifiedAt": DateTime.now().millisecondsSinceEpoch,
        "termsAgreed": true,
        "termsAgreedAt": DateTime.now().millisecondsSinceEpoch,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
        "updatedAt": DateTime.now().millisecondsSinceEpoch,
        "accountStatus": "active",
        "userType": "commuter",
      };

      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users");
      await userRef.child(firebaseUser.uid).set(userMap).timeout(const Duration(seconds: 15));

      currentFirebaseUser = firebaseUser;

      await fAuth.signOut();
      currentFirebaseUser = null;

      if (mounted) Navigator.pop(context); // Close progress dialog
      _showSuccessToast("Account created successfully! Please log in to continue.");

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => LoginScreen()),
              (route) => false,
        );
      }
    } on TimeoutException catch (_) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      await _safeDeleteUser(firebaseUser);
      _showErrorToast("Account creation timeout. Please try again.");
    } catch (error) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      setState(() {
        _isLoading = false;
      });
      await _safeDeleteUser(firebaseUser);
      _showErrorToast("Failed to save user data. Please try again.");
    }
  }

  Future<void> _safeDeleteUser(User? user) async {
    try {
      if (user != null) {
        await user.delete().timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Failed to delete user during cleanup: $e");
    }
  }

  void validateForm() {
    if (_isLoading || _isSendingOtp) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showErrorToast("Please agree to the Terms of Service to continue.");
      return;
    }

    if (!_showOtpField) {
      _sendOtp();
    } else if (!_isOtpVerified) {
      _verifyOtp();
    } else {
      _completeSignUp();
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Terms of Service",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Last Updated: ${DateTime.now().toString().split(' ')[0]}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Please read these terms carefully before using our services.",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildTermSection(
                  "1. Account Registration",
                  "You must provide accurate and complete information when creating an account. You are responsible for maintaining the security of your account.",
                ),
                const SizedBox(height: 12),
                _buildTermSection(
                  "2. User Responsibilities",
                  "You agree to use the service in compliance with all applicable laws and regulations. You are responsible for all activities that occur under your account.",
                ),
                const SizedBox(height: 12),
                _buildTermSection(
                  "3. Privacy",
                  "Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your personal information.",
                ),
                const SizedBox(height: 12),
                _buildTermSection(
                  "4. Service Usage",
                  "You agree not to misuse the service or help anyone else do so. This includes not engaging in illegal activities or violating others' rights.",
                ),
                const SizedBox(height: 12),
                _buildTermSection(
                  "5. Termination",
                  "We may suspend or terminate your account if you violate these terms or engage in activities that may harm our service or other users.",
                ),
                const SizedBox(height: 16),
                const Text(
                  "By creating an account, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _agreeToTerms = true;
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text("I Agree"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final headerHeight = r.hp(0.34, min: 240, max: 300);
    final logoSize = r.wp(0.26, min: 84, max: 110);
    final logoInnerSize = logoSize * 0.6;
    final titleSize = r.sp(32, minFactor: 0.9, maxFactor: 1.08);
    final subtitleSize = r.sp(16, minFactor: 0.9, maxFactor: 1.05);
    final pageGap = r.hp(0.04, min: 28, max: 42);
    final horizontalMargin = r.wp(0.06, min: 18, max: 28);
    final cardPadding = r.wp(0.08, min: 22, max: 32);

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
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                      Color(0xFF60A5FA),
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
                            width: logoInnerSize,
                            height: logoInnerSize,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_bus_rounded,
                                size: r.sp(40),
                                color: Colors.blue.shade800,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),
                      Text(
                        "Join Kaltrike",
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
                        _showOtpField
                            ? "Verify your phone number"
                            : "Create your commuter account",
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

              // Modern Sign Up Form Card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
                child: KalSurfaceCard(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    children: [
                      // First Name Field
                      TextFormField(
                        controller: nameTextEditingController,
                        enabled: !_showOtpField || _allowPhoneEdit,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "First Name",
                          hintText: "Enter your first name",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: (_showOtpField && !_allowPhoneEdit)
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
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
                            Icons.person_rounded,
                            color: (_showOtpField && !_allowPhoneEdit)
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: r.sp(22),
                          ),
                        ),
                        validator: _validateName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                      // Last Name Field
                      TextFormField(
                        controller: lastNameTextEditingController,
                        enabled: !_showOtpField || _allowPhoneEdit,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "Last Name",
                          hintText: "Enter your last name",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: (_showOtpField && !_allowPhoneEdit)
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
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
                            Icons.person_outline_rounded,
                            color: (_showOtpField && !_allowPhoneEdit)
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: r.sp(22),
                          ),
                        ),
                        validator: _validateLastName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                      // Email Field
                      TextFormField(
                        controller: emailTextEditingController,
                        enabled: !_showOtpField || _allowPhoneEdit,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF1E293B),
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
                          fillColor: (_showOtpField && !_allowPhoneEdit)
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
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
                            color: (_showOtpField && !_allowPhoneEdit)
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: r.sp(22),
                          ),
                        ),
                        validator: _validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                      // Phone Number Field
                      TextFormField(
                        controller: phoneTextEditingController,
                        enabled: !_showOtpField || _allowPhoneEdit,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "Phone Number",
                          hintText: "09XXXXXXXXX",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: (_showOtpField && !_allowPhoneEdit)
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
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
                            Icons.phone_rounded,
                            color: (_showOtpField && !_allowPhoneEdit)
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: r.sp(22),
                          ),
                          suffixIcon: _showOtpField && !_isOtpVerified && !_allowPhoneEdit
                              ? IconButton(
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            onPressed: () {
                              _showChangePhoneDialog();
                            },
                          )
                              : null,
                        ),
                        validator: _validatePhone,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                      // Password Field
                      TextFormField(
                        controller: passwordTextEditingController,
                        enabled: !_showOtpField || _allowPhoneEdit,
                        obscureText: _secureText,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Create a strong password",
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                          filled: true,
                          fillColor: (_showOtpField && !_allowPhoneEdit)
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFF8FAFC),
                          contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
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
                            color: (_showOtpField && !_allowPhoneEdit)
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: r.sp(22),
                          ),
                          suffixIcon: _showOtpField && _allowPhoneEdit
                              ? null
                              : IconButton(
                            icon: Icon(
                              _secureText
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.grey.shade600,
                              size: r.sp(22),
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

                      // OTP Field (shown only after sending OTP)
                      if (_showOtpField) ...[
                        SizedBox(height: r.hp(0.024, min: 16, max: 22)),
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: "Enter OTP",
                            hintText: "XXXXXX",
                            counterText: "",
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
                              borderSide: BorderSide(
                                color: _isOtpVerified
                                    ? Colors.green
                                    : const Color(0xFF2563EB),
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
                            prefixIcon: Icon(
                              Icons.sms_rounded,
                              color: _isOtpVerified
                                  ? Colors.green
                                  : Colors.blue.shade600,
                              size: r.sp(22),
                            ),
                            suffixIcon: _isOtpVerified
                                ? const Icon(
                              Icons.verified_rounded,
                              color: Colors.green,
                              size: (22),
                            )
                                : null,
                          ),
                          validator: _validateOtp,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                        const SizedBox(height: 10),

                        // OTP Actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Resend OTP Row
                            Row(
                              children: [
                                Text(
                                  "Didn't receive the code? ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: r.sp(14),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _resendCountdown > 0 ? null : _resendOtp,
                                  child: Text(
                                    _resendCountdown > 0
                                        ? "Resend in $_resendCountdown"
                                        : "Resend OTP",
                                    style: TextStyle(
                                      color: _resendCountdown > 0
                                          ? Colors.grey
                                          : const Color(0xFF2563EB),
                                      fontSize: r.sp(14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Wrong number (placed below)
                            if (!_isOtpVerified)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _showChangePhoneDialog,
                                  child: const Text(
                                    "Wrong number?",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: (15),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                            SizedBox(height: r.hp(0.024, min: 16, max: 22)),
                          ],
                        ),
                      ],

                      SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                      // Terms of Service Agreement
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _agreeToTerms ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (_isLoading || _isSendingOtp) ? null : (bool? value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "I agree to the Terms of Service",
                                    style: TextStyle(
                                      fontSize: (15),
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: (_isLoading || _isSendingOtp) ? null : _showTermsDialog,
                                    child: Text(
                                      "Read Terms of Service",
                                      style: TextStyle(
                                        fontSize: r.sp(14),
                                        color: (_isLoading || _isSendingOtp)
                                            ? Colors.grey
                                            : const Color(0xFF2563EB),
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Register/Verify Button
                      SizedBox(
                        width: double.infinity,
                        child: KalPrimaryButton(
                          label: _showOtpField ? (_isOtpVerified ? 'Complete Registration' : 'Verify OTP') : 'Send OTP',
                          icon: _showOtpField ? Icons.verified_user_rounded : Icons.person_add_alt_1_rounded,
                          isLoading: _isLoading || _isSendingOtp,
                          onPressed: (_agreeToTerms && !_isLoading && !_isSendingOtp) ? validateForm : null,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Login Section
                      if (!_showOtpField)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: r.sp(15),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: (_isLoading || _isSendingOtp)
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Log In",
                                style: TextStyle(
                                  color: (_isLoading || _isSendingOtp)
                                      ? Colors.grey
                                      : const Color(0xFF2563EB),
                                  fontSize: r.sp(15),
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

              SizedBox(height: pageGap),
            ],
          ),
        ),
      ),
    );
  }
}
