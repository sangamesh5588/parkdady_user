import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../core/qr_service.dart';
import '../../../domain/entities/parking_space.dart';
import '../../../services/booking_service.dart';
import '../../widgets/custom_button.dart';

class BookingSuccessScreen extends StatelessWidget {
  final ParkingSpace parkingSpace;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalPrice;
  final Booking? booking;

  const BookingSuccessScreen({
    super.key,
    required this.parkingSpace,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            _buildHeader(context),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppConstants.spacing16),
                child: Column(
                  children: [
                    // Success animation/icon
                    _buildSuccessAnimation(context),

                    SizedBox(height: AppConstants.spacing24),

                    // Success message
                    _buildSuccessMessage(context),

                    SizedBox(height: AppConstants.spacing32),

                    // Digital ticket
                    _buildDigitalTicket(context),

                    SizedBox(height: AppConstants.spacing32),

                    // Instructions
                    _buildInstructions(context),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          Expanded(
            child: Text(
              'Booking Confirmed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Invisible icon for balance
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 80,
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your parking is booked!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.getPrimaryText(context),
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: AppConstants.spacing8),

        Text(
          'You\'ve successfully reserved your parking spot. A confirmation has been sent to your email.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.getSecondaryText(context),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDigitalTicket(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(
          color: AppColors.ctaPrimary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ctaPrimary.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ticket header
          Row(
            children: [
              Icon(
                Icons.confirmation_number,
                color: AppColors.ctaPrimary,
                size: 24,
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                'Digital Parking Ticket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Actual QR Code
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.radius8),
              border: Border.all(
                color: AppColors.ctaPrimary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radius4),
              child: QrImageView(
                data: _generateQRData(),
                version: QrVersions.auto,
                size: 140,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),

          SizedBox(height: AppConstants.spacing8),

          // Booking ID
          Text(
            booking?.id ?? QRService.generateBookingId(), // Use actual booking ID if available
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.getSecondaryText(context),
              letterSpacing: 1,
            ),
          ),

          SizedBox(height: AppConstants.spacing16),

          // Ticket details
          _buildTicketDetail(
            context,
            'Location',
            parkingSpace.name,
            Icons.location_on,
          ),

          SizedBox(height: AppConstants.spacing8),

          _buildTicketDetail(
            context,
            'Date & Time',
            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}\n${startTime.format(context)} - ${endTime.format(context)}',
            Icons.access_time,
          ),

          SizedBox(height: AppConstants.spacing8),

          _buildTicketDetail(
            context,
            'Vehicle',
            booking != null ? booking!.vehicleType.toUpperCase() : 'Not specified',
            Icons.directions_car,
          ),

          SizedBox(height: AppConstants.spacing8),

          _buildTicketDetail(
            context,
            'Total Paid',
            '\$${totalPrice.toStringAsFixed(2)}',
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetail(BuildContext context, String label, String value, IconData icon) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppConstants.spacing4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getPrimaryText(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                size: 20,
                color: Colors.blue,
              ),
              SizedBox(width: AppConstants.spacing8),
              Text(
                'What to do next?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing12),

          _buildInstructionItem(
            'Show this digital ticket or QR code at the parking entrance',
          ),

          SizedBox(height: AppConstants.spacing8),

          _buildInstructionItem(
            'Arrive at least 15 minutes before your reserved time',
          ),

          SizedBox(height: AppConstants.spacing8),

          _buildInstructionItem(
            'Contact the host if you have any questions or need directions',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blue[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: AppConstants.spacing8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
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
      child: Column(
        children: [
          // Primary action - View in bookings
          CustomButton(
            text: 'View in My Bookings',
            onPressed: () => _navigateToBookings(context),
            icon: Icons.calendar_today,
          ),

          SizedBox(height: AppConstants.spacing12),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement directions
                  },
                  icon: Icon(Icons.directions, size: 18),
                  label: Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ctaPrimary,
                    side: BorderSide(color: AppColors.ctaPrimary),
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                  ),
                ),
              ),

              SizedBox(width: AppConstants.spacing12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement contact host
                  },
                  icon: Icon(Icons.message, size: 18),
                  label: Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ctaPrimary,
                    side: BorderSide(color: AppColors.ctaPrimary),
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Back to home
          TextButton(
            onPressed: () => _navigateToHome(context),
            child: Text(
              'Back to Home',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getSecondaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToBookings(BuildContext context) {
    // Navigate to bookings tab
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    // TODO: Switch to bookings tab programmatically
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home/explore tab
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  String _generateQRData() {
    // Use actual booking ID if available, otherwise generate temporary one
    final bookingId = booking?.id ?? QRService.generateBookingId();

    // Combine selected date with time
    final startDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    // If we have a booking, use its QR code if available
    if (booking?.qrCode != null && booking!.qrCode!.isNotEmpty) {
      return booking!.qrCode!;
    }

    // Otherwise generate QR code data
    return QRService.generateBookingQR(
      bookingId: bookingId,
      parkingSpaceId: parkingSpace.id,
      userId: booking?.renterId ?? 'user_123',
      hostId: booking?.hostId ?? parkingSpace.ownerId,
      startTime: startDateTime,
      endTime: endDateTime,
      vehicleNumber: booking?.vehicleType ?? 'car',
      totalAmount: totalPrice,
    );
  }
}
