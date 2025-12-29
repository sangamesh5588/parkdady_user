import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/config.dart';
import '../../../core/constants.dart';
import '../../../core/payment_service.dart';
import '../../../core/qr_service.dart';
import '../../../domain/entities/parking_space.dart';
import '../../../services/booking_service.dart';
import '../../widgets/custom_button.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final ParkingSpace parkingSpace;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalPrice;
  final dynamic existingBooking; // Booking already created in pending status

  const PaymentScreen({
    super.key,
    required this.parkingSpace,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.existingBooking, // Optional - if null, will create new booking
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessingPayment = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Pay with Visa, Mastercard, or RuPay',
    },
    {
      'id': 'upi',
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'description': 'Pay using UPI apps like Google Pay, PhonePe',
    },
    {
      'id': 'wallet',
      'name': 'Digital Wallet',
      'icon': Icons.account_balance,
      'description': 'Paytm, Mobikwik, Ola Money',
    },
    {
      'id': 'netbanking',
      'name': 'Net Banking',
      'icon': Icons.language,
      'description': 'Pay through your bank account',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize Razorpay
    final paymentService = ref.read(paymentServiceProvider);
    paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    final paymentService = ref.read(paymentServiceProvider);
    paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Payment',
          style: TextStyle(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: AppColors.getPrimaryText(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order summary
            _buildOrderSummary(context),

            SizedBox(height: AppConstants.spacing16),

            // Payment methods
            Expanded(
              child: _buildPaymentMethods(context),
            ),

            // Bottom action bar
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppConstants.spacing16),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Parking details
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ctaPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
                ),
                child: Icon(
                  Icons.local_parking,
                  color: AppColors.ctaPrimary,
                  size: 24,
                ),
              ),
              SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parkingSpace.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getPrimaryText(context),
                      ),
                    ),
                    Text(
                      '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year} • ${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Total amount
          Container(
            padding: EdgeInsets.all(AppConstants.spacing12),
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                Text(
                  '₹${widget.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppConstants.spacing16),
            child: Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ),

          // Payment method options
          ..._paymentMethods.map((method) => _buildPaymentMethodOption(context, method)),

          // Secure payment notice
          Container(
            padding: EdgeInsets.all(AppConstants.spacing16),
            margin: EdgeInsets.only(top: AppConstants.spacing8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              border: Border(
                top: BorderSide(
                  color: Colors.green.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  size: 20,
                  color: Colors.green,
                ),
                SizedBox(width: AppConstants.spacing8),
                Expanded(
                  child: Text(
                    'Your payment is secured with 256-bit SSL encryption',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
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

  Widget _buildPaymentMethodOption(BuildContext context, Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = method['id']),
      child: Container(
        padding: EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.divider.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.ctaPrimary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                      margin: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.ctaPrimary,
                      ),
                    )
                  : null,
            ),

            SizedBox(width: AppConstants.spacing12),

            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.ctaPrimary.withOpacity(0.1)
                    : AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppConstants.radius8),
              ),
              child: Icon(
                method['icon'],
                color: isSelected ? AppColors.ctaPrimary : AppColors.getSecondaryText(context),
                size: 20,
              ),
            ),

            SizedBox(width: AppConstants.spacing12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing4),
                  Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.ctaPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TEST MODE: Prominent test button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Column(
              children: [
                Icon(Icons.science, color: Colors.orange, size: 24),
                SizedBox(height: 4),
                Text(
                  'TEST MODE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isProcessingPayment ? null : () => _handleTestBooking(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: Text(
                    'Create Booking Without Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: AppConstants.spacing16),

          // Regular payment button (disabled for testing)
          Opacity(
            opacity: 0.5,
            child: CustomButton(
              text: 'Pay ₹${widget.totalPrice.toStringAsFixed(2)} (Disabled)',
              onPressed: null, // Disabled during testing
              icon: Icons.lock,
            ),
          ),
        ],
      ),
    );
  }

  // TEST MODE: Create booking without payment
  void _handleTestBooking(BuildContext context) async {
    debugPrint('🧪 TEST MODE: Creating booking without payment');

    // Simulate payment success response
    final mockResponse = PaymentSuccessResponse(
      'test_payment_${DateTime.now().millisecondsSinceEpoch}',
      'test_order_${DateTime.now().millisecondsSinceEpoch}',
      'test_signature',
      null, // orderId can be null
    );

    _handlePaymentSuccess(mockResponse);
  }

  void _handlePayment(BuildContext context) async {
    setState(() => _isProcessingPayment = true);

    try {
      // Create order
      final paymentService = ref.read(paymentServiceProvider);
      final orderData = paymentService.createMockOrder(
        amount: widget.totalPrice,
        notes: {
          'parking_space_id': widget.parkingSpace.id,
          'booking_date': widget.selectedDate.toIso8601String(),
          'start_time': '${widget.startTime.hour}:${widget.startTime.minute}',
          'end_time': '${widget.endTime.hour}:${widget.endTime.minute}',
        },
      );

      // Open Razorpay checkout
      paymentService.openCheckout(
        context: context,
        key: AppConfig.razorpayKey,
        amount: widget.totalPrice,
        name: 'Parking App',
        description: 'Parking Booking Payment',
        orderId: orderData['id'],
        email: 'user@example.com', // Replace with actual user email
        contact: '9999999999', // Replace with actual user contact
      );

    } catch (e) {
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment initialization failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('💳 PAYMENT SUCCESS! Payment ID: ${response.paymentId}');

    try {
      // Create booking service instance
      final bookingService = BookingService();

      // Calculate duration in hours
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.startTime.hour,
        widget.startTime.minute,
      );

      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        widget.endTime.hour,
        widget.endTime.minute,
      );

      final durationHours = endDateTime.difference(startDateTime).inHours;

      dynamic booking;

      // Check if booking already exists (created in booking confirmation screen)
      if (widget.existingBooking != null) {
        debugPrint('✔️ Using existing booking ID: ${widget.existingBooking.id}');
        debugPrint('✔️ Confirming booking with payment...');

        // Just confirm the existing booking with payment details
        await bookingService.confirmBooking(
          widget.existingBooking.id,
          transactionId: response.paymentId,
          qrCode: QRService.generateBookingQR(
            bookingId: widget.existingBooking.id,
            parkingSpaceId: widget.parkingSpace.id,
            userId: widget.existingBooking.renterId,
            hostId: widget.existingBooking.hostId,
            startTime: startDateTime,
            endTime: endDateTime,
            vehicleNumber: widget.existingBooking.vehicleType,
            totalAmount: widget.totalPrice,
          ),
        );

        booking = widget.existingBooking;
      } else {
        // Old flow: Create booking here (for backwards compatibility)
        debugPrint('📦 Creating new booking for listing: ${widget.parkingSpace.id}');
        debugPrint('📦 Duration: $durationHours hours, Amount: ₹${widget.totalPrice}');
        booking = await bookingService.createBooking(
          listingId: widget.parkingSpace.id,
          hostId: widget.parkingSpace.ownerId,
          vehicleType: 'car', // Default to car, TODO: get from user selection
          bookingDate: widget.selectedDate,
          entryTime: widget.startTime,
          exitTime: widget.endTime,
          durationHours: durationHours,
          baseAmount: widget.totalPrice,
          paymentMethod: 'razorpay',
        );

        debugPrint('✔️ Booking created! ID: ${booking.id}');
        debugPrint('✔️ Now confirming booking with payment...');
        await bookingService.confirmBooking(
          booking.id,
          transactionId: response.paymentId,
          qrCode: QRService.generateBookingQR(
            bookingId: booking.id,
            parkingSpaceId: widget.parkingSpace.id,
            userId: booking.renterId,
            hostId: booking.hostId,
            startTime: startDateTime,
            endTime: endDateTime,
            vehicleNumber: booking.vehicleType,
            totalAmount: widget.totalPrice,
          ),
        );
      }

      debugPrint('✅ Booking confirmed successfully!');
      setState(() => _isProcessingPayment = false);

      // Navigate to success screen with booking details
      debugPrint('🎉 Navigating to success screen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookingSuccessScreen(
            parkingSpace: widget.parkingSpace,
            selectedDate: widget.selectedDate,
            startTime: widget.startTime,
            endTime: widget.endTime,
            totalPrice: widget.totalPrice,
            booking: booking,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessingPayment = false);
      debugPrint('❌ FATAL ERROR in payment success handler: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking creation failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    debugPrint('❌ PAYMENT FAILED!');
    debugPrint('❌ Error Code: ${response.code}');
    debugPrint('❌ Error Message: ${response.message}');

    setState(() => _isProcessingPayment = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessingPayment = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
