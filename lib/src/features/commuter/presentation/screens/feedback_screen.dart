import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 0;
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'App Experience',
    'Driver Experience',
    'Payment Issues',
    'Safety Concerns',
    'Feature Request',
    'Bug Report',
  ];

  void _submitFeedback() {
    if (_formKey.currentState!.validate() && _selectedRating > 0) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog();
      });
    } else if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rating"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF22C55E),
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thank You!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your feedback has been submitted successfully. We appreciate your input!",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: KalPrimaryButton(
                  label: 'Done',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Give Feedback",
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF10B981),
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
                        Icons.feedback_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Share Your Thoughts",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your feedback helps us improve Kaltrike for everyone",
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

              // Rating Section
              const Text(
                "How would you rate your experience?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),

              // Star Rating
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < _selectedRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _selectedRating == 0
                      ? "Tap to rate"
                      : _selectedRating == 1
                      ? "Poor"
                      : _selectedRating == 2
                      ? "Fair"
                      : _selectedRating == 3
                      ? "Good"
                      : _selectedRating == 4
                      ? "Very Good"
                      : "Excellent",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Category Dropdown
              const Text(
                "Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: _categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Feedback Form
              const Text(
                "Your Feedback",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Tell us about your experience, suggestions, or issues...",
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your feedback';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (at least 10 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: KalPrimaryButton(
                  label: 'Submit Feedback',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitFeedback,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
