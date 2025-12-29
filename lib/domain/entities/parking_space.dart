import 'package:uuid/uuid.dart';

class ParkingSpace {
  final String id;
  final String name;
  final String address;
  final String description;
  final double? latitude;
  final double? longitude;
  final double pricePerHour;
  final bool isAvailable;
  final String ownerId;
  final List<String> images;
  final int totalSpots;
  final int availableSpots;
  final String createdAt;
  final String updatedAt;

  const ParkingSpace({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    this.latitude,
    this.longitude,
    required this.pricePerHour,
    required this.isAvailable,
    required this.ownerId,
    required this.images,
    required this.totalSpots,
    required this.availableSpots,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Supabase JSON
  // Supports both 'parking_spaces' table and 'listings' table
  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case (database) and camelCase field names
    // Also handle both 'listings' and 'parking_spaces' table structures

    // ID field - can be 'id' or needs conversion
    String id = json['id']?.toString() ?? '';

    // Name field - can be 'name', 'parking_space_name', or 'parking_name'
    String name = json['name'] as String? ??
                  json['parking_space_name'] as String? ??
                  json['parking_name'] as String? ??
                  'Unknown Parking';

    // Address field - can be 'address' or 'parking_address'
    String address = json['address'] as String? ??
                     json['parking_address'] as String? ??
                     'Address not available';

    // Description field
    String description = json['description'] as String? ??
                        json['landmark'] as String? ??
                        '';

    // Coordinates
    double? latitude = json['latitude'] != null ? (json['latitude'] as num).toDouble() : null;
    double? longitude = json['longitude'] != null ? (json['longitude'] as num).toDouble() : null;

    // Price per hour - can be from different fields depending on table
    double pricePerHour = 0.0;
    if (json['price_per_hour'] != null) {
      pricePerHour = (json['price_per_hour'] as num).toDouble();
    } else if (json['hourly_rate_car'] != null) {
      pricePerHour = (json['hourly_rate_car'] as num).toDouble();
    } else if (json['hourly_rate'] != null) {
      pricePerHour = (json['hourly_rate'] as num).toDouble();
    }

    // Availability - can be 'is_active', 'is_available', or based on status
    bool isAvailable = json['is_active'] as bool? ??
                       json['is_available'] as bool? ??
                       (json['status'] == 'approved' ? true : false);

    // Owner/Host ID
    String ownerId = json['host_id']?.toString() ??
                     json['owner_id']?.toString() ??
                     '';

    // Images - can be array or JSON array
    List<String> images = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        images = List<String>.from(json['images']);
      }
    } else if (json['parking_photos'] != null) {
      if (json['parking_photos'] is List) {
        images = List<String>.from(json['parking_photos']);
      }
    }

    // Total spots - can be from different fields
    int totalSpots = json['total_spaces'] as int? ??
                     json['total_spots'] as int? ??
                     json['total_car_slots'] as int? ??
                     1;

    // Available spots - can be calculated or from field
    int availableSpots = json['available_spaces'] as int? ??
                         json['available_spots'] as int? ??
                         json['active_car_slots'] as int? ??
                         totalSpots;

    // Timestamps
    String createdAt = json['created_at'] as String? ?? DateTime.now().toIso8601String();
    String updatedAt = json['updated_at'] as String? ?? DateTime.now().toIso8601String();

    return ParkingSpace(
      id: id,
      name: name,
      address: address,
      description: description,
      latitude: latitude,
      longitude: longitude,
      pricePerHour: pricePerHour,
      isAvailable: isAvailable,
      ownerId: ownerId,
      images: images,
      totalSpots: totalSpots,
      availableSpots: availableSpots,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'owner_id': ownerId,
      'images': images,
      'total_spots': totalSpots,
      'available_spots': availableSpots,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create a copy with updated fields
  ParkingSpace copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    double? latitude,
    double? longitude,
    double? pricePerHour,
    bool? isAvailable,
    String? ownerId,
    List<String>? images,
    int? totalSpots,
    int? availableSpots,
    String? createdAt,
    String? updatedAt,
  }) {
    return ParkingSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId ?? this.ownerId,
      images: images ?? this.images,
      totalSpots: totalSpots ?? this.totalSpots,
      availableSpots: availableSpots ?? this.availableSpots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create mock data for development
  static ParkingSpace mock() {
    final uuid = const Uuid();
    const descriptions = [
      'Secure underground parking with 24/7 security cameras and easy access.',
      'Covered parking space with electric vehicle charging station available.',
      'Prime location parking with quick access to shopping centers.',
      'Residential parking with additional storage space included.',
      'Commercial parking area with valet service during business hours.'
    ];

    const addresses = [
      '123 Main St, Downtown',
      '456 Oak Ave, Midtown',
      '789 Pine Rd, Uptown',
      '321 Elm St, Westside',
      '654 Maple Dr, Eastside'
    ];

    return ParkingSpace(
      id: uuid.v4(),
      name: 'Parking Space ${uuid.v1().substring(0, 8)}',
      address: addresses[uuid.v1().codeUnitAt(0) % addresses.length],
      description: descriptions[uuid.v1().codeUnitAt(0) % descriptions.length],
      latitude: 37.7749 + (uuid.v1().codeUnitAt(0) % 100 - 50) * 0.001,
      longitude: -122.4194 + (uuid.v1().codeUnitAt(1) % 100 - 50) * 0.001,
      pricePerHour: 2.5 + (uuid.v1().codeUnitAt(0) % 50) * 0.5,
      isAvailable: (uuid.v1().codeUnitAt(0) % 2) == 0,
      ownerId: uuid.v4(),
      images: [],
      totalSpots: 1,
      availableSpots: 1,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}
