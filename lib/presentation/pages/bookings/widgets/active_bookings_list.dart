import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../../core/qr_service.dart';
import '../../../../services/booking_service.dart';
import '../../../widgets/custom_button.dart';

// Provider for active bookings
final activeBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookingService = BookingService();
  return await bookingService.getActiveBookings();
});

class ActiveBookingsList extends ConsumerStatefulWidget {
  const ActiveBookingsList({super.key});

  @override
  ConsumerState<ActiveBookingsList> createState() => _ActiveBookingsListState();
}

class _ActiveBookingsListState extends ConsumerState<ActiveBookingsList> {
  @override
  Widget build(BuildContext context) {
    final activeBookingsAsync = ref.watch(activeBookingsProvider);

    return activeBookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeBookingsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(AppConstants.spacing16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacing12, left: AppConstants.spacing8, right: AppConstants.spacing8),
                child: _buildBookingCard(context, bookings[index]),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.ctaPrimary,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            SizedBox(height: AppConstants.spacing16),
            Text(
              'Error loading bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryText(context),
              ),
            ),
            SizedBox(height: AppConstants.spacing8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getSecondaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.spacing24),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(activeBookingsProvider);
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_parking,
            size: 80,
            color: AppColors.getSecondaryText(context).withOpacity(0.5),
          ),
          SizedBox(height: AppConstants.spacing16),
          Text(
            'No Active Bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Text(
            'Your active parking bookings will appear here',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppConstants.spacing24),
          CustomButton(
            text: 'Find Parking',
            onPressed: () => _navigateToExplore(context),
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parking space name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.parkingSpaceName ?? 'Parking Space',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing8,
                    vertical: AppConstants.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: Text(
                    booking.bookingStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(booking),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing8),

            // Address
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.getSecondaryText(context),
                ),
                SizedBox(width: AppConstants.spacing4),
                Expanded(
                  child: Text(
                    booking.parkingAddress ?? 'Address not available',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing12),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.ctaPrimary,
                ),
                SizedBox(width: AppConstants.spacing4),
                Expanded(
                  child: Text(
                    booking.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing8),

            // Entry and exit time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.ctaPrimary,
                ),
                SizedBox(width: AppConstants.spacing4),
                Text(
                  '${booking.formattedEntryTime} - ${booking.formattedExitTime}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
                SizedBox(width: AppConstants.spacing8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radius4),
                  ),
                  child: Text(
                    booking.durationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing8),

            // Vehicle type and price
            Row(
              children: [
                Icon(
                  booking.vehicleType.toLowerCase() == 'car'
                      ? Icons.directions_car
                      : Icons.two_wheeler,
                  size: 16,
                  color: AppColors.getSecondaryText(context),
                ),
                SizedBox(width: AppConstants.spacing4),
                Text(
                  booking.vehicleType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show original price with strikethrough if discount applied
                    if (booking.discountAmount > 0 || booking.originalAmount > booking.baseAmount)
                      Text(
                        '₹${booking.originalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.getSecondaryText(context),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    // Final price
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking.discountAmount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-₹${booking.discountAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        Text(
                          '₹${booking.displayAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ctaPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Payment status badge
            if (booking.paymentStatus == 'paid')
              Padding(
                padding: EdgeInsets.only(top: AppConstants.spacing8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: AppConstants.spacing4),
                    Text(
                      'Payment ${booking.paymentMethod != null ? 'via ${booking.paymentMethod}' : 'Successful'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: AppConstants.spacing16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showQRCode(context, booking),
                    icon: Icon(Icons.qr_code, size: 18),
                    label: Text('Show Ticket'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ctaPrimary,
                      side: BorderSide(color: AppColors.ctaPrimary),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.spacing8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: booking.latitude != null && booking.longitude != null
                        ? () => _openDirections(booking)
                        : null,
                    icon: Icon(Icons.directions, size: 18),
                    label: Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context, Booking booking) {
    // Generate QR code data
    final qrData = booking.qrCode ?? QRService.generateBookingQR(
      bookingId: booking.id,
      parkingSpaceId: booking.listingId,
      userId: booking.renterId,
      hostId: booking.hostId,
      startTime: DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.requestedEntryTime?.hour ?? 0,
        booking.requestedEntryTime?.minute ?? 0,
      ),
      endTime: DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.requestedExitTime?.hour ?? 0,
        booking.requestedExitTime?.minute ?? 0,
      ),
      vehicleNumber: booking.vehicleType,
      totalAmount: booking.displayAmount,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Digital Parking Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              SizedBox(height: AppConstants.spacing8),
              Text(
                'Show this QR code at the parking entrance',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getSecondaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.spacing20),
              Container(
                width: 200,
                height: 200,
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
                    data: qrData,
                    version: QrVersions.auto,
                    size: 190,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.spacing12),
              Text(
                'Booking ID: ${booking.id.substring(0, 8)}...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getSecondaryText(context),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: AppConstants.spacing4),
              Text(
                booking.formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryText(context),
                ),
              ),
              Text(
                '${booking.formattedEntryTime} - ${booking.formattedExitTime}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryText(context),
                ),
              ),
              SizedBox(height: AppConstants.spacing20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ctaPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDirections(Booking booking) {
    // TODO: Implement directions using maps with lat/lng
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening directions to ${booking.parkingSpaceName}'),
        backgroundColor: AppColors.ctaPrimary,
      ),
    );
  }

  void _navigateToExplore(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Color _getStatusColor(Booking booking) {
    switch (booking.bookingStatus.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
