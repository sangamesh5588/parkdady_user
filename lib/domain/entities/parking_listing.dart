/// Entity for user parking listings
class ParkingListing {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final double pricePerHour;
  final double? pricePerDay;
  final double minimumHours;
  final int totalSlots;
  final int availableSlots;
  final List<String> amenities;
  final List<String> images;
  final List<String> availableDays;
  final String? availableFromTime;
  final String? availableToTime;
  final bool is24x7;
  final bool instantBooking;
  final bool requiresApproval;
  final int advanceBookingDays;
  final bool isActive;
  final bool isPublished;
  final String verificationStatus;
  final String? parkingRules;
  final String? accessInstructions;
  final int totalBookings;
  final double? averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  const ParkingListing({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    this.zipCode,
    this.country = 'India',
    this.latitude,
    this.longitude,
    required this.pricePerHour,
    this.pricePerDay,
    this.minimumHours = 1.0,
    required this.totalSlots,
    required this.availableSlots,
    this.amenities = const [],
    this.images = const [],
    this.availableDays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
    this.availableFromTime,
    this.availableToTime,
    this.is24x7 = false,
    this.instantBooking = true,
    this.requiresApproval = false,
    this.advanceBookingDays = 30,
    this.isActive = true,
    this.isPublished = false,
    this.verificationStatus = 'pending',
    this.parkingRules,
    this.accessInstructions,
    this.totalBookings = 0,
    this.averageRating,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  /// Create from Supabase JSON
  factory ParkingListing.fromJson(Map<String, dynamic> json) {
    return ParkingListing(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String?,
      country: json['country'] as String? ?? 'India',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      pricePerDay: json['price_per_day'] != null ? (json['price_per_day'] as num).toDouble() : null,
      minimumHours: json['minimum_hours'] != null ? (json['minimum_hours'] as num).toDouble() : 1.0,
      totalSlots: json['total_slots'] as int,
      availableSlots: json['available_slots'] as int,
      amenities: _parseStringList(json['amenities']) ?? [],
      images: _parseStringList(json['images']) ?? [],
      availableDays: _parseStringList(json['available_days']) ??
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
      availableFromTime: json['available_from_time'] as String?,
      availableToTime: json['available_to_time'] as String?,
      is24x7: json['is_24x7'] as bool? ?? false,
      instantBooking: json['instant_booking'] as bool? ?? true,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      advanceBookingDays: json['advance_booking_days'] as int? ?? 30,
      isActive: json['is_active'] as bool? ?? true,
      isPublished: json['is_published'] as bool? ?? false,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      parkingRules: json['parking_rules'] as String?,
      accessInstructions: json['access_instructions'] as String?,
      totalBookings: json['total_bookings'] as int? ?? 0,
      averageRating: json['average_rating'] != null ? (json['average_rating'] as num).toDouble() : null,
      totalReviews: json['total_reviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
    );
  }

  /// Helper to parse JSON arrays to `List<String>`
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'price_per_hour': pricePerHour,
      'price_per_day': pricePerDay,
      'minimum_hours': minimumHours,
      'total_slots': totalSlots,
      'available_slots': availableSlots,
      'amenities': amenities,
      'images': images,
      'available_days': availableDays,
      'available_from_time': availableFromTime,
      'available_to_time': availableToTime,
      'is_24x7': is24x7,
      'instant_booking': instantBooking,
      'requires_approval': requiresApproval,
      'advance_booking_days': advanceBookingDays,
      'is_active': isActive,
      'is_published': isPublished,
      'verification_status': verificationStatus,
      'parking_rules': parkingRules,
      'access_instructions': accessInstructions,
      'total_bookings': totalBookings,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ParkingListing copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    double? latitude,
    double? longitude,
    double? pricePerHour,
    double? pricePerDay,
    double? minimumHours,
    int? totalSlots,
    int? availableSlots,
    List<String>? amenities,
    List<String>? images,
    List<String>? availableDays,
    String? availableFromTime,
    String? availableToTime,
    bool? is24x7,
    bool? instantBooking,
    bool? requiresApproval,
    int? advanceBookingDays,
    bool? isActive,
    bool? isPublished,
    String? verificationStatus,
    String? parkingRules,
    String? accessInstructions,
    int? totalBookings,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return ParkingListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      minimumHours: minimumHours ?? this.minimumHours,
      totalSlots: totalSlots ?? this.totalSlots,
      availableSlots: availableSlots ?? this.availableSlots,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      availableDays: availableDays ?? this.availableDays,
      availableFromTime: availableFromTime ?? this.availableFromTime,
      availableToTime: availableToTime ?? this.availableToTime,
      is24x7: is24x7 ?? this.is24x7,
      instantBooking: instantBooking ?? this.instantBooking,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
      isActive: isActive ?? this.isActive,
      isPublished: isPublished ?? this.isPublished,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      parkingRules: parkingRules ?? this.parkingRules,
      accessInstructions: accessInstructions ?? this.accessInstructions,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}

/// Entity for parking listing with distance information
class ParkingListingWithDistance {
  final ParkingListing listing;
  final double distanceInMeters;

  const ParkingListingWithDistance({
    required this.listing,
    required this.distanceInMeters,
  });

  String get formattedDistance {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  factory ParkingListingWithDistance.fromJson(Map<String, dynamic> json) {
    return ParkingListingWithDistance(
      listing: ParkingListing.fromJson(json),
      distanceInMeters: json['distance_meters'] != null
        ? (json['distance_meters'] as num).toDouble()
        : 0.0,
    );
  }
}
