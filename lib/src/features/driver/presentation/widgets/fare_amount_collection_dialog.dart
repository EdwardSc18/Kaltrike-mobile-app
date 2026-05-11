import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';

class FareAmountCollectionDialog extends StatefulWidget {
  final double? totalFareAmount;

  const FareAmountCollectionDialog({super.key, this.totalFareAmount});

  @override
  State<FareAmountCollectionDialog> createState() =>
      _FareAmountCollectionDialogState();
}

class _FareAmountCollectionDialogState extends State<FareAmountCollectionDialog> {
  bool _isCollecting = false;

  @override
  Widget build(BuildContext context) {
    final totalFare = widget.totalFareAmount ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
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
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${driverVehicleType?.toUpperCase() ?? 'TRIP'} FARE',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Collect fare from commuter',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The commuter already confirmed the payment. Please collect the cash before completing the trip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    '₱${totalFare.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      fontSize: 38,
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
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _isCollecting ? null : _collectCashAndCompleteTrip,
                  child: _isCollecting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Completing trip...',
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
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Collect Cash • ₱${totalFare.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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
    );
  }

  void _collectCashAndCompleteTrip() {
    setState(() {
      _isCollecting = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        width: (MediaQuery.sizeOf(context).width * 0.9)
            .clamp(280.0, 360.0)
            .toDouble(),
        buttonsBorderRadius: const BorderRadius.all(Radius.circular(16)),
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        headerAnimationLoop: false,
        animType: AnimType.bottomSlide,
        title: 'Trip completed',
        desc: 'Cash collected successfully. Returning to home screen.',
        btnOkOnPress: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
          );
        },
        btnOkText: 'Go to Home',
        btnOkColor: const Color(0xFF2563EB),
      ).show();
    });
  }
}
