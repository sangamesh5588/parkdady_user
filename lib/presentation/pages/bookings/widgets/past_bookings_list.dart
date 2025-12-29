import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../../services/booking_service.dart';

// Provider for past bookings
final pastBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookingService = BookingService();
  return await bookingService.getPastBookings();
});

class PastBookingsList extends ConsumerStatefulWidget {
  const PastBookingsList({super.key});

  @override
  ConsumerState<PastBookingsList> createState() => _PastBookingsListState();
}

class _PastBookingsListState extends ConsumerState<PastBookingsList> {
  @override
  Widget build(BuildContext context) {
    final pastBookingsAsync = ref.watch(pastBookingsProvider);

    return pastBookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pastBookingsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.all(AppConstants.spacing16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: AppConstants.spacing12, left: AppConstants.spacing8, right: AppConstants.spacing8),
                child: _buildPastBookingCard(context, bookings[index]),
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
              'Error loading past bookings',
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
                ref.invalidate(pastBookingsProvider);
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
            Icons.history,
            size: 80,
            color: AppColors.getSecondaryText(context).withOpacity(0.5),
          ),
          SizedBox(height: AppConstants.spacing16),
          Text(
            'No Past Bookings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Text(
            'Your completed parking bookings will appear here',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getSecondaryText(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPastBookingCard(BuildContext context, Booking booking) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parking space name and booking status
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.parkingSpaceName ?? 'Parking Space',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getPrimaryText(context),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.bookingStatus),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.bookingStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing4),

            // Address
            if (booking.parkingAddress != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.getSecondaryText(context)),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.parkingAddress!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.getSecondaryText(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppConstants.spacing8),
            ],

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.getSecondaryText(context)),
                SizedBox(width: 4),
                Text(
                  booking.formattedDate,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: AppColors.getSecondaryText(context)),
                SizedBox(width: 4),
                Text(
                  '${booking.formattedEntryTime} - ${booking.formattedExitTime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing8),

            // Vehicle and price
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
                if (booking.durationHours != null) ...[
                  SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: AppColors.getSecondaryText(context)),
                  SizedBox(width: 4),
                  Text(
                    booking.durationText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getSecondaryText(context),
                    ),
                  ),
                ],
                Spacer(),
                Text(
                  '₹${booking.displayAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.getPrimaryText(context),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppConstants.spacing12),

            // Action buttons - only show for completed bookings
            if (booking.isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _leaveReview(context, booking),
                      icon: Icon(Icons.star_border, size: 18),
                      label: Text('Leave Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ctaPrimary,
                        side: BorderSide(color: AppColors.ctaPrimary),
                      ),
                    ),
                  ),
                  SizedBox(width: AppConstants.spacing8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _bookAgain(context, booking),
                      icon: Icon(Icons.replay, size: 18),
                      label: Text('Book Again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ctaPrimary,
                        side: BorderSide(color: AppColors.ctaPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _leaveReview(BuildContext context, Booking booking) {
    // TODO: Navigate to review screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening review for ${booking.parkingSpaceName ?? "parking space"}'),
        backgroundColor: AppColors.ctaPrimary,
      ),
    );
  }

  void _bookAgain(BuildContext context, Booking booking) {
    // TODO: Navigate to booking flow with pre-filled data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to book ${booking.parkingSpaceName ?? "parking space"} again'),
        backgroundColor: AppColors.ctaPrimary,
      ),
    );
  }
}
