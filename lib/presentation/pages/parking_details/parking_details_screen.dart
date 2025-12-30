import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/parking_provider.dart';
import 'widgets/image_carousel.dart';
import 'widgets/amenities_section.dart';
import 'widgets/location_section.dart';

class ParkingDetailsScreen extends ConsumerStatefulWidget {
  final ParkingSpaceCard parkingSpace;

  const ParkingDetailsScreen({
    super.key,
    required this.parkingSpace,
  });

  @override
  ConsumerState<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends ConsumerState<ParkingDetailsScreen> {
  // Urgency system variables
  Timer? _urgencyTimer;
  int _currentViewers = 0;
  String _urgencyMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize urgency system
    _currentViewers = Random().nextInt(10) + 3;
    _updateUrgencyMessage();
    _startUrgencyUpdates();
  }

  @override
  void dispose() {
    _urgencyTimer?.cancel();
    super.dispose();
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
      'High demand - book soon',
      '${Random().nextInt(3) + 2} people just booked',
      'Limited availability today',
      '$_currentViewers others viewing now',
      'Booking fast - secure your spot',
      '${Random().nextInt(5) + 3}min ago - spot reserved',
      'Popular choice this hour',
      'Nearly at capacity',
      '${Random().nextInt(4) + 3} active bookings',
      'Filling up quickly',
      'Most booked spot today',
      'Reserve before it\'s gone',
      '${Random().nextInt(3) + 2} slots left',
      'In high demand now',
      'Booking recommended',
    ];

    _urgencyMessage = messages[Random().nextInt(messages.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ImageCarousel(images: widget.parkingSpace.images),
            ),
          ),

          // Parking Information
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.parkingSpace.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 18, color: Colors.amber),
                            SizedBox(width: 4),
                            Text(
                              widget.parkingSpace.averageRating?.toStringAsFixed(1) ?? '4.5',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing8),

                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: AppColors.ctaPrimary),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.parkingSpace.address,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing12),

                  // Distance and Urgency Info (removed spots count)
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.directions_walk,
                        widget.parkingSpace.formattedDistance,
                        AppColors.ctaPrimary,
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      Expanded(
                        child: AnimatedSwitcher(
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
                          child: _buildInfoChip(
                            Icons.trending_up,
                            _urgencyMessage,
                            Color(0xFFFF6B35),
                            key: ValueKey(_urgencyMessage),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppConstants.spacing12),

                  // Live viewers banner
                  _buildLiveViewersBanner(),
                ],
              ),
            ),
          ),

          // Amenities Section
          SliverToBoxAdapter(
            child: AmenitiesSection(
              amenities: widget.parkingSpace.allAmenities.isNotEmpty
                ? widget.parkingSpace.allAmenities
                : widget.parkingSpace.features,
            ),
          ),

          // Location Section
          SliverToBoxAdapter(
            child: LocationSection(
              address: widget.parkingSpace.address,
              distance: widget.parkingSpace.formattedDistance,
              latitude: widget.parkingSpace.latitude,
              longitude: widget.parkingSpace.longitude,
            ),
          ),

          // Booking Section
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.only(top: AppConstants.spacing12),
              padding: EdgeInsets.all(AppConstants.spacing20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking header
                  Text(
                    'Ready to Park?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Book your parking spot in just a few taps',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppConstants.spacing20),

                  // Price summary card
                  Container(
                    padding: EdgeInsets.all(AppConstants.spacing16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(AppConstants.radius12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        // Car pricing row
                        if (widget.parkingSpace.hourlyRateCar != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.directions_car, size: 20, color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Car',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${widget.parkingSpace.hourlyRateCar?.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '/hr',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],

                        // Bike pricing row
                        if (widget.parkingSpace.hourlyRateBike != null) ...[
                          if (widget.parkingSpace.hourlyRateCar != null)
                            SizedBox(height: AppConstants.spacing12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.two_wheeler, size: 20, color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bike',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${widget.parkingSpace.hourlyRateBike?.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '/hr',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing20),

                  // Book Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _navigateToBooking(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ctaPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Continue to Booking',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppConstants.spacing12),

                  // Info text
                  Center(
                    child: Text(
                      'Free cancellation up to 1 hour before arrival',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom spacing
          SliverToBoxAdapter(
            child: SizedBox(height: AppConstants.spacing24),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, {Key? key}) {
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveViewersBanner() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
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
        borderRadius: BorderRadius.circular(10),
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
                width: 8,
                height: 8,
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
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_currentViewers people viewing',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Icon(
            Icons.visibility_outlined,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.pushNamed(
      context,
      '/booking-selection',
      arguments: widget.parkingSpace,
    );
  }
}
