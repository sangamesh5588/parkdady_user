class Vehicle {
  final String id;
  final String userId;
  final String licensePlate;
  final String make;
  final String model;
  final String? color;
  final int? year;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.licensePlate,
    required this.make,
    required this.model,
    this.color,
    this.year,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor for creating a vehicle from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      color: json['color'],
      year: json['year'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Method to convert vehicle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'license_plate': licensePlate,
      'make': make,
      'model': model,
      'color': color,
      'year': year,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Method to convert vehicle to JSON for API requests (without id and timestamps)
  Map<String, dynamic> toJsonForApi() {
    final data = <String, dynamic>{
      'license_plate': licensePlate,
      'make': make,
      'model': model,
    };

    if (color != null) data['color'] = color;
    if (year != null) data['year'] = year;
    data['is_default'] = isDefault;

    return data;
  }

  // Copy with method for immutability
  Vehicle copyWith({
    String? id,
    String? userId,
    String? licensePlate,
    String? make,
    String? model,
    String? color,
    int? year,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      licensePlate: licensePlate ?? this.licensePlate,
      make: make ?? this.make,
      model: model ?? this.model,
      color: color ?? this.color,
      year: year ?? this.year,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display name for the vehicle
  String get displayName => '$make $model';

  // Get full display info including license plate
  String get displayInfo => '$make $model - $licensePlate';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
