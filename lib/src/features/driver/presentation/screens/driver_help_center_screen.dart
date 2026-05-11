import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_surface_card.dart';

class DriverHelpCenterScreen extends StatelessWidget {
  const DriverHelpCenterScreen({super.key});

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Coming Soon"),
          content: Text("$feature will be available in our next update."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDetails(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Driver Help Center",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Driver Support",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Get help with driving, earnings, and account issues",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Help Section
            const Text(
              "Driver Resources",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Driving & Trips Section
            _buildHelpCategory(
              icon: Icons.electric_rickshaw_rounded,
              title: "Driving & Trips",
              questions: [
                "How to accept ride requests?",
                "What to do when passenger cancels?",
                "Navigation and route optimization",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "How to accept ride requests?":
                    _showHelpDetails(
                      context,
                      "How to accept ride requests?",
                      "To accept ride requests:\n\n1. Keep your app online and active\n2. You'll receive ride requests automatically\n3. Review passenger details and destination\n4. Tap 'Accept' within 15 seconds\n5. Proceed to pickup location immediately\n\nTips:\n• Maintain good network connection\n• Keep your location services enabled\n• Respond promptly to avoid timeout",
                    );
                    break;
                  case "What to do when passenger cancels?":
                    _showHelpDetails(
                      context,
                      "What to do when passenger cancels?",
                      "When a passenger cancels:\n\n• If canceled within 2 minutes: No cancellation fee\n• If canceled after 2 minutes: Small cancellation fee applies\n• You'll receive notification of cancellation\n• Return to available status automatically\n• Cancellation fees are added to your weekly earnings\n\nNote: Repeated cancellations by drivers may affect your rating.",
                    );
                    break;
                  case "Navigation and route optimization":
                    _showHelpDetails(
                      context,
                      "Navigation and route optimization",
                      "Navigation features:\n\n• Built-in GPS navigation integration\n• Estimated time of arrival (ETA)\n• Turn-by-turn directions\n\nFor best results:\n• Use recommended routes for fare calculation\n• Keep navigation app updated\n• Report route inaccuracies to support",
                    );
                    break;
                }
              },
            ),

            // Earnings & Payments Section
            _buildHelpCategory(
              icon: Icons.attach_money_rounded,
              title: "Earnings & Payments",
              questions: [
                "Understanding fare calculation",
                "Payment issues and disputes",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Understanding fare calculation":
                    _showHelpDetails(
                      context,
                      "Understanding fare calculation",
                      "Fare breakdown for drivers:\n\n• Base fare: Fixed amount is ₱20\n• Shared ride: ₱20 per additional passenger\n• Baggage fee: ₱20 per bag\n• Cancellation fee: When applicable\n• Tips: 100% goes to driver\n\nYour earnings = (Base + Distance + Shared Ride + Baggage + Time + Cancellation + Tips) - Service Fee",
                    );
                    break;
                  case "Payment issues and disputes":
                    _showHelpDetails(
                      context,
                      "Payment issues and disputes",
                      "If you have payment issues:\n\n• Check your payment method details\n• Ensure your account is verified\n• Contact support for missing payments\n• Disputes must be filed within 7 days\n• Provide trip details and evidence\n\nCommon issues:\n• Bank account verification pending\n• Incorrect account information\n• Technical processing delays",
                    );
                    break;
                }
              },
            ),

            // Vehicle Requirements Section
            _buildHelpCategory(
              icon: Icons.electric_rickshaw_rounded,
              title: "Vehicle Requirements",
              questions: [
                "Vehicle inspection guidelines",
                "Insurance requirements",
                "Document renewal process",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Vehicle inspection guidelines":
                    _showHelpDetails(
                      context,
                      "Vehicle inspection guidelines",
                      "Vehicle requirements:\n\n• Condition: Good working condition\n• Cleanliness: Interior and exterior clean\n• Documents: Updated registration and insurance\n\nInspection includes:\n• Brakes and tires check\n• Lights and signals test\n• Engine and transmission\n• Interior cleanliness",
                    );
                    break;
                  case "Insurance requirements":
                    _showHelpDetails(
                      context,
                      "Insurance requirements",
                      "Insurance coverage:\n\n• Comprehensive third-party liability insurance\n• Personal accident coverage\n• Insurance must be valid throughout service\n• Additional ride-sharing coverage recommended\n\nYou must provide proof of valid insurance during vehicle inspection.",
                    );
                    break;
                  case "Document renewal process":
                    _showHelpDetails(
                      context,
                      "Document renewal process",
                      "Document renewal:\n\n• Driver's license: Renew before expiration\n• Vehicle registration: Annual renewal\n• Insurance: Keep updated\n• Upload new documents in the app\n• Allow 3-5 days for verification\n\nExpired documents will result in temporary suspension until updated.",
                    );
                    break;
                }
              },
            ),

