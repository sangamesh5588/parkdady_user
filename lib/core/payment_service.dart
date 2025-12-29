
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  late Razorpay _razorpay;

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal() {
    _razorpay = Razorpay();
  }

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void openCheckout({
    required BuildContext context,
    required String key,
    required double amount, // Amount in rupees
    required String name,
    required String description,
    required String orderId,
    required String email,
    required String contact,
    String? logoUrl,
    Map<String, dynamic>? notes,
  }) {
    var options = {
      'key': key,
      'amount': (amount * 100).toInt(), // Amount in paisa
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'email': email,
        'contact': contact,
      },
      'notes': notes ?? {},
      'theme': {
        'color': '#2563EB', // Primary blue color
        'backdrop_color': '#000000',
      },
      'modal': {
        'backdropclose': false,
        'escape': false,
        'confirm_close': true,
        'ondismiss': true,
      },
      'retry': {
        'enabled': false,
      },
      'timeout': 300, // 5 minutes
      'readonly': {
        'email': true,
        'contact': true,
      },
    };

    if (logoUrl != null) {
      options['image'] = logoUrl;
    }

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
    }
  }

  // Create order on backend (you'll need to implement this on your server)
  Future<Map<String, dynamic>?> createOrder({
    required double amount,
    required String currency,
    required Map<String, dynamic> notes,
  }) async {
    try {
      // This is a placeholder - you'll need to implement this on your backend
      // The backend should create an order using Razorpay's Orders API

      const String backendUrl = 'YOUR_BACKEND_URL/create-order'; // Replace with your backend URL

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // Convert to paisa
          'currency': currency,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create order: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  // For testing purposes, create a mock order
  Map<String, dynamic> createMockOrder({
    required double amount,
    required Map<String, dynamic> notes,
  }) {
    const uuid = Uuid();
    final orderId = 'order_${uuid.v4()}';

    return {
      'id': orderId,
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'receipt': orderId,
      'status': 'created',
      'notes': notes,
    };
  }
}

// Provider for PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// Provider for payment state
final paymentStateProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});

class PaymentState {
  final bool isProcessing;
  final String? errorMessage;
  final Map<String, dynamic>? paymentData;

  PaymentState({
    this.isProcessing = false,
    this.errorMessage,
    this.paymentData,
  });

  PaymentState copyWith({
    bool? isProcessing,
    String? errorMessage,
    Map<String, dynamic>? paymentData,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentData: paymentData ?? this.paymentData,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  void startPayment() {
    state = state.copyWith(isProcessing: true, errorMessage: null);
  }

  void paymentSuccess(Map<String, dynamic> data) {
    state = state.copyWith(
      isProcessing: false,
      paymentData: data,
      errorMessage: null,
    );
  }

  void paymentFailed(String error) {
    state = state.copyWith(
      isProcessing: false,
      errorMessage: error,
      paymentData: null,
    );
  }

  void reset() {
    state = PaymentState();
  }
}
