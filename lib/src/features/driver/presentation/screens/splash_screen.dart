import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/auth/presentation/screens/login_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  startTimer() {
    Timer(const Duration(seconds: 3), () async {
      // Always navigate to LoginScreen first
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => LoginScreen())
      );
    });
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500)
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    );

    _controller.forward();
    startTimer();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final logoSize = r.wp(0.34, min: 104, max: 150);
    final logoInnerSize = logoSize * 0.72;
    final topSpacing = r.hp(0.1, min: 56, max: 100);
    final titleSize = r.sp(36, minFactor: 0.9, maxFactor: 1.08);
    final subtitleSize = r.sp(16, minFactor: 0.9, maxFactor: 1.08);
    final loaderSize = r.wp(0.15, min: 52, max: 64);
    final contentGap = r.hp(0.04, min: 24, max: 36);
    final footerBottom = r.hp(0.04, min: 24, max: 40);
    final horizontalPadding = r.wp(0.1, min: 24, max: 40);

    return Scaffold(
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
            stops: [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "images/icon.png",
                          width: logoInnerSize,
                          height: logoInnerSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: contentGap),
                    Text(
                      "Kaltrike Driver",
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.hp(0.012, min: 10, max: 14)),
                    Text(
                      "Your trusted ride partner in Tabuk City",
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: r.hp(0.06, min: 32, max: 56)),
                    Column(
                      children: [
                        Container(
                          width: loaderSize,
                          height: loaderSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3.0,
                          ),
                        ),
                        SizedBox(height: r.hp(0.022, min: 14, max: 20)),
                        Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: r.sp(14),
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(bottom: footerBottom),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.wp(0.05, min: 18, max: 24),
                          vertical: r.hp(0.012, min: 8, max: 10),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Powered by Kaltrike",
                          style: TextStyle(
                            fontSize: r.sp(14),
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}