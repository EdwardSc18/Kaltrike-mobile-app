import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/state/app_info.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/assistant_methods.dart';

class RatingsTabPage extends StatefulWidget {
  const RatingsTabPage({Key? key}) : super(key: key);

  @override
  State<RatingsTabPage> createState() => _RatingsTabPageState();
}

class _RatingsTabPageState extends State<RatingsTabPage> {
  double ratingsNumber = 0;
  int totalRatings = 0;
  bool _isRefreshing = false;

  Future<void> _refreshRatings() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh driver ratings from Firebase
      AssistantMethods.readDriverRatings(context);

      // Wait a moment for data to be processed
      await Future.delayed(Duration(milliseconds: 300));

      // Update local state with new ratings
      getRatingsNumber();
      getTotalRatingsCount();

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ratings updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update ratings: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Refresh ratings error: $error");
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Load initial data when screen first opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshRatings();
    });
  }

  getRatingsNumber() {
    setState(() {
      ratingsNumber = double.parse(
          Provider.of<AppInfo>(context, listen: false).driverAverageRatings);
    });

    setupRatingsTitle();
  }

  getTotalRatingsCount() {
    setState(() {
      totalRatings = 24; // Replace with actual count from your database
    });
  }

  setupRatingsTitle() {
    if (ratingsNumber == 1) {
      setState(() {
        titleStarsRating = "Very Bad";
      });
    }
    if (ratingsNumber == 2) {
      setState(() {
        titleStarsRating = "Bad";
      });
    }
    if (ratingsNumber == 3) {
      setState(() {
        titleStarsRating = "Good";
      });
    }
    if (ratingsNumber == 4) {
      setState(() {
        titleStarsRating = "Very Good";
      });
    }
    if (ratingsNumber == 5) {
      setState(() {
        titleStarsRating = "Excellent";
      });
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return const Color(0xFF10B981);
    if (rating >= 3.5) return const Color(0xFFF59E0B);
    if (rating >= 2.5) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _getRatingSubtitle(double rating) {
    if (rating >= 4.5) return "Outstanding driver! Keep up the great work.";
    if (rating >= 4.0) return "Excellent service! Passengers love your rides.";
    if (rating >= 3.5) return "Good performance! You're doing well.";
    if (rating >= 3.0) return "Average rating. Room for improvement.";
    if (rating >= 2.0) return "Below average. Focus on service quality.";
    return "Needs significant improvement.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Modern Gradient Header - Fixed to occupy full top
          Container(
            width: double.infinity,
            height: 190, // Fixed height for the header
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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    // Title and Refresh Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Driver Ratings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isRefreshing
                            ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : IconButton(
                          icon: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.9), size: 20),
                          onPressed: _refreshRatings,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Refresh ratings',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Based on all the passenger reviews",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Rest of the content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshRatings,
              color: Color(0xFF2563EB),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Main Rating Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Rating number with loading state
                              _isRefreshing
                                  ? Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              )
                                  : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: _getRatingColor(ratingsNumber).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                    _getRatingColor(ratingsNumber).withOpacity(0.3),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ratingsNumber.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: _getRatingColor(ratingsNumber),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Star rating
                              _isRefreshing
                                  ? SizedBox(
                                height: 30,
                                child: Center(
                                  child: Text(
                                    "Updating...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                                  : SmoothStarRating(
                                rating: ratingsNumber,
                                allowHalfRating: true,
                                starCount: 5,
                                color: const Color(0xFFFFC107),
                                borderColor: Colors.grey.shade300,
                                size: 30,
                                spacing: 4,
                              ),
                              const SizedBox(height: 15),

                              // Rating title
                              _isRefreshing
                                  ? SizedBox(
                                height: 24,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              )
                                  : Text(
                                titleStarsRating,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _getRatingColor(ratingsNumber),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Rating subtitle
                              _isRefreshing
                                  ? SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    "Fetching latest ratings...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              )
                                  : Text(
                                _getRatingSubtitle(ratingsNumber),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Tips Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_rounded,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Improve Your Rating",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Be punctual, drive safely, and provide excellent service",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Loading indicator for entire screen
                      if (_isRefreshing)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Updating ratings data...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}