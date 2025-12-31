import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../services/booking_service.dart';

// Booking history entity for demo purposes
class BookingHistory {
  final String id;
  final String parkingSpaceName;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final double totalAmount;
  final String status; // 'completed', 'cancelled', 'active'
  final String vehicleInfo;
  final DateTime createdAt;

  const BookingHistory({
    required this.id,
    required this.parkingSpaceName,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.status,
    required this.vehicleInfo,
    required this.createdAt,
  });

  String get durationText {
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
  }

  Color get statusColor {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return AppColors.ctaPrimary;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }
}

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  final BookingService _bookingService = BookingService();
  List<BookingHistory> _bookings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);
      final bookings = await _bookingService.getUserBookings();

      // Convert Booking objects to BookingHistory objects for compatibility
      final bookingHistory = bookings.map((booking) {
        // Calculate start and end times from booking date and time slots
        final startDateTime = DateTime(
          booking.bookingDate.year,
          booking.bookingDate.month,
          booking.bookingDate.day,
          booking.requestedEntryTime?.hour ?? 0,
          booking.requestedEntryTime?.minute ?? 0,
        );

        final endDateTime = DateTime(
          booking.bookingDate.year,
          booking.bookingDate.month,
          booking.bookingDate.day,
          booking.requestedExitTime?.hour ?? 0,
          booking.requestedExitTime?.minute ?? 0,
        );

        return BookingHistory(
          id: booking.id,
          parkingSpaceName: booking.parkingSpaceName ?? 'Unknown Location',
          address: booking.parkingAddress ?? 'Address not available',
          startTime: startDateTime,
          endTime: endDateTime,
          totalAmount: booking.totalWithPlatformFee,
          status: _mapBookingStatus(booking.bookingStatus),
          vehicleInfo: booking.vehicleType.toUpperCase(),
          createdAt: booking.createdAt,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _bookings = bookingHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load bookings. Please try again.');
      }
    }
  }

  Future<void> _refreshBookings() async {
    if (!mounted || _isRefreshing) return;

    try {
      setState(() => _isRefreshing = true);
      await _loadBookings();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  String _mapBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
        return 'active';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'expired':
        return 'expired';
      default:
        return 'pending';
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
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadBookings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Handle back button press (both system and app bar back button)
        if (didPop) {
          // Navigation was handled automatically
          return;
        }
        // If for some reason pop didn't work, force it
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          title: Text(
            'Booking History',
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
          actions: [
            if (_bookings.isNotEmpty)
              IconButton(
                icon: Icon(Icons.filter_list, color: AppColors.textPrimary),
                onPressed: () => _showFilterBottomSheet(context),
              ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.ctaPrimary,
                  ),
                )
              : _bookings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshBookings,
                      color: AppColors.ctaPrimary,
                      child: _buildBookingsList(),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textMuted,
          ),
          SizedBox(height: AppConstants.spacing16),
          Text(
            'No booking history yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing8),
          Text(
            'Your completed bookings will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      padding: EdgeInsets.all(AppConstants.spacing16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(BookingHistory booking) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spacing12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status and booking ID
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing8,
                  vertical: AppConstants.spacing4,
                ),
                decoration: BoxDecoration(
                  color: booking.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: booking.statusColor,
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spacing8),
              Flexible(
                child: Text(
                  '#${booking.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing12),

          // Parking space info
          Text(
            booking.parkingSpaceName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: AppConstants.spacing4),

          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppConstants.spacing4),
              Expanded(
                child: Text(
                  booking.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing12),

          // Booking details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: DateFormat('MMM d, y').format(booking.startTime),
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: booking.durationText,
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing8),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.directions_car,
                  label: 'Vehicle',
                  value: booking.vehicleInfo,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.currency_rupee,
                  label: 'Amount',
                  value: '₹${booking.totalAmount.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),

          SizedBox(height: AppConstants.spacing16),

          // Time info
          Container(
            padding: EdgeInsets.all(AppConstants.spacing12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: AppConstants.spacing8),
                Expanded(
                  child: Text(
                    '${DateFormat('MMM d, h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action buttons for active and pending bookings
          if (booking.status == 'active' || booking.status == 'pending') ...[
            SizedBox(height: AppConstants.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelBookingDialog(context, booking),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
                SizedBox(width: AppConstants.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBookingDetails(context, booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPrimary,
                      foregroundColor: AppColors.ctaOnPrimary,
                      padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],

          // View receipt for completed bookings
          if (booking.status == 'completed') ...[
            SizedBox(height: AppConstants.spacing16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReceipt(context, booking),
                icon: Icon(Icons.receipt),
                label: Text('View Receipt'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        SizedBox(width: AppConstants.spacing4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter Bookings',
                  style: TextStyle(
                    fontSize: AppConstants.fontSize20,
                    fontWeight: AppConstants.fontWeightSemiBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: AppConstants.spacing16),
            _buildFilterOption('All Bookings', null),
            _buildFilterOption('Active', 'active'),
            _buildFilterOption('Completed', 'completed'),
            _buildFilterOption('Cancelled', 'cancelled'),
            SizedBox(height: AppConstants.spacing16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String? filterStatus) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: AppConstants.fontWeightMedium,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        Navigator.pop(context);
        setState(() {
          if (filterStatus == null) {
            _loadBookings();
          } else {
            _filterBookingsByStatus(filterStatus);
          }
        });
      },
    );
  }

  void _filterBookingsByStatus(String status) {
    // This would typically filter on the server side
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filtered by: $status'),
        backgroundColor: AppColors.ctaPrimary,
      ),
    );
  }

  void _showCancelBookingDialog(BuildContext context, BookingHistory booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
        title: Text(
          'Cancel Booking',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: AppConstants.fontWeightSemiBold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your booking at ${booking.parkingSpaceName}? You may be charged a cancellation fee.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep Booking',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _cancelBooking(booking);
            },
            child: Text(
              'Cancel Booking',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BookingHistory booking) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: AppConstants.spacing12),
              Text('Cancelling booking...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Call the service to cancel booking
      await _bookingService.cancelBooking(booking.id);

      // Refresh the list
      await _loadBookings();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppConstants.spacing12),
                Text('Booking cancelled successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking. Please try again.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _cancelBooking(booking),
            ),
          ),
        );
      }
    }
  }

  void _showBookingDetails(BuildContext context, BookingHistory booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: AppConstants.fontSize20,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppConstants.spacing16),
                  children: [
                    _buildDetailSection('Parking Location', [
                      _buildDetailRow('Name', booking.parkingSpaceName),
                      _buildDetailRow('Address', booking.address),
                    ]),
                    SizedBox(height: AppConstants.spacing16),
                    _buildDetailSection('Booking Information', [
                      _buildDetailRow('Booking ID', '#${booking.id}'),
                      _buildDetailRow('Status', booking.status.toUpperCase()),
                      _buildDetailRow('Booked On', DateFormat('MMM d, y h:mm a').format(booking.createdAt)),
                    ]),
                    SizedBox(height: AppConstants.spacing16),
                    _buildDetailSection('Parking Time', [
                      _buildDetailRow('Start', DateFormat('MMM d, y h:mm a').format(booking.startTime)),
                      _buildDetailRow('End', DateFormat('MMM d, y h:mm a').format(booking.endTime)),
                      _buildDetailRow('Duration', booking.durationText),
                    ]),
                    SizedBox(height: AppConstants.spacing16),
                    _buildDetailSection('Vehicle Details', [
                      _buildDetailRow('Vehicle', booking.vehicleInfo),
                    ]),
                    SizedBox(height: AppConstants.spacing16),
                    _buildDetailSection('Payment', [
                      _buildDetailRow('Total Amount', '₹${booking.totalAmount.toStringAsFixed(2)}', isHighlighted: true),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: AppConstants.fontSize16,
              fontWeight: AppConstants.fontWeightSemiBold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppConstants.fontSize14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isHighlighted ? AppColors.ctaPrimary : AppColors.textPrimary,
                fontSize: AppConstants.fontSize14,
                fontWeight: isHighlighted ? AppConstants.fontWeightSemiBold : AppConstants.fontWeightMedium,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, BookingHistory booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Receipt',
                      style: TextStyle(
                        fontSize: AppConstants.fontSize20,
                        fontWeight: AppConstants.fontWeightSemiBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.download, color: AppColors.ctaPrimary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Receipt downloaded')),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppConstants.spacing24),
                  children: [
                    // Receipt Header
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: AppColors.ctaPrimary,
                          ),
                          SizedBox(height: AppConstants.spacing8),
                          Text(
                            'Parking Receipt',
                            style: TextStyle(
                              fontSize: AppConstants.fontSize24,
                              fontWeight: AppConstants.fontWeightBold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppConstants.spacing4),
                          Text(
                            'Booking #${booking.id}',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: AppConstants.fontSize14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing24),
                    Divider(color: AppColors.borderLight),
                    SizedBox(height: AppConstants.spacing16),

                    // Parking Details
                    _buildReceiptRow('Location', booking.parkingSpaceName),
                    _buildReceiptRow('Address', booking.address),
                    SizedBox(height: AppConstants.spacing16),

                    // Time Details
                    _buildReceiptRow('Start Time', DateFormat('MMM d, y h:mm a').format(booking.startTime)),
                    _buildReceiptRow('End Time', DateFormat('MMM d, y h:mm a').format(booking.endTime)),
                    _buildReceiptRow('Duration', booking.durationText),
                    SizedBox(height: AppConstants.spacing16),

                    // Vehicle
                    _buildReceiptRow('Vehicle', booking.vehicleInfo),
                    SizedBox(height: AppConstants.spacing16),

                    Divider(color: AppColors.borderLight),
                    SizedBox(height: AppConstants.spacing16),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: AppConstants.fontSize18,
                            fontWeight: AppConstants.fontWeightBold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '₹${booking.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppConstants.fontSize24,
                            fontWeight: AppConstants.fontWeightBold,
                            color: AppColors.ctaPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.spacing24),

                    // Status
                    Container(
                      padding: EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: booking.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radius12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: booking.statusColor,
                            size: 20,
                          ),
                          SizedBox(width: AppConstants.spacing8),
                          Text(
                            'Payment ${booking.status}',
                            style: TextStyle(
                              color: booking.statusColor,
                              fontWeight: AppConstants.fontWeightSemiBold,
                              fontSize: AppConstants.fontSize16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppConstants.spacing16),

                    // Footer
                    Center(
                      child: Text(
                        'Thank you for using our service!',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: AppConstants.fontSize12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppConstants.fontSize14,
            ),
          ),
          SizedBox(width: AppConstants.spacing16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppConstants.fontSize14,
                fontWeight: AppConstants.fontWeightMedium,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
