import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/user.dart';
import '../../../services/notification_service.dart';
import '../../providers/auth_provider.dart';

class NotificationSetting {
  final String id;
  final String title;
  final String description;
  final bool isEnabled;
  final IconData icon;

  const NotificationSetting({
    required this.id,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.icon,
  });

  NotificationSetting copyWith({
    String? id,
    String? title,
    String? description,
    bool? isEnabled,
    IconData? icon,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      icon: icon ?? this.icon,
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final NotificationServiceImpl _notificationService = NotificationServiceImpl();
  List<NotificationSetting> _settings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    if (!mounted) return;

    try {
      final preferences = await _notificationService.getUserPreferences();

      final settings = [
        NotificationSetting(
          id: 'booking_confirmations',
          title: 'Booking Confirmations',
          description: 'Get notified when bookings are confirmed',
          isEnabled: preferences.bookingConfirmations,
          icon: Icons.confirmation_number,
        ),
        NotificationSetting(
          id: 'booking_reminders',
          title: 'Booking Reminders',
          description: 'Reminders before your booking starts',
          isEnabled: preferences.bookingReminders,
          icon: Icons.schedule,
        ),
        NotificationSetting(
          id: 'payment_updates',
          title: 'Payment Updates',
          description: 'Notifications about payments and receipts',
          isEnabled: preferences.paymentUpdates,
          icon: Icons.payment,
        ),
        NotificationSetting(
          id: 'parking_updates',
          title: 'Parking Updates',
          description: 'Updates about parking space availability',
          isEnabled: preferences.parkingUpdates,
          icon: Icons.local_parking,
        ),
        NotificationSetting(
          id: 'promotions',
          title: 'Promotions & Offers',
          description: 'Special offers and promotional updates',
          isEnabled: preferences.promotions,
          icon: Icons.local_offer,
        ),
        NotificationSetting(
          id: 'account_updates',
          title: 'Account Updates',
          description: 'Security and account-related notifications',
          isEnabled: preferences.accountUpdates,
          icon: Icons.security,
        ),
      ];

      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load notification preferences');
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      final preferences = NotificationPreferences(
        bookingConfirmations: _settings.firstWhere((s) => s.id == 'booking_confirmations').isEnabled,
        bookingReminders: _settings.firstWhere((s) => s.id == 'booking_reminders').isEnabled,
        paymentUpdates: _settings.firstWhere((s) => s.id == 'payment_updates').isEnabled,
        parkingUpdates: _settings.firstWhere((s) => s.id == 'parking_updates').isEnabled,
        promotions: _settings.firstWhere((s) => s.id == 'promotions').isEnabled,
        accountUpdates: _settings.firstWhere((s) => s.id == 'account_updates').isEnabled,
      );

      await _notificationService.updatePreferences(preferences);
    } catch (e) {
      _showErrorSnackBar('Failed to save notification preferences');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'Notifications',
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.ctaPrimary,
                ),
              )
            : _settings.isEmpty
                ? Center(
                    child: Text(
                      'No notification settings available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(AppConstants.spacing16),
                    itemCount: _settings.length,
                    itemBuilder: (context, index) {
                      final setting = _settings[index];
                      return _buildNotificationSettingCard(setting);
                    },
                  ),
      ),
    );
  }

  Widget _buildNotificationSettingCard(NotificationSetting setting) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing8),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [AppColors.lightShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            child: Icon(
              setting.icon,
              color: setting.isEnabled ? AppColors.ctaPrimary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          SizedBox(width: AppConstants.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppConstants.spacing4),
                Text(
                  setting.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: setting.isEnabled,
            onChanged: (value) => _toggleSetting(setting, value),
            activeColor: AppColors.ctaPrimary,
          ),
        ],
      ),
    );
  }

  void _toggleSetting(NotificationSetting setting, bool isEnabled) async {
    setState(() {
      final index = _settings.indexWhere((s) => s.id == setting.id);
      if (index != -1) {
        _settings[index] = setting.copyWith(isEnabled: isEnabled);
      }
    });

    // Save preferences to backend
    await _saveNotificationPreferences();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${setting.title} ${isEnabled ? 'enabled' : 'disabled'}',
        ),
      ),
    );
  }
}
