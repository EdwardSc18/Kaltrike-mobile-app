import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius modalRadius = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
  );
}
