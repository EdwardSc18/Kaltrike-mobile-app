import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/driver/state/app_info.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/trips_history_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/assistant_methods.dart';

class EarningsTabPage extends StatefulWidget {
  const EarningsTabPage({Key? key}) : super(key: key);

  @override
  _EarningsTabPageState createState() => _EarningsTabPageState();
}

class _EarningsTabPageState extends State<EarningsTabPage> {
  bool _isRefreshing = false;

  Future<void> _refreshEarningsData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh driver earnings from Firebase
      AssistantMethods.readDriverEarnings(context);

      // Wait a moment for data to be processed
      await Future.delayed(Duration(milliseconds: 500));

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Earnings data updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update earnings: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Refresh earnings error: $error");
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
      _refreshEarningsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refreshEarningsData,
        color: Color(0xFF2563EB),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Modern Earnings Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A), // Deep navy blue
                      Color(0xFF2563EB), // Vibrant blue
                      Color(0xFF60A5FA), // Light blue
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
                    padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title and Refresh Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Total Earnings",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
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
                              icon: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.8), size: 20),
                              onPressed: _refreshEarningsData,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              tooltip: 'Refresh earnings',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Earnings Amount
                        Consumer<AppInfo>(
                          builder: (context, appInfo, child) {
                            return _isRefreshing
                                ? Container(
                              height: 62,
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            )
                                : Text(
                              "₱ " + appInfo.driverTotalEarnings,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          "Lifetime earnings from all completed trips",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Stats Cards Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    // Trips Count Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: const Color(0xFF2563EB),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Total Trips",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<AppInfo>(
                              builder: (context, appInfo, child) {
                                return _isRefreshing
                                    ? Container(
                                  height: 28,
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
                                  appInfo.allTripsHistoryInformationList.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Average Earnings Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                color: const Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Avg. per Trip",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<AppInfo>(
                              builder: (context, appInfo, child) {
                                return _isRefreshing
                                    ? Container(
                                  height: 28,
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                      ),
                                    ),
                                  ),
                                )
                                    : Text(
                                  _calculateAverageEarnings(appInfo),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Trips History Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    final appInfo = Provider.of<AppInfo>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ChangeNotifierProvider<AppInfo>.value(
                          value: appInfo,
                          child: TripsHistoryScreen(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
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
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: const Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Trip History",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "View all your completed trips and earnings",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF2563EB),
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Loading Indicator for entire screen
              if (_isRefreshing)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
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
                          const SizedBox(width: 8),
                          Text(
                            "Updating earnings data...",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateAverageEarnings(AppInfo appInfo) {
    final totalTrips = appInfo.allTripsHistoryInformationList.length;

    if (totalTrips == 0) return "₱ 0";

    try {
      final totalEarnings = double.parse(appInfo.driverTotalEarnings.replaceAll('₱ ', '').replaceAll(',', ''));
      final average = totalEarnings / totalTrips;
      return "₱ ${average.toStringAsFixed(0)}";
    } catch (e) {
      return "₱ 0";
    }
  }
}