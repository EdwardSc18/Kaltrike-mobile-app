import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryDeep = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF60A5FA);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryDeep, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
