import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';

class LocationSection extends StatelessWidget {
  final String address;
  final String distance;
  final double? latitude;
  final double? longitude;

  const LocationSection({
    super.key,
    required this.address,
    required this.distance,
    this.latitude,
    this.longitude,
  });

  Future<void> _openMapsForDirections(BuildContext context) async {
    if (latitude == null || longitude == null) return;

    final lat = latitude!;
    final lng = longitude!;

    // Calculate a point approximately 15 meters away from the parking location
    // This helps users find the nearby area rather than the exact spot
    // Using a simple approximation: 1 degree latitude ≈ 111,320 meters
    // 15 meters ≈ 0.000135 degrees
    const double offsetMeters = 15.0;
    const double metersPerDegree = 111320.0;
    final double latOffset = offsetMeters / metersPerDegree;

    // Add offset to latitude (directing user to approach from south)
    final double nearbyLat = lat - latOffset;
    final double nearbyLng = lng;

    // Try Google Maps first (works on both Android and iOS)
    // Using the nearby point (15m away) as destination
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$nearbyLat,$nearbyLng');

    // Alternative: Use geo URI scheme (works on most platforms)
    final geoUrl = Uri.parse('geo:$nearbyLat,$nearbyLng?q=$nearbyLat,$nearbyLng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: AppConstants.spacing12),
      padding: EdgeInsets.all(AppConstants.spacing16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spacing12),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.ctaPrimary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing8),
          Row(
            children: [
              Icon(Icons.directions_walk, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text(
                '$distance away from you',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spacing16),

          // Get Directions button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: latitude != null && longitude != null
                  ? () => _openMapsForDirections(context)
                  : null,
              icon: Icon(Icons.directions),
              label: Text('Get Directions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ctaPrimary,
                side: BorderSide(color: AppColors.ctaPrimary),
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing16,
                  vertical: AppConstants.spacing12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
