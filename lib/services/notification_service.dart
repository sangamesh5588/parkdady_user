import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Notification Service
/// Handles user notification preferences with Supabase
class NotificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Notification preferences data class
  static NotificationPreferences defaultPreferences = const NotificationPreferences(
    bookingConfirmations: true,
    bookingReminders: true,
    paymentUpdates: true,
    parkingUpdates: false,
    promotions: false,
    accountUpdates: true,
  );
}

/// Notification preferences model
class NotificationPreferences {
  final bool bookingConfirmations;
  final bool bookingReminders;
  final bool paymentUpdates;
  final bool parkingUpdates;
  final bool promotions;
  final bool accountUpdates;

  const NotificationPreferences({
    required this.bookingConfirmations,
    required this.bookingReminders,
    required this.paymentUpdates,
    required this.parkingUpdates,
    required this.promotions,
    required this.accountUpdates,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'booking_confirmations': bookingConfirmations,
      'booking_reminders': bookingReminders,
      'payment_updates': paymentUpdates,
      'parking_updates': parkingUpdates,
      'promotions': promotions,
      'account_updates': accountUpdates,
    };
  }

  /// Create from JSON (database response)
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      bookingConfirmations: json['booking_confirmations'] ?? true,
      bookingReminders: json['booking_reminders'] ?? true,
      paymentUpdates: json['payment_updates'] ?? true,
      parkingUpdates: json['parking_updates'] ?? false,
      promotions: json['promotions'] ?? false,
      accountUpdates: json['account_updates'] ?? true,
    );
  }

  /// Create a copy with updated values
  NotificationPreferences copyWith({
    bool? bookingConfirmations,
    bool? bookingReminders,
    bool? paymentUpdates,
    bool? parkingUpdates,
    bool? promotions,
    bool? accountUpdates,
  }) {
    return NotificationPreferences(
      bookingConfirmations: bookingConfirmations ?? this.bookingConfirmations,
      bookingReminders: bookingReminders ?? this.bookingReminders,
      paymentUpdates: paymentUpdates ?? this.paymentUpdates,
      parkingUpdates: parkingUpdates ?? this.parkingUpdates,
      promotions: promotions ?? this.promotions,
      accountUpdates: accountUpdates ?? this.accountUpdates,
    );
  }
}

/// Notification Service Implementation
class NotificationServiceImpl implements NotificationService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get user notification preferences
  Future<NotificationPreferences> getUserPreferences() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return NotificationService.defaultPreferences;
      }

      final response = await _supabase
          .from('user_notification_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences if none exist
        await _createDefaultPreferences(userId);
        return NotificationService.defaultPreferences;
      }

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      // Return defaults on error
      return NotificationService.defaultPreferences;
    }
  }

  /// Update user notification preferences
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = preferences.toJson();
      data['user_id'] = userId;

      final response = await _supabase
          .from('user_notification_preferences')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update notification preferences: ${e.toString()}');
    }
  }

  /// Create default preferences for new user
  Future<void> _createDefaultPreferences(String userId) async {
    try {
      final data = NotificationService.defaultPreferences.toJson();
      data['user_id'] = userId;

      await _supabase
          .from('user_notification_preferences')
          .insert(data);
    } catch (e) {
      // Ignore errors when creating defaults
    }
  }

  /// Reset preferences to defaults
  Future<NotificationPreferences> resetToDefaults() async {
    final defaults = NotificationService.defaultPreferences;
    return await updatePreferences(defaults);
  }
}
