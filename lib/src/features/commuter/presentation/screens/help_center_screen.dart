import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_surface_card.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
          "Help Center",
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
                    "How can we help you?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Find answers to common questions and get support",
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
              "Quick Help",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            // Commuters Section
            _buildHelpCategory(
              icon: Icons.people_rounded,
              title: "Commuters",
              questions: [
                "Who can use Kaltrike?",
                "How to find nearby drivers?",
                "Ride sharing guidelines",
                "Commuter safety tips",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Who can use Kaltrike?":
                    _showHelpDetails(
                      context,
                      "Who can use Kaltrike?",
                      "Kaltrike is available for all commuters aged 18 and above. To use our service:\n\n• You must be at least 18 years old\n• Have a valid phone number\n• Complete profile verification\n• Agree to our terms of service\n\nWe serve both individual commuters and groups looking for convenient transportation solutions.",
                    );
                    break;
                  case "How to find nearby drivers?":
                    _showHelpDetails(
                      context,
                      "How to find nearby drivers?",
                      "To find nearby drivers:\n\n1. Open the Kaltrike app\n2. Allow location access for accurate results\n3. Available drivers will appear on the map\n4. Driver availability is shown in real-time\n5. You can see driver ratings and estimated arrival times\n\nNote: Driver availability may vary based on your location and time of day.",
                    );
                    break;
                  case "Ride sharing guidelines":
                    _showHelpDetails(
                      context,
                      "Ride sharing guidelines",
                      "For a smooth ride sharing experience:\n\n• Be ready at your pickup location\n• Treat drivers and other passengers with respect\n• Keep the vehicle clean\n• No smoking or alcohol consumption\n• Follow safety protocols\n• Maximum 3 passengers per vehicle\n• Wear seatbelts at all times\n\nViolations may result in account suspension.",
                    );
                    break;
                  case "Commuter safety tips":
                    _showHelpDetails(
                      context,
                      "Commuter safety tips",
                      "Your safety is our priority:\n\n• Verify driver details before boarding\n• Share your trip details with trusted contacts\n• Sit in the back seat when traveling alone\n• Always wear your seatbelt\n• Check that the vehicle matches the app details\n• Report any safety concerns immediately",
                    );
                    break;
                }
              },
            ),

            _buildHelpCategory(
              icon: Icons.account_circle_rounded,
              title: "Account & Profile",
              questions: [
                "How to update my profile?",
                "Account verification issues",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "How to update my profile?":
                    _showHelpDetails(
                      context,
                      "How to update my profile?",
                      "To update your profile:\n\n1. Go to 'Profile' in the app menu\n2. Tap 'Edit Profile'\n3. Update your personal information\n4. Save your changes\nRequired information:\n• Full name\n• Phone number\n• Email address",
                    );
                    break;
                  case "Account verification issues":
                    _showHelpDetails(
                      context,
                      "Account verification issues",
                      "If you're having verification issues:\n\n• Ensure your phone number is correct and active\n• Check your internet connection\n• Make sure you're entering the correct verification code\n• Wait for the code to expire before requesting a new one\n• Contact support if issues persist\n\nVerification is required for security and to prevent duplicate accounts.",
                    );
                    break;
                }
              },
            ),

            _buildHelpCategory(
              icon: Icons.electric_rickshaw_rounded,
              title: "Rides & Booking",
              questions: [
                "How to book a ride?",
                "Ride cancellation policy",
                "One user per ride policy",
                "Booking for groups",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "How to book a ride?":
                    _showHelpDetails(
                      context,
                      "How to book a ride?",
                      "Booking a ride is simple:\n\n1. Open the Kaltrike app\n2. Enter your destination\n3. Confirm your pickup location\n4. Select your preferred vehicle type\n5. Review the fare estimate\n6. Tap 'Book Ride'\n7. Wait for driver acceptance\n\nYou'll receive notifications when a driver accepts your request and when they arrive.",
                    );
                    break;
                  case "Ride cancellation policy":
                    _showHelpDetails(
                      context,
                      "Ride cancellation policy",
                      "Cancellation policies:\n\n• Free cancellation within 2 minutes of booking\n• Cancellation after 2 minutes may incur a small fee\n• Repeated cancellations may affect your rating\n• No fee if driver is significantly late\n• Cancel via app before driver arrives\n\nWe encourage timely cancellations to respect our drivers' time.",
                    );
                    break;
                  case "One user per ride policy":
                    _showHelpDetails(
                      context,
                      "One user per ride policy",
                      "ONE USER PER RIDE POLICY:\n\n• Each booking is tied to ONE registered user account\n• The booking user must be present during the ride\n• Account sharing is strictly prohibited\n• This ensures safety and accountability\n• Each user must have their own verified account\n\nThis policy helps us maintain security and provide better service to all commuters.",
                    );
                    break;
                  case "Booking for groups":
                    _showHelpDetails(
                      context,
                      "Booking for groups",
                      "Group booking information:\n\n• Maximum 3 passengers per vehicle\n• The booking user is responsible for the group\n• All passengers must follow safety rules\n• Additional charges may apply for extra passengers\n• Specify group size when booking\n\nFor larger groups, please book multiple vehicles.",
                    );
                    break;
                }
              },
            ),

            _buildHelpCategory(
              icon: Icons.payment_rounded,
              title: "Payments & Refunds",
              questions: [
                "Understanding ride fares",
                "Online payment methods",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Understanding ride fares":
                    _showHelpDetails(
                      context,
                      "Understanding ride fares",
                      "Fare breakdown:\n\n• Passenger fare: ₱20 per passenger for the first 3 km\n• Distance fee: ₱5 per km after 3 km\n• Baggage fee: ₱20 per bag\n\nYou'll see the fare estimate before confirming your ride. Final fare updates based on passenger count, baggage, and actual route distance.",
                    );
                    break;
                  case "Payment declined issues":
                    _showHelpDetails(
                      context,
                      "Payment declined issues",
                      "If your payment is declined:\n\n• Check your payment method details\n• Ensure sufficient funds\n• Verify card expiration date\n• Contact your bank for authorization issues\n• Try an alternative payment method\n• Clear app cache and restart\n\nWe currently accept cash payments. Online payment options coming soon!",
                    );
                    break;
                  case "Online payment methods":
                    _showHelpDetails(
                      context,
                      "Online payment methods",
                      "CURRENT PAYMENT METHODS:\n\n• CASH: Pay directly to the driver after your ride\n\nCOMING SOON:\n• GCash\n• Credit/Debit Cards\n• PayPal\n• Other digital wallets\n\nWe're working to bring you more convenient payment options. Stay tuned for updates!",
                    );
                    break;
                }
              },
            ),

            _buildHelpCategory(
              icon: Icons.security_rounded,
              title: "Safety & Security",
              questions: [
                "Safety features in the app",
                "What to do in emergency?",
                "Reporting safety concerns",
                "Driver verification process",
              ],
              onQuestionTap: (question) {
                switch (question) {
                  case "Safety features in the app":
                    _showHelpDetails(
                      context,
                      "Safety features in the app",
                      "Our safety features include:\n\n• Driver background checks\n• Real-time ride tracking\n• Share trip details with contacts\n• Driver ratings and reviews\n• Vehicle information verification\n• 24/7 support team\n\nWe continuously work to enhance safety for all users.",
                    );
                    break;
                  case "What to do in emergency?":
                    _showHelpDetails(
                      context,
                      "What to do in emergency?",
                      "In case of emergency:\n\n1. Contact local authorities immediately (911)\n2. Share your location with trusted contacts\n3. Move to a safe location if possible\n4. Contact our 24/7 support team\n\nYour safety is our top priority. All emergency reports are taken seriously and addressed immediately.",
                    );
                    break;
                  case "Reporting safety concerns":
                    _showHelpDetails(
                      context,
                      "Reporting safety concerns",
                      "To report safety concerns:\n\n Please contact directly from the provided information below for any possible reports  \n\nWe investigate all reports thoroughly and take appropriate action, which may include driver suspension or permanent removal from the platform.",
                    );
                    break;
                  case "Driver verification process":
                    _showHelpDetails(
                      context,
                      "Driver verification process",
                      "Our driver verification includes:\n\n• Comprehensive background checks\n• Driving license validation\n• Vehicle inspection and insurance\n• Identity verification\n• Continuous monitoring\n\nOnly verified and qualified drivers are allowed on our platform.",
                    );
                    break;
                }
              },
            ),

            const SizedBox(height: 24),

            // Contact Support
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
                    "Still need help?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Our support team is available 24/7 to assist you",
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
