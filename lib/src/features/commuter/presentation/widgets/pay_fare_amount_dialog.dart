import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_colors.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_spacing.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_surface_card.dart';

class PayFareAmountDialog extends StatefulWidget {
  const PayFareAmountDialog({super.key, this.fareAmount});

  final double? fareAmount;

  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  bool _isPaying = false;

  @override
  Widget build(BuildContext context) {
    final fareAmount = widget.fareAmount ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA7F3D0),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TRIP FARE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pay fare to driver',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is your total trip fare. Please pay the driver in cash to complete your ride.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              KalSurfaceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Text(
                      'Total fare amount',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${fareAmount.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                        fontSize: 40,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cash payment only',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.white70,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _isPaying ? null : _processPayment,
                    child: _isPaying
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing payment...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Pay Cash • ₱${fareAmount.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() {
    setState(() {
      _isPaying = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, 'cashPayed');
      }
    });
  }
}
