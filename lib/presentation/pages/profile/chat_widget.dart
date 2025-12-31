import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../core/config.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? agentName;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.agentName,
  });
}

class ChatWidget extends StatefulWidget {
  final String userId;

  const ChatWidget({super.key, required this.userId});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _chatId;
  bool _isTyping = false;
  int _retryCount = 0;

  // Animation controller for typing dots
  late AnimationController _typingAnimationController;

  // Use dynamic chat service URL from config
  String get _chatServiceUrl => AppConfig.activeChatServiceUrl;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      content: "Hi! I'm here to help you with any questions about parking bookings. How can I assist you today?",
      isUser: false,
      timestamp: DateTime.now(),
      agentName: "Support Bot",
    ));
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          content: message,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _isTyping = true;
        _isLoading = true;
      });
    }

    _messageController.clear();
    _scrollToBottom();

    // Retry logic with exponential backoff
    for (int attempt = 0; attempt <= AppConfig.maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$_chatServiceUrl/chat'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'user_id': widget.userId,
                'message': message,
                'chat_id': _chatId,
              }),
            )
            .timeout(AppConfig.chatTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _chatId = data['chat_id'];
              _retryCount = 0; // Reset retry count on success

              // Add bot response
              _messages.add(ChatMessage(
                content: data['response'],
                isUser: false,
                timestamp: DateTime.now(),
                agentName: data['escalated'] == true ? "Support Agent" : "Support Bot",
              ));

              // Handle escalation
              if (data['escalated'] == true && data['agent_contact_info'] != null) {
                _messages.add(ChatMessage(
                  content: "🔄 Connecting you to ${data['agent_contact_info']['name']} from ${data['agent_contact_info']['department']}...",
                  isUser: false,
                  timestamp: DateTime.now(),
                  agentName: "System",
                ));

                if (data['suggested_actions'] != null) {
                  _messages.add(ChatMessage(
                    content: "💡 Suggested actions: ${data['suggested_actions'].join(', ')}",
                    isUser: false,
                    timestamp: DateTime.now(),
                    agentName: "System",
                  ));
                }
              }
            });
          }
          break; // Success, exit retry loop
        } else if (response.statusCode >= 500 && attempt < AppConfig.maxRetries) {
          // Server error, retry
          if (AppConfig.enableLogging) {
            print('Server error (${response.statusCode}), retrying... Attempt ${attempt + 1}');
          }
          await Future.delayed(AppConfig.retryDelay * (attempt + 1));
          continue;
        } else {
          // Client error or final retry failed
          _showErrorMessage('Failed to send message (${response.statusCode}). Please try again.');
          break;
        }
      } on http.ClientException catch (e) {
        if (attempt < AppConfig.maxRetries) {
          if (AppConfig.enableLogging) {
            print('Network error, retrying... Attempt ${attempt + 1}: $e');
          }
          await Future.delayed(AppConfig.retryDelay * (attempt + 1));
          continue;
        } else {
          _showErrorMessage('Unable to connect to chat service. Please check your internet connection.');
          if (AppConfig.enableLogging) {
            print('Chat network error after retries: $e');
          }
          break;
        }
      } catch (e) {
        if (AppConfig.enableLogging) {
          print('Chat error: $e');
        }
        _showErrorMessage('An unexpected error occurred. Please try again.');
        break;
      }
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          content: "❌ $message",
          isUser: false,
          timestamp: DateTime.now(),
          agentName: "System",
        ));
      });
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
        bottom: AppConstants.spacing8,
      ),
      child: Row(
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
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessage(_messages[index]);
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
                      height: 48,
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
                        maxLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.ctaPrimary,
                                AppColors.ctaPrimary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isLoading ? AppColors.textMuted : null,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _isLoading
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
                      onPressed: _isLoading
                          ? null
                          : () => _sendMessage(_messageController.text),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
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
