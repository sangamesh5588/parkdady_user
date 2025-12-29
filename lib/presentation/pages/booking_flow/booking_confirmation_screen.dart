import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/parking_space.dart';
import '../../../services/booking_service.dart';
import '../../widgets/custom_button.dart';
import 'payment_screen.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final ParkingSpace parkingSpace;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalPrice;

  const BookingConfirmationScreen({
    super.key,
    required this.parkingSpace,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
  });

  @override
  ConsumerState<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends ConsumerState<BookingConfirmationScreen> {
  bool _isCreatingBooking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Confirm Booking',
          style: TextStyle(
            color: AppColors.getPrimaryText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parking space summary
                    _buildParkingSummary(context),

                    SizedBox(height: AppConstants.spacing24),

                    // Booking details
                    _buildBookingDetails(context),

                    SizedBox(height: AppConstants.spacing24),

                    // Cancellation policy
                    _buildCancellationPolicy(context),

                    SizedBox(height: AppConstants.spacing24),

                    // Terms and conditions
                    _buildTermsAndConditions(context),
                  ],
                ),
              ),
            ),

            // Bottom action bar (scrolls with content)
            _buildBottomActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildParkingSummary(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Parking image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.ctaPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Icon(
              Icons.local_parking,
              color: AppColors.ctaPrimary,
              size: 30,
            ),
          ),

          SizedBox(width: AppConstants.spacing12),

          // Parking details
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
                SizedBox(height: AppConstants.spacing4),
                Text(
                  widget.parkingSpace.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
                SizedBox(height: AppConstants.spacing8),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    SizedBox(width: AppConstants.spacing4),
                    Text(
                      '4.8 (127 reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getSecondaryText(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),

          SizedBox(height: AppConstants.spacing16),

          // Date
          _buildDetailRow(
            context,
            'Date',
            '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
            Icons.calendar_today,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Time
          _buildDetailRow(
            context,
            'Time',
            '${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
            Icons.access_time,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Duration
          _buildDetailRow(
            context,
            'Duration',
            _calculateDurationText(),
            Icons.hourglass_empty,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Vehicle (placeholder)
          _buildDetailRow(
            context,
            'Vehicle',
            'ABC-123 (Toyota Camry)',
            Icons.directions_car,
          ),

          SizedBox(height: AppConstants.spacing16),

          // Divider
          Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),

          SizedBox(height: AppConstants.spacing16),

          // Price breakdown
          _buildPriceBreakdown(context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.ctaPrimary,
          ),
        ),
        SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getSecondaryText(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.getPrimaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(BuildContext context) {
    final hourlyRate = widget.parkingSpace.pricePerHour;
    final hours = _calculateDurationHours();
    final platformFee = 9.0; // Fixed platform fee of ₹9
    final subtotal = widget.totalPrice;
    final grandTotal = subtotal + platformFee;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${hourlyRate.toStringAsFixed(2)} × ${hours.toStringAsFixed(1)} hours',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryText(context),
              ),
            ),
            Text(
              '₹${subtotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.spacing8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Platform fee',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryText(context),
              ),
            ),
            Text(
              '₹${platformFee.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.getPrimaryText(context),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.spacing12),

        Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),

        SizedBox(height: AppConstants.spacing8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimaryText(context),
              ),
            ),
            Text(
              '₹${grandTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ctaPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancellationPolicy(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.orange,
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                'Cancellation Policy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing8),

          Text(
            'Free cancellation up to 24 hours before your booking. Cancellations within 24 hours may incur a fee.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By confirming this booking, you agree to our',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getSecondaryText(context),
            ),
          ),

          SizedBox(height: AppConstants.spacing8),

          Row(
            children: [
              Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ctaPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getSecondaryText(context),
                ),
              ),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ctaPrimary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: CustomButton(
        text: _isCreatingBooking
            ? 'Creating Booking...'
            : 'Confirm & Pay \$${widget.totalPrice.toStringAsFixed(2)}',
        onPressed: _isCreatingBooking ? null : () => _handleConfirmBooking(context),
        icon: _isCreatingBooking ? Icons.hourglass_empty : Icons.credit_card,
        isLoading: _isCreatingBooking,
      ),
    );
  }

  void _handleConfirmBooking(BuildContext context) async {
    print('==========================================');
    print('BUTTON CLICKED - STARTING BOOKING CREATION');
    print('==========================================');
    debugPrint('📝 Creating booking BEFORE payment...');
    setState(() => _isCreatingBooking = true);

    try {
      final bookingService = BookingService();

      // Calculate duration
      final durationHours = _calculateDurationHours().ceil();

      // CREATE BOOKING FIRST (pending status)
      debugPrint('🔄 Creating pending booking in database...');
      final booking = await bookingService.createBooking(
        listingId: widget.parkingSpace.id,
        hostId: widget.parkingSpace.ownerId,
        vehicleType: 'car', // TODO: Add vehicle selection
        bookingDate: widget.selectedDate,
        entryTime: widget.startTime,
        exitTime: widget.endTime,
        durationHours: durationHours,
        baseAmount: widget.totalPrice,
        paymentMethod: 'pending', // Will be updated after payment
      );

      debugPrint('✅ Booking created! ID: ${booking.id}, Status: ${booking.bookingStatus}');

      if (!mounted) return;
      setState(() => _isCreatingBooking = false);

      // Now go to payment screen with the booking
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            parkingSpace: widget.parkingSpace,
            selectedDate: widget.selectedDate,
            startTime: widget.startTime,
            endTime: widget.endTime,
            totalPrice: widget.totalPrice,
            existingBooking: booking, // Pass the created booking
          ),
        ),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() => _isCreatingBooking = false);

      debugPrint('❌ ERROR creating booking: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Error type: ${e.runtimeType}');

      // Show error dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Booking Error'),
          content: SingleChildScrollView(
            child: Text('Error: ${e.toString()}\n\nPlease screenshot this and check console for details.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _calculateDurationText() {
    final hours = _calculateDurationHours();
    final minutes = ((hours - hours.floor()) * 60).round();

    if (hours >= 1) {
      return '${hours.floor()}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double _calculateDurationHours() {
    final startMinutes = widget.startTime.hour * 60 + widget.startTime.minute;
    final endMinutes = widget.endTime.hour * 60 + widget.endTime.minute;
    final durationMinutes = endMinutes - startMinutes;

    return durationMinutes / 60.0;
  }
}
