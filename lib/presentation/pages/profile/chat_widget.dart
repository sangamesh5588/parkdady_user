import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../services/booking_service.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? agentName;
  final List<String>? quickReplies;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.agentName,
    this.quickReplies,
  });
}

class ChatWidget extends ConsumerStatefulWidget {
  final String userId;

  const ChatWidget({super.key, required this.userId});

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  List<Booking> _userBookings = [];
  bool _showQuickQuestions = true;

  // Animation controller for typing dots
  late AnimationController _typingAnimationController;

  // Pre-selected question categories
  final List<Map<String, dynamic>> _quickQuestions = [
    {'icon': Icons.calendar_today, 'text': 'My Bookings', 'query': 'bookings'},
    {'icon': Icons.cancel, 'text': 'Cancellation', 'query': 'cancellation'},
    {'icon': Icons.currency_rupee, 'text': 'Refund Status', 'query': 'refund'},
    {'icon': Icons.help_outline, 'text': 'How It Works', 'query': 'how_it_works'},
    {'icon': Icons.payment, 'text': 'Payment Help', 'query': 'payment'},
    {'icon': Icons.support_agent, 'text': 'Contact Support', 'query': 'contact'},
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadUserBookings();
    _addWelcomeMessage();
  }

  Future<void> _loadUserBookings() async {
    try {
      final bookingService = BookingService();
      final bookings = await bookingService.getUserBookings();
      if (mounted) {
        setState(() {
          _userBookings = bookings;
        });
      }
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      content: "👋 Hi! I'm your Park Daddy support assistant. I can help you with bookings, cancellations, refunds, and more. What would you like to know?",
      isUser: false,
      timestamp: DateTime.now(),
      agentName: "Support Bot",
    ));
  }

  Future<void> _handleQuickQuestion(String query) async {
    setState(() {
      _showQuickQuestions = false;
    });

    // Add user's query as a message
    final questionText = _quickQuestions.firstWhere((q) => q['query'] == query)['text'] as String;
    _addUserMessage(questionText);

    // Show typing indicator
    setState(() => _isTyping = true);
    _scrollToBottom();

    // Simulate thinking time
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate response based on query
    switch (query) {
      case 'bookings':
        await _handleBookingsQuery();
        break;
      case 'cancellation':
        await _handleCancellationQuery();
        break;
      case 'refund':
        await _handleRefundQuery();
        break;
      case 'how_it_works':
        await _handleHowItWorksQuery();
        break;
      case 'payment':
        await _handlePaymentQuery();
        break;
      case 'contact':
        await _handleContactQuery();
        break;
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _addBotMessage(String text, {List<String>? quickReplies}) {
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: false,
        timestamp: DateTime.now(),
        agentName: "Support Bot",
        quickReplies: quickReplies,
      ));
    });
  }

  Future<void> _handleBookingsQuery() async {
    if (_userBookings.isEmpty) {
      _addBotMessage(
        "📋 You don't have any bookings yet.\n\nWould you like to:\n• Browse parking spaces near you\n• Learn how to make a booking",
        quickReplies: ['Browse Spaces', 'How to Book'],
      );
    } else {
      final active = _userBookings.where((b) => b.bookingStatus == 'active' || b.bookingStatus == 'confirmed').toList();
      final pending = _userBookings.where((b) => b.bookingStatus == 'pending').toList();
      final completed = _userBookings.where((b) => b.bookingStatus == 'completed').toList();

      String response = "📋 Here's your booking summary:\n\n";

      if (active.isNotEmpty) {
        response += "✅ Active Bookings: ${active.length}\n";
        for (var booking in active.take(2)) {
          response += "   • ${booking.parkingSpaceName}\n     ${_formatBookingTime(booking)}\n";
        }
      }

      if (pending.isNotEmpty) {
        response += "\n⏳ Pending Bookings: ${pending.length}\n";
        for (var booking in pending.take(2)) {
          response += "   • ${booking.parkingSpaceName}\n     ${_formatBookingTime(booking)}\n";
        }
      }

      if (completed.isNotEmpty) {
        response += "\n📅 Completed: ${completed.length} bookings\n";
      }

      response += "\nWhat would you like to do?";

      _addBotMessage(response, quickReplies: ['Cancel a Booking', 'View All Bookings', 'Contact Support']);
    }
  }

  String _formatBookingTime(Booking booking) {
    final date = booking.bookingDate;
    final entry = booking.requestedEntryTime;
    final exit = booking.requestedExitTime;

    if (entry != null && exit != null) {
      return "${date.day}/${date.month} • ${entry.format(context)} - ${exit.format(context)}";
    }
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _handleCancellationQuery() async {
    final activeBookings = _userBookings.where((b) =>
      b.bookingStatus == 'active' || b.bookingStatus == 'pending' || b.bookingStatus == 'confirmed'
    ).toList();

    if (activeBookings.isEmpty) {
      _addBotMessage(
        "ℹ️ You don't have any active bookings to cancel.\n\n📌 Cancellation Policy:\n• Free cancellation up to 1 hour before arrival\n• Cancellations within 1 hour: Platform fee (₹9) is non-refundable\n• After check-in: No refund available\n\nNeed help with something else?",
        quickReplies: ['My Bookings', 'Refund Status', 'Contact Support'],
      );
    } else {
      String response = "🔄 You have ${activeBookings.length} booking(s) that can be cancelled:\n\n";

      for (var i = 0; i < activeBookings.take(3).length; i++) {
        final booking = activeBookings[i];
        response += "${i + 1}. ${booking.parkingSpaceName}\n";
        response += "   ${_formatBookingTime(booking)}\n";
        response += "   Amount: ₹${booking.totalWithPlatformFee.toStringAsFixed(2)}\n\n";
      }

      response += "📌 Cancellation Policy:\n";
      response += "• Free cancellation up to 1 hour before arrival\n";
      response += "• Within 1 hour: Platform fee (₹9) is non-refundable\n";
      response += "• After check-in: No refund\n\n";
      response += "To cancel a booking, please go to 'My Bookings' and select the booking you want to cancel.";

      _addBotMessage(response, quickReplies: ['Go to My Bookings', 'Contact Support']);
    }
  }

  Future<void> _handleRefundQuery() async {
    final cancelledBookings = _userBookings.where((b) => b.bookingStatus == 'cancelled').toList();

    if (cancelledBookings.isEmpty) {
      _addBotMessage(
        "ℹ️ You don't have any cancelled bookings.\n\n💰 Refund Policy:\n• Cancellations 1+ hour before: Full refund (3-5 business days)\n• Cancellations within 1 hour: Parking fee refunded, platform fee (₹9) non-refundable\n• After check-in: No refund\n\nHave another question?",
        quickReplies: ['My Bookings', 'Cancellation Policy', 'Contact Support'],
      );
    } else {
      String response = "💰 Your cancelled bookings:\n\n";

      for (var booking in cancelledBookings.take(3)) {
        response += "• ${booking.parkingSpaceName}\n";
        response += "  Amount: ₹${booking.totalWithPlatformFee.toStringAsFixed(2)}\n";
        response += "  Status: ${booking.paymentStatus == 'refunded' ? '✅ Refunded' : '⏳ Processing'}\n\n";
      }

      response += "💡 Refunds typically take 3-5 business days to appear in your account.\n\n";
      response += "If you haven't received your refund after 5 business days, please contact our support team.";

      _addBotMessage(response, quickReplies: ['Contact Support', 'View All Bookings']);
    }
  }

  Future<void> _handleHowItWorksQuery() async {
    _addBotMessage(
      "🎯 How Park Daddy Works:\n\n"
      "1️⃣ Find Parking\n"
      "   • Search by location\n"
      "   • View available spots on map\n"
      "   • Check rates & amenities\n\n"
      "2️⃣ Book Your Spot\n"
      "   • Select date & time\n"
      "   • Choose vehicle type\n"
      "   • Make secure payment\n\n"
      "3️⃣ Get QR Code\n"
      "   • Receive booking confirmation\n"
      "   • Get unique QR code\n"
      "   • Save for easy access\n\n"
      "4️⃣ Park & Go\n"
      "   • Show QR at entry\n"
      "   • Park your vehicle\n"
      "   • Show QR at exit\n\n"
      "Need help with anything specific?",
      quickReplies: ['Make a Booking', 'Payment Methods', 'Contact Support'],
    );
  }

  Future<void> _handlePaymentQuery() async {
    _addBotMessage(
      "💳 Payment Information:\n\n"
      "Accepted Payment Methods:\n"
      "• Credit/Debit Cards (Visa, MasterCard, RuPay)\n"
      "• UPI (Google Pay, PhonePe, Paytm)\n"
      "• Net Banking\n"
      "• Wallets (Paytm, MobiKwik)\n\n"
      "💰 Pricing:\n"
      "• Parking Fee: Based on location & duration\n"
      "• Platform Fee: ₹9.00 (fixed)\n"
      "• Total = Parking Fee + Platform Fee\n\n"
      "🔒 All payments are 100% secure and encrypted.\n\n"
      "Payment Issues?\n"
      "• Check internet connection\n"
      "• Verify card/UPI details\n"
      "• Try different payment method\n\n"
      "Still facing issues?",
      quickReplies: ['Contact Support', 'My Bookings', 'Refund Policy'],
    );
  }

  Future<void> _handleContactQuery() async {
    _addBotMessage(
      "📞 Contact Our Support Team:\n\n"
      "📧 Email: support@parkdaddy.com\n"
      "⏰ Response Time: Within 24 hours\n\n"
      "For faster assistance, please include:\n"
      "• Your booking ID (if applicable)\n"
      "• Detailed description of your issue\n"
      "• Screenshots (if relevant)\n\n"
      "Would you like to send an email now?",
      quickReplies: ['Send Email', 'Back to Menu'],
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _showQuickQuestions = false;
    });

    _addUserMessage(message);
    _messageController.clear();

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simple keyword-based response
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('booking') || lowerMessage.contains('book')) {
      await _handleBookingsQuery();
    } else if (lowerMessage.contains('cancel')) {
      await _handleCancellationQuery();
    } else if (lowerMessage.contains('refund') || lowerMessage.contains('money')) {
      await _handleRefundQuery();
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('pay')) {
      await _handlePaymentQuery();
    } else if (lowerMessage.contains('how') || lowerMessage.contains('work')) {
      await _handleHowItWorksQuery();
    } else if (lowerMessage.contains('email') || lowerMessage.contains('contact') || lowerMessage.contains('support')) {
      await _handleContactQuery();
    } else {
      // Default response for unrecognized queries
      _addBotMessage(
        "I'm here to help! I can assist you with:\n\n"
        "• Viewing your bookings\n"
        "• Cancellation policy\n"
        "• Refund status\n"
        "• How Park Daddy works\n"
        "• Payment methods\n\n"
        "For detailed assistance, please email us at support@parkdaddy.com and we'll respond within 24 hours.",
        quickReplies: ['My Bookings', 'Contact Support', 'How It Works'],
      );
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<void> _handleQuickReply(String reply) async {
    _addUserMessage(reply);

    setState(() => _isTyping = true);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    final lowerReply = reply.toLowerCase();

    if (lowerReply.contains('browse') || lowerReply.contains('spaces')) {
      _addBotMessage(
        "🏠 To browse parking spaces:\n\n"
        "1. Tap the Home icon in bottom navigation\n"
        "2. Enter your destination or use current location\n"
        "3. View available spaces on map or list\n"
        "4. Tap any space to see details and book\n\n"
        "Happy parking! 🚗",
      );
    } else if (lowerReply.contains('book')) {
      await _handleHowItWorksQuery();
    } else if (lowerReply.contains('cancel')) {
      if (mounted) {
        Navigator.of(context).pop(); // Close chat
      }
      // User should navigate to bookings page
    } else if (lowerReply.contains('view all') || lowerReply.contains('my bookings')) {
      _addBotMessage(
        "📱 To view all your bookings:\n\n"
        "Tap the 'Bookings' icon in the bottom navigation bar.\n\n"
        "You'll see all your active, pending, completed, and cancelled bookings there.",
      );
    } else if (lowerReply.contains('email') || lowerReply.contains('send')) {
      await _launchEmail();
    } else if (lowerReply.contains('back') || lowerReply.contains('menu')) {
      setState(() {
        _showQuickQuestions = true;
      });
      _addBotMessage(
        "🏠 Back to main menu. What would you like to know?",
      );
    } else {
      await _sendMessage(reply);
    }

    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@parkdaddy.com',
      queryParameters: {
        'subject': 'Support Request - Park Daddy',
        'body': 'Hi,\n\nUser ID: ${widget.userId}\n\nI need help with:\n\n[Please describe your issue]\n\nThank you!',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _addBotMessage(
          "✅ Email client opened! We'll respond within 24 hours.",
        );
      } else {
        _addBotMessage(
          "📧 Please email us at: support@parkdaddy.com\n\n"
          "Include your User ID: ${widget.userId}",
        );
      }
    } catch (e) {
      _addBotMessage(
        "📧 Please email us at: support@parkdaddy.com",
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60.0 : AppConstants.spacing16,
        right: isUser ? AppConstants.spacing16 : 60.0,
        top: AppConstants.spacing8,
        bottom: message.quickReplies != null ? AppConstants.spacing4 : AppConstants.spacing8,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bot avatar on left
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ctaPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    message.agentName == "Support Agent" ? Icons.person : Icons.smart_toy,
                    color: AppColors.ctaPrimary,
                    size: 18,
                  ),
                ),
                SizedBox(width: AppConstants.spacing8),
              ],

              // Message bubble
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing16,
                    vertical: AppConstants.spacing12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.ctaPrimary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radius20),
                      topRight: Radius.circular(AppConstants.radius20),
                      bottomLeft: isUser ? Radius.circular(AppConstants.radius20) : Radius.circular(AppConstants.radius4),
                      bottomRight: isUser ? Radius.circular(AppConstants.radius4) : Radius.circular(AppConstants.radius20),
                    ),
                    border: isUser ? null : Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.ctaPrimary.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.agentName != null && !isUser)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppConstants.spacing4),
                          child: Text(
                            message.agentName!,
                            style: TextStyle(
                              fontSize: AppConstants.fontSize12,
                              fontWeight: AppConstants.fontWeightSemiBold,
                              color: AppColors.ctaPrimary,
                            ),
                          ),
                        ),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser ? Colors.white : AppColors.textPrimary,
                          fontSize: AppConstants.fontSize14,
                          height: 1.5,
                          fontWeight: AppConstants.fontWeightRegular,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: isUser ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                          fontSize: AppConstants.fontSize10,
                          fontWeight: AppConstants.fontWeightRegular,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // User avatar on right
              if (isUser) ...[
                SizedBox(width: AppConstants.spacing8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ctaPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),

          // Quick replies
          if (message.quickReplies != null && message.quickReplies!.isNotEmpty) ...[
            SizedBox(height: AppConstants.spacing8),
            Wrap(
              spacing: AppConstants.spacing8,
              runSpacing: AppConstants.spacing8,
              children: message.quickReplies!.map((reply) {
                return InkWell(
                  onTap: () => _handleQuickReply(reply),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing12,
                      vertical: AppConstants.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(AppConstants.radius20),
                      border: Border.all(color: AppColors.ctaPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      reply,
                      style: TextStyle(
                        fontSize: AppConstants.fontSize12,
                        color: AppColors.ctaPrimary,
                        fontWeight: AppConstants.fontWeightSemiBold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.spacing16,
        right: 60.0,
        top: AppConstants.spacing8,
        bottom: AppConstants.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.smart_toy,
              color: AppColors.ctaPrimary,
              size: 18,
            ),
          ),
          SizedBox(width: AppConstants.spacing8),

          // Typing bubble
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radius20),
                topRight: Radius.circular(AppConstants.radius20),
                bottomRight: Radius.circular(AppConstants.radius20),
                bottomLeft: Radius.circular(AppConstants.radius4),
              ),
              border: Border.all(
                color: AppColors.borderLight.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: AppConstants.spacing4),
                _buildTypingDot(1),
                SizedBox(width: AppConstants.spacing4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        // Stagger the animation for each dot
        final delay = index * 0.2;
        final animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _typingAnimationController,
            curve: Interval(
              delay,
              delay + 0.4,
              curve: Curves.easeInOut,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, -6 * animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withValues(alpha: 0.3 + 0.7 * animation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickQuestions() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      child: Wrap(
        spacing: AppConstants.spacing12,
        runSpacing: AppConstants.spacing12,
        children: _quickQuestions.map((question) {
          return InkWell(
            onTap: () => _handleQuickQuestion(question['query'] as String),
            borderRadius: BorderRadius.circular(AppConstants.radius12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radius12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    question['icon'] as IconData,
                    size: 18,
                    color: AppColors.ctaPrimary,
                  ),
                  SizedBox(width: AppConstants.spacing8),
                  Text(
                    question['text'] as String,
                    style: TextStyle(
                      fontSize: AppConstants.fontSize14,
                      fontWeight: AppConstants.fontWeightMedium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.ctaPrimary,
                        AppColors.ctaPrimary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ctaPrimary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Chat',
                        style: TextStyle(
                          fontSize: AppConstants.fontSize18,
                          fontWeight: AppConstants.fontWeightSemiBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isTyping ? AppColors.ctaPrimary : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: AppConstants.spacing8),
                          Text(
                            _isTyping ? 'Typing...' : 'Online',
                            style: TextStyle(
                              fontSize: AppConstants.fontSize12,
                              color: AppColors.textSecondary,
                              fontWeight: AppConstants.fontWeightRegular,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: AppConstants.spacing16),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_showQuickQuestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (_showQuickQuestions && index == 0) {
                  return _buildQuickQuestions();
                }

                final messageIndex = _showQuickQuestions ? index - 1 : index;

                if (messageIndex < _messages.length) {
                  return _buildMessage(_messages[messageIndex]);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: AppConstants.fontSize14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: AppConstants.fontSize14,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _isTyping ? null : _sendMessage,
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.ctaPrimary,
                                AppColors.ctaPrimary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isTyping ? AppColors.textMuted : null,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _isTyping
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.ctaPrimary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: IconButton(
                      onPressed: _isTyping
                          ? null
                          : () => _sendMessage(_messageController.text),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isTyping ? Icons.hourglass_empty : Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
}
