import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/auth/presentation/screens/login_screen.dart';

import '../../../models/driver_data.dart';

class AuthLoadingScreen extends StatefulWidget {
  final User firebaseUser;

  const AuthLoadingScreen({super.key, required this.firebaseUser});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  String _title = 'Setting up your driver profile';
  String _subtitle = 'Please wait while we securely load your account information.';
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileAndRoute();
    });
  }

  Future<void> _hydrateProfileAndRoute() async {
    try {
      if (mounted) {
        setState(() {
          _title = 'Checking your driver account';
          _subtitle = 'Verifying your sign-in and loading your driver details.';
        });
      }

      currentFirebaseUser = widget.firebaseUser;

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('drivers')
          .child(widget.firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 20));

      if (snapshot.value == null) {
        throw Exception('Driver profile was not found.');
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final vehicleDetails = data['vechicle_details'] is Map
          ? Map<dynamic, dynamic>.from(data['vechicle_details'] as Map)
          : <dynamic, dynamic>{};

      onlineDriverData.id = data['id']?.toString() ?? widget.firebaseUser.uid;
      onlineDriverData.name = data['name']?.toString() ?? '';
      onlineDriverData.phone = data['phone']?.toString() ?? '';
      onlineDriverData.email = data['email']?.toString() ?? '';
      onlineDriverData.vehicle_color = vehicleDetails['vehicle_color']?.toString() ?? '';
      onlineDriverData.vehicle_model = vehicleDetails['vehicle_model']?.toString() ?? '';
      onlineDriverData.plate_number = vehicleDetails['plate_number']?.toString() ?? '';
      driverVehicleType = vehicleDetails['type']?.toString() ?? '';

      final validationStatus = (data['validationStatus'] ?? 'pending').toString().toLowerCase();
      final isApproved = validationStatus == 'approved' || validationStatus == 'validated';

      if (mounted) {
        setState(() {
          _title = 'Driver profile ready';
          _subtitle = isApproved
              ? 'Welcome back, ${onlineDriverData.name?.isNotEmpty == true ? onlineDriverData.name : 'Driver'}.'
              : 'Your account is ${validationStatus.toUpperCase()}. We loaded your details and will open your dashboard now.';
          _completed = true;
        });
      }

      await Future<void>.delayed(const Duration(milliseconds: 350));

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
        (route) => false,
      );
    } on TimeoutException {
      await _handleFailure('Loading your driver profile took too long. Please try again.');
    } catch (error) {
      await _handleFailure('Failed to load your driver profile. Please sign in again.');
    }
  }

  Future<void> _handleFailure(String message) async {
    try {
      await fAuth.signOut();
    } catch (_) {}

    currentFirebaseUser = null;
    onlineDriverData = DriverData();
    driverVehicleType = '';

    if (!mounted) {
      return;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
      fontSize: 14.0,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            shape: BoxShape.circle,
                          ),
                          child: _completed
                              ? const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF10B981),
                                  size: 48,
                                )
                              : const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
