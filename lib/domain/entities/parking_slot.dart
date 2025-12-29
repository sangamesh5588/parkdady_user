/// Entity for individual parking slots
class ParkingSlot {
  final String id;
  final String parkingSpaceId;
  final String slotNumber;
  final String slotType;
  final bool isAvailable;
  final DateTime availableFrom;
  final DateTime? availableUntil;
  final double? pricePerHour;
  final List<String> features;
  final String? floorLevel;
  final String? currentBookingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSlot({
    required this.id,
    required this.parkingSpaceId,
    required this.slotNumber,
    this.slotType = 'standard',
    this.isAvailable = true,
    required this.availableFrom,
    this.availableUntil,
    this.pricePerHour,
    this.features = const [],
    this.floorLevel,
    this.currentBookingId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      id: json['id'] as String,
      parkingSpaceId: json['parking_space_id'] as String,
      slotNumber: json['slot_number'] as String,
      slotType: json['slot_type'] as String? ?? 'standard',
      isAvailable: json['is_available'] as bool? ?? true,
      availableFrom: DateTime.parse(json['available_from'] as String),
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      pricePerHour: json['price_per_hour'] != null
          ? (json['price_per_hour'] as num).toDouble()
          : null,
      features: _parseStringList(json['features']) ?? [],
      floorLevel: json['floor_level'] as String?,
      currentBookingId: json['current_booking_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      'parking_space_id': parkingSpaceId,
      'slot_number': slotNumber,
      'slot_type': slotType,
      'is_available': isAvailable,
      'available_from': availableFrom.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'price_per_hour': pricePerHour,
      'features': features,
      'floor_level': floorLevel,
      'current_booking_id': currentBookingId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  ParkingSlot copyWith({
    String? id,
    String? parkingSpaceId,
    String? slotNumber,
    String? slotType,
    bool? isAvailable,
    DateTime? availableFrom,
    DateTime? availableUntil,
    double? pricePerHour,
    List<String>? features,
    String? floorLevel,
    String? currentBookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingSlot(
      id: id ?? this.id,
      parkingSpaceId: parkingSpaceId ?? this.parkingSpaceId,
      slotNumber: slotNumber ?? this.slotNumber,
      slotType: slotType ?? this.slotType,
      isAvailable: isAvailable ?? this.isAvailable,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      features: features ?? this.features,
      floorLevel: floorLevel ?? this.floorLevel,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get slotTypeDisplay {
    switch (slotType) {
      case 'standard':
        return 'Standard';
      case 'compact':
        return 'Compact';
      case 'ev':
        return 'EV Charging';
      case 'disabled':
        return 'Accessible';
      case 'motorcycle':
        return 'Motorcycle';
      default:
        return slotType;
    }
  }
}
