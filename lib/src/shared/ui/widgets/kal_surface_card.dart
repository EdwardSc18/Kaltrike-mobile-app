import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_colors.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_spacing.dart';

class KalSurfaceCard extends StatelessWidget {
  const KalSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
