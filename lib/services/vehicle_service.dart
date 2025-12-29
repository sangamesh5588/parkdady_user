import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../domain/entities/vehicle.dart';

/// Vehicle Service
/// Handles all vehicle-related operations with Supabase
class VehicleService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Fetch all vehicles for the current user
  Future<List<Vehicle>> fetchUserVehicles() async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Vehicle.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch vehicles: ${e.toString()}');
    }
  }

  /// Add a new vehicle
  Future<Vehicle> addVehicle({
    required String licensePlate,
    required String make,
    required String model,
    String? color,
    int? year,
    bool isDefault = false,
  }) async {
    try {
      final vehicleData = {
        'license_plate': licensePlate,
        'make': make,
        'model': model,
        'color': color,
        'year': year,
        'is_default': isDefault,
      };

      final response = await _supabase
          .from('vehicles')
          .insert(vehicleData)
          .select()
          .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add vehicle: ${e.toString()}');
    }
  }

  /// Update an existing vehicle
  Future<Vehicle> updateVehicle({
    required String vehicleId,
    String? licensePlate,
    String? make,
    String? model,
    String? color,
    int? year,
    bool? isDefault,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (licensePlate != null) updateData['license_plate'] = licensePlate;
      if (make != null) updateData['make'] = make;
      if (model != null) updateData['model'] = model;
      if (color != null) updateData['color'] = color;
      if (year != null) updateData['year'] = year;
      if (isDefault != null) updateData['is_default'] = isDefault;

      final response = await _supabase
          .from('vehicles')
          .update(updateData)
          .eq('id', vehicleId)
          .select()
          .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update vehicle: ${e.toString()}');
    }
  }

  /// Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _supabase
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);
    } catch (e) {
      throw Exception('Failed to delete vehicle: ${e.toString()}');
    }
  }

  /// Set a vehicle as the default
  Future<Vehicle> setDefaultVehicle(String vehicleId) async {
    try {
      // First, set all vehicles for the user to not default
      await _supabase
          .from('vehicles')
          .update({'is_default': false})
          .neq('id', vehicleId);

      // Then set the specified vehicle as default
      final response = await _supabase
          .from('vehicles')
          .update({'is_default': true})
          .eq('id', vehicleId)
          .select()
          .single();

      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to set default vehicle: ${e.toString()}');
    }
  }

  /// Get a specific vehicle by ID
  Future<Vehicle?> getVehicleById(String vehicleId) async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('id', vehicleId)
          .maybeSingle();

      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch vehicle: ${e.toString()}');
    }
  }

  /// Get the default vehicle for the current user
  Future<Vehicle?> getDefaultVehicle() async {
    try {
      final response = await _supabase
          .from('vehicles')
          .select()
          .eq('is_default', true)
          .maybeSingle();

      if (response == null) return null;
      return Vehicle.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch default vehicle: ${e.toString()}');
    }
  }

  /// Get real-time stream of user vehicles
  /// This will automatically update when data changes in Supabase
  Stream<List<Vehicle>> watchUserVehicles() {
    return _supabase
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .order('is_default', ascending: false)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Vehicle.fromJson(json)).toList());
  }

  /// Subscribe to real-time vehicle changes
  /// Returns a RealtimeChannel that can be unsubscribed
  RealtimeChannel subscribeToVehicleChanges({
    required void Function(Vehicle vehicle) onInsert,
    required void Function(Vehicle vehicle) onUpdate,
    required void Function(String id) onDelete,
  }) {
    final channel = _supabase.channel('vehicles_changes');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'vehicles',
          callback: (payload) {
            final vehicle = Vehicle.fromJson(payload.newRecord);
            onInsert(vehicle);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'vehicles',
          callback: (payload) {
            final vehicle = Vehicle.fromJson(payload.newRecord);
            onUpdate(vehicle);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'vehicles',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String;
            onDelete(id);
          },
        )
        .subscribe();

    return channel;
  }
}
