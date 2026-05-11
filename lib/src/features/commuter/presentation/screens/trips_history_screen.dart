import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/history_design_ui.dart';
import 'package:kaltrike_driver_app/src/features/commuter/services/assistant_methods.dart';

class TripsHistoryScreen extends StatefulWidget {
  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshTripHistory() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Get the AppInfo provider
      final appInfo = Provider.of<AppInfo>(context, listen: false);

      // First, read the trip keys to get the latest data
      AssistantMethods.readTripsKeysForOnlineUser(context);

      // Wait a moment for the keys to be processed, then read the full history
      await Future.delayed(Duration(milliseconds: 500));

      // Now read the complete trip history information
      await AssistantMethods.readTripsHistoryInformation(context);

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip history updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update history: ${error.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("Refresh error: $error");
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
      _refreshTripHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
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
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
        ),
        title: const Text(
          "Trip History",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          // Refresh Button
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              onPressed: _isRefreshing ? null : _refreshTripHistory,
              tooltip: 'Refresh history',
            ),
          ),

          // Trip Count Badge
          Consumer<AppInfo>(
            builder: (context, appInfo, child) {
              final tripCount = appInfo.allTripsHistoryInformationList.length;
              if (tripCount > 0) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$tripCount ${tripCount == 1 ? 'trip' : 'trips'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),

      body: Consumer<AppInfo>(
        builder: (context, appInfo, child) {
          // Get the list and sort it from latest to oldest
          final allTripsHistory = appInfo.allTripsHistoryInformationList;

          // Sort the list in descending order (latest first)
          final sortedTripsHistory = List.from(allTripsHistory)
            ..sort((a, b) => b.time!.compareTo(a.time!));

          return _isRefreshing && sortedTripsHistory.isEmpty
              ? _buildLoadingState()
              : sortedTripsHistory.isEmpty
              ? _buildEmptyState()
              : Column(
            children: [
              // Summary Card
              Padding(
                padding: const EdgeInsets.all(20),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Spent",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _calculateTotalSpent(sortedTripsHistory),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${sortedTripsHistory.length} ${sortedTripsHistory.length == 1 ? 'ride' : 'rides'}",
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Trips Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Recent Rides",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (_isRefreshing)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2563EB)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Updating...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "Latest first",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Trips List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RefreshIndicator(
                    onRefresh: _refreshTripHistory,
                    color: Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    child: ListView.separated(
                      separatorBuilder: (context, i) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // Handle trip tap if needed
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: HistoryDesignUIWidget(
                                    tripsHistoryModel: sortedTripsHistory[i],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      itemCount: sortedTripsHistory.length,
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading your trips...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshTripHistory,
      color: Color(0xFF2563EB),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    color: Color(0xFF2563EB),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "No Rides Yet",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your completed rides will appear here",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _refreshTripHistory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade600.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Refresh History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _calculateTotalSpent(List<dynamic> trips) {
    double total = 0;
    for (var trip in trips) {
      try {
        final fare = trip.fareAmount?.replaceAll('₱', '').replaceAll(',', '') ?? '0';
        total += double.parse(fare);
      } catch (e) {
        // Handle parsing errors
        print("Error parsing fare for trip: $e");
      }
    }
    return "₱${total.toStringAsFixed(0)}";
  }
}