import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/colors.dart';
import '../../../core/constants.dart';
import '../../providers/parking_provider.dart';
import 'widgets/image_carousel.dart';
import 'widgets/parking_info_section.dart';
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

                  // Distance and Available Spots
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.directions_walk,
                        widget.parkingSpace.formattedDistance,
                        AppColors.ctaPrimary,
                      ),
                      SizedBox(width: AppConstants.spacing12),
                      _buildInfoChip(
                        Icons.local_parking,
                        '${widget.parkingSpace.availableSpots} spots',
                        widget.parkingSpace.isUrgent ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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
