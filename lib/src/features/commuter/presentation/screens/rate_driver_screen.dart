import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/main_screen.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';

class RateDriverScreen extends StatefulWidget {
  final String? assignedDriverId;

  const RateDriverScreen({super.key, this.assignedDriverId});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _updateRatingTitle(double value) {
    setState(() {
      countRatingStars = value;
      if (value == 1) {
        titleStarsRating = 'Very Bad';
      } else if (value == 2) {
        titleStarsRating = 'Bad';
      } else if (value == 3) {
        titleStarsRating = 'Good';
      } else if (value == 4) {
        titleStarsRating = 'Very Good';
      } else if (value == 5) {
        titleStarsRating = 'Excellent';
      } else {
        titleStarsRating = '';
      }
    });
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    if (countRatingStars <= 0) {
      Fluttertoast.showToast(msg: 'Please select a rating first.');
      return;
    }
    if (widget.assignedDriverId == null || widget.assignedDriverId!.isEmpty) {
      Fluttertoast.showToast(msg: 'Driver information is missing.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final DatabaseReference commentRef = FirebaseDatabase.instance
          .ref('All Ride Requests')
          .push();
      await commentRef.set('Comment: ${_commentController.text.trim()}');

      final DatabaseReference rateDriverRef = FirebaseDatabase.instance
          .ref()
          .child('drivers')
          .child(widget.assignedDriverId!)
          .child('ratings');

      final DatabaseEvent snap = await rateDriverRef.once();
      if (snap.snapshot.value == null) {
        await rateDriverRef.set(countRatingStars.toString());
      } else {
        final double pastRatings =
            double.tryParse(snap.snapshot.value.toString()) ?? 0.0;
        final double newAverageRatings = (pastRatings + countRatingStars) / 2;
        await rateDriverRef.set(newAverageRatings.toString());
      }

      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Rating submitted successfully');
      _showSuccessDialog();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to submit rating. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Thank you for your feedback!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your trip has been completed successfully and your rating was recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: KalPrimaryButton(
                    label: 'Back to Home',
                    icon: Icons.home_rounded,
                    onPressed: () {
                      countRatingStars = 0.0;
                      titleStarsRating = '';
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => MainScreen()),
                            (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xCC0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rate_review_rounded,
                          color: Color(0xFF2563EB),
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'Rate your trip',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tell us how your ride went so we can improve the commuter experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          SmoothStarRating(
                            rating: countRatingStars,
                            allowHalfRating: false,
                            starCount: 5,
                            color: const Color(0xFFF59E0B),
                            borderColor: const Color(0xFFF59E0B),
                            size: 42,
                            onRatingChanged: _updateRatingTitle,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            titleStarsRating.isEmpty
                                ? 'Select a rating'
                                : titleStarsRating,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleStarsRating.isEmpty
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Additional comments',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentController,
                      minLines: 4,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Share anything about the ride, driver service, or overall experience.',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: KalPrimaryButton(
                        label: 'Submit Feedback',
                        icon: Icons.send_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _submitRating,
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
