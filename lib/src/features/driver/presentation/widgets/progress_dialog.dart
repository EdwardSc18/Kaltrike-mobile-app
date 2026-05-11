import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String? message;

  const ProgressDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Loading Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer rotating progress
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      strokeWidth: 3.0,
                      backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    ),
                  ),
                  // Inner icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Message Text
            Text(
              message ?? "Processing...",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              "Please wait a moment",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative simplified version for quick operations
class SimpleProgressDialog extends StatelessWidget {
  final String? message;

  const SimpleProgressDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator with container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                strokeWidth: 3.0,
              ),
            ),

            const SizedBox(width: 20),

            // Message
            Expanded(
              child: Text(
                message ?? "Loading...",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Success Dialog for completion states
class SuccessDialog extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const SuccessDialog({this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade900.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Message
            Text(
              message ?? "Success!",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Error Dialog for error states
class ErrorDialog extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const ErrorDialog({this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade900.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Message
            Text(
              message ?? "Error Occurred",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}