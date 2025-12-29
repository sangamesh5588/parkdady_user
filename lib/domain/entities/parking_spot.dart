/// Parking Spot Entity
/// Represents a parking spot with real-time availability
class ParkingSpot {
  final String id;
  final String? listingId;
  final DateTime date;
  final int activeCarSlots;
  final int activeBikeSlots;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSpot({
    required this.id,
    this.listingId,
    required this.date,
    required this.activeCarSlots,
    required this.activeBikeSlots,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Supabase JSON
  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] ?? '',
      listingId: json['listing_id'],
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      activeCarSlots: json['active_car_slots'] ?? 0,
      activeBikeSlots: json['active_bike_slots'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (listingId != null) 'listing_id': listingId,
      'date': date.toIso8601String(),
      'active_car_slots': activeCarSlots,
      'active_bike_slots': activeBikeSlots,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if any slots are available
  bool get hasAvailability => activeCarSlots > 0 || activeBikeSlots > 0;

  /// Get total available slots
  int get totalAvailableSlots => activeCarSlots + activeBikeSlots;

  /// Copy with method
  ParkingSpot copyWith({
    String? id,
    String? listingId,
    DateTime? date,
    int? activeCarSlots,
    int? activeBikeSlots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      date: date ?? this.date,
      activeCarSlots: activeCarSlots ?? this.activeCarSlots,
      activeBikeSlots: activeBikeSlots ?? this.activeBikeSlots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingSpot && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ParkingSpot(id: $id, listingId: $listingId, date: $date, cars: $activeCarSlots, bikes: $activeBikeSlots)';
  }
}
