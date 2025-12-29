import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/colors.dart';
import '../../../../core/constants.dart';
import '../../../providers/parking_provider.dart';
import '../../../../../domain/entities/parking_space.dart';
import '../../parking_details/parking_details_screen.dart';

class SearchMapView extends ConsumerStatefulWidget {
  final List<ParkingSpaceCard> searchResults;

  const SearchMapView({
    super.key,
    required this.searchResults,
  });

  @override
  ConsumerState<SearchMapView> createState() => _SearchMapViewState();
}

class _SearchMapViewState extends ConsumerState<SearchMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    // Initialize markers when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    final locationAsync = ref.read(currentLocationProvider);
    locationAsync.whenData((location) {
      if (location != null && mounted) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
        });
      }
    });

    // Update markers with search results
    _updateMarkers(widget.searchResults);
  }

  @override
  void didUpdateWidget(SearchMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update markers when search results change
    if (oldWidget.searchResults != widget.searchResults) {
      // Delay marker update to ensure map controller is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateMarkers(widget.searchResults);
      });
    }
  }

  Future<void> _updateMarkers(List<ParkingSpaceCard> parkingSpaces) async {
    debugPrint('Updating markers for ${parkingSpaces.length} search results');

    final newMarkers = <Marker>{};

    for (final parkingSpace in parkingSpaces) {
      // Skip if no coordinates
      if (parkingSpace.latitude == null || parkingSpace.longitude == null) {
        debugPrint('Skipping ${parkingSpace.name} - no coordinates');
        continue;
      }

      debugPrint('Adding marker for ${parkingSpace.name} at ${parkingSpace.latitude}, ${parkingSpace.longitude}');

      final markerId = MarkerId(parkingSpace.id);
      final position = LatLng(parkingSpace.latitude!, parkingSpace.longitude!);

      // Create marker with custom icon (price badge) or fallback to default
      BitmapDescriptor icon;
      try {
        icon = await _createPriceMarkerIcon(parkingSpace.pricePerHour.toInt());
      } catch (e) {
        debugPrint('Failed to create custom marker icon: $e');
        // Fallback to default marker
        icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      }

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: position,
          onTap: () => _onMarkerTap(parkingSpace),
          icon: icon,
          anchor: const Offset(0.5, 0.5), // Center the marker
          infoWindow: InfoWindow(
            title: parkingSpace.name,
            snippet: '₹${parkingSpace.pricePerHour.toInt()}/hr • ${parkingSpace.availableSpots} spots',
            onTap: () => _navigateToParkingDetails(parkingSpace),
          ),
        ),
      );
    }

    debugPrint('Created ${newMarkers.length} markers');

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });

      // After setting markers, fit camera to show all markers
      if (newMarkers.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _fitCameraToParkingLocations(parkingSpaces);
        });
      }
    }
  }

  void _fitCameraToParkingLocations(List<ParkingSpaceCard> parkingSpaces) {
    if (_mapController == null || parkingSpaces.isEmpty) return;

    // Get all valid coordinates
    final validLocations = parkingSpaces
        .where((space) => space.latitude != null && space.longitude != null)
        .map((space) => LatLng(space.latitude!, space.longitude!))
        .toList();

    if (validLocations.isEmpty) {
      // Fallback to current location if available
      if (_currentLocation != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 13),
        );
      }
      return;
    }

    // Include current location if available
    if (_currentLocation != null) {
      validLocations.add(_currentLocation!);
    }

    // Calculate bounds to fit all markers
    double minLat = validLocations.first.latitude;
    double maxLat = validLocations.first.latitude;
    double minLng = validLocations.first.longitude;
    double maxLng = validLocations.first.longitude;

    for (final location in validLocations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    // Create bounds with padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate camera to fit bounds
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100 pixels padding
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(currentLocationProvider);

    // Update current location when it changes
    locationAsync.whenData((location) {
      if (location != null && _currentLocation == null) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
        });
      }
    });

    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? const LatLng(12.9716, 77.5946), // Default to Bangalore
            zoom: 13,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            // Set map style for better UI
            _setMapStyle();
            // Initialize map position after controller is ready
            Future.delayed(const Duration(milliseconds: 500), () {
              _initializeMap();
            });
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // We'll add custom location button
          zoomControlsEnabled: false, // We'll add custom zoom controls
          mapType: MapType.normal,
          compassEnabled: false,
          buildingsEnabled: true,
          onTap: (_) {
            // Close any open info windows or reset selection
          },
        ),

        // Loading overlay
        if (widget.searchResults.isEmpty)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),

        // Custom controls overlay
        Positioned(
          right: AppConstants.spacing16,
          bottom: AppConstants.spacing64, // Above FAB
          child: Column(
            children: [
              // Location button
              FloatingActionButton.small(
                onPressed: _animateToCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: AppColors.ctaPrimary,
                ),
              ),
              SizedBox(height: AppConstants.spacing8),
              // Zoom in button
              FloatingActionButton.small(
                onPressed: _zoomIn,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.add,
                  color: AppColors.ctaPrimary,
                ),
              ),
              SizedBox(height: AppConstants.spacing8),
              // Zoom out button
              FloatingActionButton.small(
                onPressed: _zoomOut,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.remove,
                  color: AppColors.ctaPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<BitmapDescriptor> _createPriceMarkerIcon(int price) async {
    // Create a custom marker with price label similar to the reference image
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Marker dimensions
    const double width = 80;
    const double height = 36;
    const double borderRadius = 18;

    // Draw rounded rectangle background (white with border)
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(borderRadius),
    );

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw price text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹$price',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2),
    );

    // Convert to image
    final img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  void _onMarkerTap(ParkingSpaceCard parkingSpace) {
    // Show a bottom sheet with parking details preview
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ParkingPreviewSheet(parkingSpace: parkingSpace),
    );
  }

  void _navigateToParkingDetails(ParkingSpaceCard parkingSpace) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParkingDetailsScreen(parkingSpace: parkingSpace),
      ),
    );
  }

  Future<void> _animateToCurrentLocation() async {
    final locationAsync = ref.read(currentLocationProvider);
    locationAsync.whenData((location) {
      if (location != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(location.latitude, location.longitude),
            15,
          ),
        );
      }
    });
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  Future<void> _setMapStyle() async {
    // Custom map styling for better parking app experience
    const mapStyle = '''
    [
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';

    try {
      await _mapController?.setMapStyle(mapStyle);
    } catch (e) {
      // Ignore styling errors
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _ParkingPreviewSheet extends StatelessWidget {
  final ParkingSpaceCard parkingSpace;

  const _ParkingPreviewSheet({required this.parkingSpace});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: EdgeInsets.only(top: AppConstants.spacing8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(AppConstants.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parking name and rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parkingSpace.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (parkingSpace.averageRating != null) ...[
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      SizedBox(width: AppConstants.spacing4),
                      Text(
                        parkingSpace.averageRating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: AppConstants.spacing8),

                // Address
                Text(
                  parkingSpace.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: AppConstants.spacing16),

                // Price and availability
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing12,
                        vertical: AppConstants.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ctaPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radius8),
                      ),
                      child: Text(
                        '₹${parkingSpace.pricePerHour}/hr',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ctaPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing12,
                        vertical: AppConstants.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: parkingSpace.availableSpots > 0
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppConstants.radius8),
                      ),
                      child: Text(
                        '${parkingSpace.availableSpots} spots',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: parkingSpace.availableSpots > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppConstants.spacing16),

                // Features
                if (parkingSpace.features.isNotEmpty) ...[
                  Wrap(
                    spacing: AppConstants.spacing8,
                    runSpacing: AppConstants.spacing8,
                    children: parkingSpace.features.map((feature) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing8,
                          vertical: AppConstants.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                        ),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: AppConstants.spacing16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.ctaPrimary),
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: AppColors.ctaPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ParkingDetailsScreen(parkingSpace: parkingSpace),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ctaPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppConstants.spacing12),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
}
