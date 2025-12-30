import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/parking_provider.dart';
import '../../../services/payment_service.dart';
import '../../../services/booking_service.dart';
import 'booking_success_screen.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bookingData;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingData,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parkingSpace = widget.bookingData['parkingSpace'] as ParkingSpaceCard;
    final date = widget.bookingData['date'] as DateTime;
    final startTime = widget.bookingData['startTime'] as TimeOfDay;
    final duration = widget.bookingData['duration'] as int;
    final vehicleType = widget.bookingData['vehicleType'] as String;
    final totalPrice = widget.bookingData['totalPrice'] as double;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Confirm Booking'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: AppConstants.spacing16),

                // Parking Space Details
                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Header
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppConstants.radius16),
                          topRight: Radius.circular(AppConstants.radius16),
                        ),
                        child: parkingSpace.images.isNotEmpty
                            ? Image.network(
                                parkingSpace.images.first,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildLargeImagePlaceholder(),
                              )
                            : _buildLargeImagePlaceholder(),
                      ),
                      // Details Section
                      Padding(
                        padding: EdgeInsets.all(AppConstants.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parkingSpace.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    parkingSpace.address,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppConstants.spacing16),

                // Booking Details
                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing16),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        DateFormat('EEEE, dd MMM yyyy').format(date),
                      ),
                      _buildDetailRow(
                        Icons.access_time,
                        'Check-in',
                        _formatTimeOfDay(startTime),
                      ),
                      _buildDetailRow(
                        Icons.access_time_filled,
                        'Check-out',
                        _formatTimeOfDay(_calculateEndTime(startTime, duration)),
                      ),
                      _buildDetailRow(
                        Icons.schedule,
                        'Duration',
                        '$duration ${duration == 1 ? 'hour' : 'hours'}',
                      ),
                      _buildDetailRow(
                        Icons.directions_car,
                        'Vehicle Type',
                        vehicleType,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppConstants.spacing16),

                // Payment Summary
                Container(
                  margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radius16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppConstants.spacing16),
                      _buildPriceRow('Parking fee', totalPrice),
                      _buildPriceRow('Platform fee', 9.0),
                      // GST hidden as per requirement (no GST registration, but included in total)
                      Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${_calculateFinalAmount(totalPrice).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctaPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.spacing16),
                      // Pay Button inside the card
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _processPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ctaPrimary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radius12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pay ₹${_calculateFinalAmount(totalPrice).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppConstants.spacing24)
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spacing24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radius16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaPrimary),
                      ),
                      SizedBox(height: AppConstants.spacing16),
                      Text(
                        'Processing payment...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.ctaPrimary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Icon(
        Icons.local_parking,
        color: AppColors.textMuted,
        size: 32,
      ),
    );
  }

  Widget _buildLargeImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            color: AppColors.textMuted,
            size: 64,
          ),
          SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _calculateEndTime(TimeOfDay startTime, int durationHours) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + (durationHours * 60);
    return TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
  }

  double _calculateFinalAmount(double basePrice) {
    final platformFee = 9.0;
    return basePrice + platformFee; // NO GST - just parking + platform fee
  }

  void _processPayment() async {
    print('==========================================');
    print('CREATING BOOKING WITHOUT PAYMENT (TEST MODE)');
    print('==========================================');

    setState(() => _isProcessing = true);

    try {
      // Get booking data
      final parkingSpace = widget.bookingData['parkingSpace'] as ParkingSpaceCard;
      final date = widget.bookingData['date'] as DateTime;
      final startTime = widget.bookingData['startTime'] as TimeOfDay;
      final duration = widget.bookingData['duration'] as int;
      final vehicleType = widget.bookingData['vehicleType'] as String;
      final totalPrice = widget.bookingData['totalPrice'] as double;

      // Calculate end time
      final endTime = TimeOfDay(
        hour: (startTime.hour + duration) % 24,
        minute: startTime.minute,
      );

      print('📝 Booking Details:');
      print('   - Listing ID: ${parkingSpace.id}');
      print('   - Date: $date');
      print('   - Time: ${startTime.hour}:${startTime.minute} to ${endTime.hour}:${endTime.minute}');
      print('   - Duration: $duration hours');
      print('   - Amount: ₹$totalPrice');

      // Get listing to find host_id
      final listingResponse = await Supabase.instance.client
          .from('listings')
          .select('host_id')
          .eq('id', parkingSpace.id)
          .single();

      final hostId = listingResponse['host_id'] as String;
      print('   - Host ID: $hostId');

      // Calculate pricing breakdown
      final platformFee = 9.0; // Platform fee
      final finalAmount = totalPrice + platformFee; // Total: Parking + Platform fee (NO GST)

      print('💰 Price Breakdown:');
      print('   - Parking Fee: ₹$totalPrice');
      print('   - Platform Fee: ₹$platformFee');
      print('   - Final Amount (for payment, stored in DB): ₹$finalAmount');

      // Create booking using BookingService
      final bookingService = BookingService();
      final booking = await bookingService.createBooking(
        listingId: parkingSpace.id,
        hostId: hostId,
        vehicleType: vehicleType.toLowerCase(),
        bookingDate: date,
        entryTime: startTime,
        exitTime: endTime,
        durationHours: duration,
        baseAmount: finalAmount, // Parking + Platform fee = ₹200 + ₹9 = ₹209 (NO GST)
        paymentMethod: 'test_mode',
      );

      print('✅ BOOKING CREATED SUCCESSFULLY!');
      print('   - Booking ID: ${booking.id}');
      print('   - Status: ${booking.bookingStatus}');
      print('==========================================');

      setState(() => _isProcessing = false);

      // Navigate to success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookingSuccessScreen(
            bookingData: {
              ...widget.bookingData,
              'booking': booking,
              'bookingId': booking.id,
              'paymentId': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ ERROR CREATING BOOKING: $e');
      print('❌ Stack trace: $stackTrace');

      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to create booking: ${e.toString()}');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() {
      _isProcessing = true;
    });

    // Save booking to database
    _saveBookingToDatabase(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showErrorDialog('External wallet: ${response.walletName}');
  }

  Future<void> _saveBookingToDatabase(String paymentId) async {
    // Simulate database save
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Navigate to success screen
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/booking-success',
        arguments: {
          ...widget.bookingData,
          'paymentId': paymentId,
          'bookingId': 'BK${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
