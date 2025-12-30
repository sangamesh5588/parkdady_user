import 'dart:async';
import 'dart:math';
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

  // Urgency system variables
  late Timer _urgencyTimer;
  int _currentViewers = 0;
  String _urgencyMessage = '';
  int _availableSlotsToday = 0;
  bool _isLoading = true;

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

    // Initialize urgency system
    _initializeUrgencySystem();
    _startUrgencyUpdates();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _urgencyTimer.cancel();
    super.dispose();
  }

  void _initializeUrgencySystem() {
    // Simulate random viewers between 3-12
    _currentViewers = Random().nextInt(10) + 3;

    // Calculate available slots for today
    _fetchTodayAvailability();

    // Set initial urgency message
    _updateUrgencyMessage();
  }

  void _startUrgencyUpdates() {
    // Update viewers and messages every 5-6 seconds for smooth professional feeling
    _urgencyTimer = Timer.periodic(Duration(seconds: 5 + Random().nextInt(2)), (timer) {
      if (mounted) {
        setState(() {
          // Randomly change viewers count (±1-2 for smoother changes)
          final change = Random().nextInt(2) + 1;
          if (Random().nextBool()) {
            _currentViewers = (_currentViewers + change).clamp(3, 12).toInt();
          } else {
            _currentViewers = (_currentViewers - change).clamp(3, 12).toInt();
          }

          _updateUrgencyMessage();
        });
      }
    });
  }

  void _updateUrgencyMessage() {
    final messages = [
      'Only $_availableSlotsToday slots available today',
      '${Random().nextInt(3) + 2} people just booked',
      'Limited availability - book now',
      '$_currentViewers others viewing now',
      'Booking fast today',
      '${Random().nextInt(5) + 3}min ago - spot reserved',
      'Popular time slot',
      'Only $_availableSlotsToday spots remaining',
      '${Random().nextInt(4) + 3} recent bookings',
      'High demand slot',
      'Reserve your spot soon',
      '${Random().nextInt(3) + 2} slots left for today',
      'Filling up quickly',
      'Trending spot this hour',
      'Book before spots run out',
    ];

    _urgencyMessage = messages[Random().nextInt(messages.length)];
  }

  Future<void> _fetchTodayAvailability() async {
    // Calculate how many slots are already booked today
    // For now, simulate based on total spots
    final totalSpots = widget.parkingSpace.totalSpots;
    final bookedToday = Random().nextInt((totalSpots * 0.7).toInt());

    setState(() {
      _availableSlotsToday = (totalSpots - bookedToday).clamp(1, totalSpots).toInt();
      _isLoading = false;
    });
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

                            // URGENCY BANNER - Live viewers and aggressive messaging
                            _buildUrgencyBanner(),

                            // Rotating urgency message
                            _buildRotatingUrgencyMessage(),

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

  // URGENCY BANNER - Live viewers count
  Widget _buildUrgencyBanner() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4A5568),
            Color(0xFF2D3748),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Smooth pulsing dot
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.4, end: 1.0),
            duration: Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (context, double value, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(0xFF48BB78).withValues(alpha: value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF48BB78).withValues(alpha: value * 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
            onEnd: () {
              // Restart animation
              if (mounted) setState(() {});
            },
          ),
          SizedBox(width: AppConstants.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_currentViewers people viewing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$_availableSlotsToday slots available today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.visibility_outlined,
            color: Colors.white70,
            size: 20,
          ),
        ],
      ),
    );
  }

  // ROTATING URGENCY MESSAGE
  Widget _buildRotatingUrgencyMessage() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_urgencyMessage),
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        padding: EdgeInsets.all(AppConstants.spacing12),
        decoration: BoxDecoration(
          color: Color(0xFFFFF9F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color(0xFFFFE5CC),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Color(0xFFFF6B35),
              size: 18,
            ),
            SizedBox(width: AppConstants.spacing8),
            Expanded(
              child: Text(
                _urgencyMessage,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
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

    debugPrint('🚗 BOOKING FLOW DEBUG:');
    debugPrint('  ParkingSpace.pricePerHour from database: ₹${widget.parkingSpace.pricePerHour}');
    debugPrint('  WARNING: If this is NOT ₹100, then the issue is in data loading!');

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
    final parkingFee = totalHours * widget.parkingSpace.pricePerHour;

    // Debug logging to track price calculation
    debugPrint('🔍 PRICE CALCULATION DEBUG:');
    debugPrint('  Total hours: $totalHours');
    debugPrint('  Price per hour: ₹${widget.parkingSpace.pricePerHour}');
    debugPrint('  Parking fee (should be base_amount): ₹$parkingFee');
    debugPrint('  This should be ONLY parking cost, no platform fee or GST');

    return parkingFee;
  }
}
