import 'package:flutter/material.dart';

class Responsive {
  Responsive(this.context) : size = MediaQuery.sizeOf(context);

  final BuildContext context;
  final Size size;

  double wp(double percent, {double min = 0, double? max}) {
    final value = size.width * percent;
    return value.clamp(min, max ?? double.infinity).toDouble();
  }

  double hp(double percent, {double min = 0, double? max}) {
    final value = size.height * percent;
    return value.clamp(min, max ?? double.infinity).toDouble();
  }

  double sp(double base, {double minFactor = 0.88, double maxFactor = 1.18}) {
    final factor = (size.shortestSide / 390).clamp(minFactor, maxFactor);
    return (base * factor).toDouble();
  }

  bool get isSmallPhone => size.width < 360;
  bool get isTablet => size.width >= 600;
}

extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive(this);
}
