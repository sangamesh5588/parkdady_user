class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String role; // Legacy field (can be null/ignored)
  final bool isRenter; // TRUE when user uses RENTER app
  final bool isHost; // TRUE when user uses HOST app

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.role = '', // Legacy field
    this.isRenter = false,
    this.isHost = false,
  });

  // Factory constructor for creating a user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      role: json['role'] ?? '',
      isRenter: json['is_renter'] ?? false,
      isHost: json['is_host'] ?? false,
    );
  }

  // Method to convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
      'is_renter': isRenter,
      'is_host': isHost,
    };
  }

  // Factory constructor for creating a user from Supabase User
  factory User.fromSupabaseUser(dynamic supabaseUser, {String? name}) {
    // Default to renter if no profile data provided (backward compatibility)
    return User(
      id: supabaseUser.id ?? '',
      name: name ?? supabaseUser.userMetadata?['full_name'] ?? supabaseUser.email ?? '',
      email: supabaseUser.email ?? '',
      createdAt: supabaseUser.createdAt != null
          ? DateTime.parse(supabaseUser.createdAt)
          : DateTime.now(),
      role: 'renter', // Default role - will be overridden by profile data
    );
  }

  // Factory constructor for creating a user from Supabase User with profile data
  factory User.fromSupabaseUserWithProfile(dynamic supabaseUser, Map<String, dynamic>? profile) {
    final role = profile?['role'] ?? ''; // Legacy field
    final fullName = profile?['full_name'] ?? supabaseUser.userMetadata?['full_name'] ?? supabaseUser.email ?? '';
    final isRenter = profile?['is_renter'] ?? false;
    final isHost = profile?['is_host'] ?? false;

    return User(
      id: supabaseUser.id ?? '',
      name: fullName,
      email: supabaseUser.email ?? '',
      createdAt: supabaseUser.createdAt != null
          ? DateTime.parse(supabaseUser.createdAt)
          : DateTime.now(),
      role: role,
      isRenter: isRenter,
      isHost: isHost,
    );
  }

  // Copy with method for immutability
  User copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    String? role,
    bool? isRenter,
    bool? isHost,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isRenter: isRenter ?? this.isRenter,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
