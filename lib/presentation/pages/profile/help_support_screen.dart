import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'chat_widget.dart';

class HelpItem {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;

  const HelpItem({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });
}

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              _buildSectionTitle('Quick Actions'),
              _buildQuickActions(),

              SizedBox(height: AppConstants.spacing32),

              // Common Questions
              _buildSectionTitle('Common Questions'),
              _buildCommonQuestions(),

              SizedBox(height: AppConstants.spacing32),

              // Contact Support
              _buildSectionTitle('Contact Support'),
              _buildContactSupport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      HelpItem(
        title: 'How to Book',
        description: 'Learn the booking process step by step',
        icon: Icons.book_online,
        onTap: () => _showHowToBook(),
      ),
      HelpItem(
        title: 'Payment Issues',
        description: 'Troubleshoot payment and billing problems',
        icon: Icons.payment,
        onTap: () => _showPaymentIssues(),
      ),
      HelpItem(
        title: 'Cancel Booking',
        description: 'How to cancel or modify your booking',
        icon: Icons.cancel,
        onTap: () => _showCancelBooking(),
      ),
      HelpItem(
        title: 'Parking Rules',
        description: 'Understand parking space rules and regulations',
        icon: Icons.rule,
        onTap: () => _showParkingRules(),
      ),
    ];

    return Column(
      children: actions.map((action) => _buildHelpCard(action)).toList(),
    );
  }

  Widget _buildCommonQuestions() {
    final questions = [
      HelpItem(
        title: 'What payment methods do you accept?',
        description: 'We accept credit cards, debit cards, UPI, and digital wallets',
        icon: Icons.question_answer,
      ),
      HelpItem(
        title: 'Can I modify my booking?',
        description: 'Bookings can be modified up to 2 hours before start time',
        icon: Icons.question_answer,
      ),
      HelpItem(
        title: 'What if I arrive late?',
        description: 'Late arrivals may result in space reassignment or cancellation',
        icon: Icons.question_answer,
      ),
      HelpItem(
        title: 'Is my vehicle insured?',
        description: 'We recommend your own vehicle insurance for comprehensive coverage',
        icon: Icons.question_answer,
      ),
    ];

    return Column(
      children: questions.map((question) => _buildHelpCard(question, showArrow: false)).toList(),
    );
  }

  Widget _buildContactSupport() {
    return Column(
      children: [
        _buildContactCard(
          title: 'Live Chat',
          description: 'Chat with our support team',
          icon: Icons.chat,
          onTap: () => _startLiveChat(),
        ),
        _buildContactCard(
          title: 'Email Support',
          description: 'support@parkingapp.com',
          icon: Icons.email,
          onTap: () => _sendEmail(),
        ),
        _buildContactCard(
          title: 'Call Us',
          description: '+1 (555) 123-4567',
          icon: Icons.phone,
          onTap: () => _makeCall(),
        ),
        _buildContactCard(
          title: 'Emergency',
          description: 'For urgent parking issues',
          icon: Icons.emergency,
          onTap: () => _emergencyContact(),
        ),
      ],
    );
  }

  Widget _buildHelpCard(HelpItem item, {bool showArrow = true}) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Icon(
            item.icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          item.description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: showArrow
            ? Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              )
            : null,
        onTap: item.onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Icon(
            icon,
            color: AppColors.ctaPrimary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
      ),
    );
  }

  void _showHowToBook() {
    _showDetailedGuide(
      title: 'How to Book a Parking Space',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideStep(
            step: 1,
            title: 'Browse Available Spaces',
            description: 'Open the app and explore parking spaces in your area. Use filters to find spaces that match your needs.',
          ),
          _buildGuideStep(
            step: 2,
            title: 'Select Date & Time',
            description: 'Choose your desired parking date and time range. The app will show real-time availability.',
          ),
          _buildGuideStep(
            step: 3,
            title: 'Choose Your Vehicle',
            description: 'Select which vehicle you\'ll be parking. If you haven\'t added a vehicle yet, you can do so from your profile.',
          ),
          _buildGuideStep(
            step: 4,
            title: 'Review & Pay',
            description: 'Review your booking details and complete payment. You\'ll receive a confirmation with QR code.',
          ),
          _buildGuideStep(
            step: 5,
            title: 'Arrive & Park',
            description: 'Arrive at the parking location and scan your QR code at the entrance for access.',
          ),
          SizedBox(height: AppConstants.spacing20),
          Text(
            '💡 Pro Tip: Book in advance to get the best rates and ensure availability!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ctaPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentIssues() {
    _showDetailedGuide(
      title: 'Payment Troubleshooting',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIssueSection(
            title: 'Common Payment Issues',
            issues: [
              _buildIssueItem(
                icon: Icons.credit_card,
                title: 'Card Declined',
                solution: 'Check your card balance, expiration date, and try a different card. Contact your bank if the issue persists.',
              ),
              _buildIssueItem(
                icon: Icons.wifi_off,
                title: 'Connection Error',
                solution: 'Ensure you have a stable internet connection and try again. Payment processing requires internet access.',
              ),
              _buildIssueItem(
                icon: Icons.lock,
                title: 'Security Code Issues',
                solution: 'Double-check your CVV code. For international cards, ensure your card supports online transactions.',
              ),
              _buildIssueItem(
                icon: Icons.timer_off,
                title: 'Payment Timeout',
                solution: 'Complete your payment within 5 minutes. If timed out, start a new booking process.',
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing20),
          _buildContactSection(),
        ],
      ),
    );
  }

  void _showCancelBooking() {
    _showDetailedGuide(
      title: 'Booking Cancellation & Modification',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(color: AppColors.ctaPrimary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.ctaPrimary),
                SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Text(
                    'Bookings can be modified or cancelled up to 2 hours before the start time for a full refund.',
                    style: TextStyle(
                      color: AppColors.ctaPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spacing20),
          Text(
            'How to Cancel or Modify:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing16),
          _buildGuideStep(
            step: 1,
            title: 'Go to My Bookings',
            description: 'Navigate to the Bookings tab from the bottom navigation.',
          ),
          _buildGuideStep(
            step: 2,
            title: 'Select Your Booking',
            description: 'Find the booking you want to modify or cancel from the active bookings list.',
          ),
          _buildGuideStep(
            step: 3,
            title: 'Choose Action',
            description: 'Tap "Modify" to change time/date or "Cancel" to cancel the booking.',
          ),
          _buildGuideStep(
            step: 4,
            title: 'Confirm Changes',
            description: 'Review any refund amount and confirm your action.',
          ),
          SizedBox(height: AppConstants.spacing20),
          Text(
            'Cancellation Policy:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing12),
          _buildPolicyItem('2+ hours before start', 'Full refund'),
          _buildPolicyItem('1-2 hours before start', '50% refund'),
          _buildPolicyItem('< 1 hour before start', 'No refund'),
        ],
      ),
    );
  }

  void _showParkingRules() {
    _showDetailedGuide(
      title: 'Parking Rules & Regulations',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRulesSection(
            title: 'General Parking Rules',
            rules: [
              'Park only in designated spaces',
              'Do not block access roads or entrances',
              'Respect time limits and booking durations',
              'Keep vehicles locked and valuables secure',
              'Follow host-specific rules and instructions',
            ],
          ),
          SizedBox(height: AppConstants.spacing20),
          _buildRulesSection(
            title: 'Vehicle Requirements',
            rules: [
              'Vehicles must be street-legal and insured',
              'Maximum vehicle size restrictions apply',
              'Electric vehicle charging only in designated areas',
              'Clean up any spills or debris before leaving',
            ],
          ),
          SizedBox(height: AppConstants.spacing20),
          _buildRulesSection(
            title: 'Safety Guidelines',
            rules: [
              'No smoking in parking areas',
              'Properly secure loose items in vehicle',
              'Report any suspicious activity to authorities',
              'Emergency exits must remain clear',
              'Children must be supervised at all times',
            ],
          ),
          SizedBox(height: AppConstants.spacing20),
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Text(
                    'Violation of parking rules may result in fines, towing, or account suspension.',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          'Start Live Chat',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.ctaPrimary,
            ),
            SizedBox(height: AppConstants.spacing16),
            Text(
              'Connect with our support team for instant help',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppConstants.spacing16),
            Text(
              'Available: Mon-Fri 9AM-6PM',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showChatInterface();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctaPrimary,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@parkingapp.com',
      queryParameters: {
        'subject': 'Support Request - Parking App',
        'body': 'Hi,\n\nI need help with...\n\nThank you.',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showContactForm('Email Support');
      }
    } catch (e) {
      _showContactForm('Email Support');
    }
  }

  void _makeCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+15551234567');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to make phone call. Please call +1 (555) 123-4567 directly.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to make phone call. Please call +1 (555) 123-4567 directly.')),
      );
    }
  }

  void _emergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: AppConstants.spacing8),
            Text(
              'Emergency Contact',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For urgent parking issues only. Regular support requests should use live chat or email.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacing16),
            Container(
              padding: EdgeInsets.all(AppConstants.spacing12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppConstants.radius8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    '🚨 Emergency Hotline',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing4),
                  Text(
                    '+1 (555) 911-PARK',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _makeCall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _showDetailedGuide({required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.borderLight),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.spacing20),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep({
    required int step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.spacing4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueSection({
    required String title,
    required List<Widget> issues,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing12),
        ...issues,
      ],
    );
  }

  Widget _buildIssueItem({
    required IconData icon,
    required String title,
    required String solution,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing12),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Icon(icon, color: Colors.red.shade600, size: 16),
          ),
          SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.spacing4),
                Text(
                  solution,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSection({
    required String title,
    required List<String> rules,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing8),
        ...rules.map((rule) => Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacing4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Text(
                  rule,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPolicyItem(String condition, String refund) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              condition,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              refund,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Still need help?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildQuickContactButton(
                icon: Icons.chat,
                label: 'Live Chat',
                onTap: _startLiveChat,
              ),
            ),
            SizedBox(width: AppConstants.spacing8),
            Expanded(
              child: _buildQuickContactButton(
                icon: Icons.email,
                label: 'Email',
                onTap: _sendEmail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacing12,
            vertical: AppConstants.spacing8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ctaPrimary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppConstants.radius8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.ctaPrimary),
              SizedBox(width: AppConstants.spacing4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctaPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatInterface() {
    final user = ref.read(authProvider);
    final userId = user?.id ?? 'anonymous_user';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatWidget(userId: userId),
    );
  }

  Widget _buildChatMessage({
    required String message,
    required bool isSupport,
    required String timestamp,
  }) {
    return Align(
      alignment: isSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: AppConstants.spacing12),
        padding: EdgeInsets.all(AppConstants.spacing12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isSupport ? AppColors.secondaryBackground : AppColors.ctaPrimary,
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isSupport ? AppColors.textPrimary : Colors.white,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppConstants.spacing4),
            Text(
              timestamp,
              style: TextStyle(
                color: isSupport ? AppColors.textMuted : Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactForm(String contactType) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppConstants.spacing20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      contactType,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.borderLight),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.spacing20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: subjectController,
                      label: 'Subject',
                      hintText: 'Brief description of your issue',
                    ),
                    SizedBox(height: AppConstants.spacing16),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(AppConstants.radius12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: 'Describe your issue in detail...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(AppConstants.spacing12),
                        ),
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing24),
                    CustomButton(
                      text: 'Send Message',
                      onPressed: () {
                        final subject = subjectController.text.trim();
                        final message = messageController.text.trim();

                        if (subject.isEmpty || message.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please fill in all fields')),
                          );
                          return;
                        }

                        // Simulate sending message
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message sent! We\'ll respond within 24 hours.'),
                            backgroundColor: Colors.green.shade700,
                          ),
                        );
                      },
                      icon: Icons.send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