            // Ratings & Performance Section
            _buildHelpCategory(
              icon: Icons.star_rounded,
              title: "Ratings & Performance",
              questions: [
                "How ratings affect your account",
                "Improving your driver rating",
                "Handling negative feedback",
                "Performance incentives",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "How ratings affect your account":
                    _showHelpDetails(
                      context,
                      "How ratings affect your account",
                      "Rating system impact:\n\n• Minimum rating: 4.5 required\n• Below 4.5: Warning and coaching\n• Below 4.0: Temporary suspension\n• Consistently low ratings: Account review\n• Excellent ratings: More ride opportunities\n\nRatings are based on:\n• Driving safety\n• Vehicle cleanliness\n• Professionalism\n• Navigation accuracy",
                    );
                    break;
                  case "Improving your driver rating":
                    _showHelpDetails(
                      context,
                      "Improving your driver rating",
                      "Tips for better ratings:\n\n• Maintain clean and comfortable vehicle\n• Drive safely and obey traffic rules\n• Be polite and professional\n• Help with luggage when appropriate\n• Follow the navigation route\n• Keep the car at comfortable temperature\n• Avoid strong scents or loud music",
                    );
                    break;
                  case "Handling negative feedback":
                    _showHelpDetails(
                      context,
                      "Handling negative feedback",
                      "Dealing with negative reviews:\n\n• Don't take it personally\n• Learn from constructive feedback\n• Contact support for unfair reviews\n• Focus on providing excellent service\n• One bad review won't significantly impact your average\n\nYou can view feedback in your driver portal and respond professionally.",
                    );
                    break;
                  case "Performance incentives":
                    _showHelpDetails(
                      context,
                      "Performance incentives",
                      "Available incentives:\n\n• Weekly trip bonuses\n• Peak hour multipliers\n• High rating bonuses\n• Referral programs\n• Loyalty rewards\n• Complete streak bonuses\n\nCheck the 'Promotions' section in your app for current incentive programs.",
                    );
                    break;
                }
              },
            ),

            // Safety & Compliance Section
            _buildHelpCategory(
              icon: Icons.security_rounded,
              title: "Safety & Compliance",
              questions: [
                "Safety protocols and features",
                "Emergency procedures",
                "BPLO Tabuk City regulations",
                "Passenger verification",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Safety protocols and features":
                    _showHelpDetails(
                      context,
                      "Safety protocols and features",
                      "Safety features:\n\n• Trip sharing with trusted contacts\n• 24/7 support line\n• Passenger verification\n• Route tracking\n• Incident reporting\n\nAlways:\n• Verify passenger matches app details\n• Share your trip status with family\n• Park in well-lit areas for pickup/dropoff",
                    );
                    break;
                  case "Emergency procedures":
                    _showHelpDetails(
                      context,
                      "Emergency procedures",
                      "In case of emergency:\n\n1. Contact local authorities immediately (911)\n2. Move to safe location if possible\n3. Contact our 24/7 safety team\n4. Report incident through the app\n\nYour safety is our priority. All emergency reports are handled immediately.",
                    );
                    break;
                  case "BPLO Tabuk City regulations":
                    _showHelpDetails(
                      context,
                      "BPLO Tabuk City regulations",
                      "Local requirements:\n\n• Business permit from BPLO Tabuk City\n• Mayor's permit for transportation service\n• Franchise or transportation permit\n• Compliance with local traffic rules\n• Regular vehicle inspection certification\n\nEnsure all local permits are current and displayed as required.",
                    );
                    break;
                  case "Passenger verification":
                    _showHelpDetails(
                      context,
                      "Passenger verification",
                      "Passenger verification process:\n\n• Verify passenger name matches app\n• Confirm pickup location matches\n• Check passenger rating if available\n• Maximum 3 passengers per vehicle\n• No unverified additional passengers\n\nDo not proceed with trip if passenger details don't match for safety reasons.",
                    );
                    break;
                }
              },
            ),

            const SizedBox(height: 24),

            // Driver Support Contact
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFF0EA5E9),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "24/7 Driver Support",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Our dedicated driver support team is available round the clock",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Contact: 09567720160 | kaltrike@gmail.com",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCategory({
    required IconData icon,
    required String title,
    required List<String> questions,
    required Function(String) onQuestionTap,
  }) {
    return KalSurfaceCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: questions.map((question) =>
                  _buildQuestionItem(question, () => onQuestionTap(question))
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(String question, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: Color(0xFF64748B),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
