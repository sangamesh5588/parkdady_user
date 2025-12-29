import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../../domain/entities/parking_space.dart';
import '../../widgets/custom_button.dart';
import 'widgets/image_carousel.dart';
import 'widgets/space_info_section.dart';
import 'widgets/booking_section.dart';
import 'widgets/host_info_section.dart';
import 'booking_confirmation_screen.dart';

class ParkingSpaceDetailsScreen extends ConsumerStatefulWidget {
  final ParkingSpace parkingSpace;

  const ParkingSpaceDetailsScreen({
    super.key,
    required this.parkingSpace,
  });

  @override
  ConsumerState<ParkingSpaceDetailsScreen> createState() =>
      _ParkingSpaceDetailsScreenState();
}

class _ParkingSpaceDetailsScreenState
    extends ConsumerState<ParkingSpaceDetailsScreen>
    with TickerProviderStateMixin {
  DateTime? selectedDate;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Enhanced header with better design
              _buildEnhancedHeader(),

              // Main content with improved layout
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced image carousel
                      ImageCarousel(images: widget.parkingSpace.images),

                      // Content container with better spacing
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppConstants.radius20),
                            topRight: Radius.circular(AppConstants.radius20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        transform: Matrix4.translationValues(0, -AppConstants.spacing12, 0),
                        child: Column(
                          children: [
                            // Space info section
                            SpaceInfoSection(parkingSpace: widget.parkingSpace),

                            // Trust indicators section
                            _buildTrustIndicators(),

                            // Host info section
                            HostInfoSection(parkingSpace: widget.parkingSpace),

                            // Reviews preview section
                            _buildReviewsPreview(),

                            // Booking section
                            BookingSection(
                              parkingSpace: widget.parkingSpace,
                              onDateTimeSelected: _onDateTimeSelected,
                            ),

                            // Bottom spacing
                            SizedBox(height: AppConstants.spacing32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Regular bottom booking bar - part of scrollable content
              _buildBottomBookingBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Enhanced back button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              shape: BoxShape.circle,
              boxShadow: [AppColors.lightShadow],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.getPrimaryText(context),
                size: 20,
              ),
            ),
          ),

          const Spacer(),

          // Screen title with better typography
          Text(
            'Parking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryText(context),
            ),
          ),

          const Spacer(),

          // Enhanced favorite button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              shape: BoxShape.circle,
              boxShadow: [AppColors.lightShadow],
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement favorite functionality
              },
              icon: Icon(
                Icons.favorite_border,
                color: AppColors.getPrimaryText(context),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.statusSuccess.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: AppColors.statusSuccess,
            size: 20,
          ),
          SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verified & Secure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statusSuccess,
                  ),
                ),
                Text(
                  '24/7 security • Instant booking • Cancellation protection',
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
    );
  }

  Widget _buildReviewsPreview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppConstants.spacing16, vertical: AppConstants.spacing16),
      padding: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius12),
        border: Border.all(
          color: AppColors.divider,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Reviews & Ratings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getPrimaryText(context),
                ),
              ),
              const Spacer(),
              Text(
                '4.8 (127 reviews)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctaPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing12),
          // Sample review preview
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.ctaPrimary.withOpacity(0.1),
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctaPrimary,
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Great parking spot! Easy access and well maintained.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getPrimaryText(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '2 days ago',
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
        ],
      ),
    );
  }

  Widget _buildBottomBookingBar() {
    final totalHours = _calculateTotalHours();
    final totalPrice = totalHours * widget.parkingSpace.pricePerHour;

    return Container(
      padding: EdgeInsets.all(AppConstants.spacing20),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enhanced price info with better design
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctaPrimary,
                      ),
                    ),
                    if (totalHours > 0) ...[
                      SizedBox(width: AppConstants.spacing8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing8,
                          vertical: AppConstants.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ctaPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.radius8),
                        ),
                        child: Text(
                          '${totalHours.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctaPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '\$${widget.parkingSpace.pricePerHour}/hr • Free cancellation',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getSecondaryText(context),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced book now button
          SizedBox(
            width: 140,
            height: 56,
            child: CustomButton(
              text: 'Book Now',
              onPressed: _canBook() ? _handleBookNow : null,
              icon: Icons.confirmation_number,
            ),
          ),
        ],
      ),
    );
  }

  void _onDateTimeSelected({
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    setState(() {
      selectedDate = date;
      selectedStartTime = startTime;
      selectedEndTime = endTime;
    });
  }

  bool _canBook() {
    return selectedDate != null &&
           selectedStartTime != null &&
           selectedEndTime != null;
  }

  double _calculateTotalHours() {
    if (selectedStartTime == null || selectedEndTime == null) {
      return 0;
    }

    final startMinutes = selectedStartTime!.hour * 60 + selectedStartTime!.minute;
    final endMinutes = selectedEndTime!.hour * 60 + selectedEndTime!.minute;
    final durationMinutes = endMinutes - startMinutes;

    return durationMinutes / 60.0;
  }

  void _handleBookNow() {
    if (!_canBook()) return;

    // Navigate to booking confirmation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          parkingSpace: widget.parkingSpace,
          selectedDate: selectedDate!,
          startTime: selectedStartTime!,
          endTime: selectedEndTime!,

          totalPrice: _calculateTotalPrice(),
        ),
      ),
    );
  }

  double _calculateTotalPrice() {
    final totalHours = _calculateTotalHours();
    return totalHours * widget.parkingSpace.pricePerHour;
  }
}
