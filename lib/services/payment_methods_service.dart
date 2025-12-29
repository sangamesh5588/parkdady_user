import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Payment Methods Service
/// Handles user payment methods storage with Supabase
class PaymentMethodsService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Get all payment methods for the current user
  Future<List<PaymentMethod>> getUserPaymentMethods() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _supabase
          .from('user_payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PaymentMethod.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payment methods: ${e.toString()}');
    }
  }

  /// Add a new payment method
  Future<PaymentMethod> addPaymentMethod({
    required String type,
    required String displayName,
    String? lastFour,
    String? cardExpiryMonth,
    String? cardExpiryYear,
    String? upiId,
    String? bankName,
    bool isDefault = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'user_id': userId,
        'type': type,
        'display_name': displayName,
        'last_four': lastFour,
        'card_expiry_month': cardExpiryMonth,
        'card_expiry_year': cardExpiryYear,
        'upi_id': upiId,
        'bank_name': bankName,
        'is_default': isDefault,
      };

      final response = await _supabase
          .from('user_payment_methods')
          .insert(data)
          .select()
          .single();

      return PaymentMethod.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add payment method: ${e.toString()}');
    }
  }

  /// Update an existing payment method
  Future<PaymentMethod> updatePaymentMethod({
    required String paymentMethodId,
    String? displayName,
    String? cardExpiryMonth,
    String? cardExpiryYear,
    String? upiId,
    String? bankName,
    bool? isDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (displayName != null) updateData['display_name'] = displayName;
      if (cardExpiryMonth != null) updateData['card_expiry_month'] = cardExpiryMonth;
      if (cardExpiryYear != null) updateData['card_expiry_year'] = cardExpiryYear;
      if (upiId != null) updateData['upi_id'] = upiId;
      if (bankName != null) updateData['bank_name'] = bankName;
      if (isDefault != null) updateData['is_default'] = isDefault;

      final response = await _supabase
          .from('user_payment_methods')
          .update(updateData)
          .eq('id', paymentMethodId)
          .select()
          .single();

      return PaymentMethod.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update payment method: ${e.toString()}');
    }
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _supabase
          .from('user_payment_methods')
          .delete()
          .eq('id', paymentMethodId);
    } catch (e) {
      throw Exception('Failed to delete payment method: ${e.toString()}');
    }
  }

  /// Set a payment method as the default
  Future<PaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First, set all payment methods for the user to not default
      await _supabase
          .from('user_payment_methods')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Then set the specified payment method as default
      final response = await _supabase
          .from('user_payment_methods')
          .update({'is_default': true})
          .eq('id', paymentMethodId)
          .select()
          .single();

      return PaymentMethod.fromJson(response);
    } catch (e) {
      throw Exception('Failed to set default payment method: ${e.toString()}');
    }
  }

  /// Get a specific payment method by ID
  Future<PaymentMethod?> getPaymentMethodById(String paymentMethodId) async {
    try {
      final response = await _supabase
          .from('user_payment_methods')
          .select()
          .eq('id', paymentMethodId)
          .maybeSingle();

      if (response == null) return null;
      return PaymentMethod.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch payment method: ${e.toString()}');
    }
  }

  /// Get the default payment method for the current user
  Future<PaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return PaymentMethod.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch default payment method: ${e.toString()}');
    }
  }

  /// Get real-time stream of user payment methods
  Stream<List<PaymentMethod>> watchUserPaymentMethods() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('user_payment_methods')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => PaymentMethod.fromJson(json)).toList());
  }
}

/// Payment Method Model
class PaymentMethod {
  final String id;
  final String userId;
  final String type; // 'card', 'upi', 'netbanking'
  final String displayName;
  final String? lastFour;
  final String? cardExpiryMonth;
  final String? cardExpiryYear;
  final String? upiId;
  final String? bankName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    this.lastFour,
    this.cardExpiryMonth,
    this.cardExpiryYear,
    this.upiId,
    this.bankName,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from JSON (database response)
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      displayName: json['display_name'],
      lastFour: json['last_four'],
      cardExpiryMonth: json['card_expiry_month'],
      cardExpiryYear: json['card_expiry_year'],
      upiId: json['upi_id'],
      bankName: json['bank_name'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'display_name': displayName,
      'last_four': lastFour,
      'card_expiry_month': cardExpiryMonth,
      'card_expiry_year': cardExpiryYear,
      'upi_id': upiId,
      'bank_name': bankName,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get icon for payment method type
  IconData get icon {
    switch (type) {
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance_wallet;
      case 'netbanking':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  /// Get masked display for sensitive information
  String get maskedDisplay {
    if (type == 'card' && lastFour != null) {
      return '•••• •••• •••• $lastFour';
    }
    return displayName;
  }

  /// Create a copy with updated values
  PaymentMethod copyWith({
    String? id,
    String? userId,
    String? type,
    String? displayName,
    String? lastFour,
    String? cardExpiryMonth,
    String? cardExpiryYear,
    String? upiId,
    String? bankName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      lastFour: lastFour ?? this.lastFour,
      cardExpiryMonth: cardExpiryMonth ?? this.cardExpiryMonth,
      cardExpiryYear: cardExpiryYear ?? this.cardExpiryYear,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
