import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../domain/entities/parking_spot.dart';

/// Parking Service
/// Handles all parking-related operations with Supabase
class ParkingService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Fetch all active parking slots
  Future<List<ParkingSpot>> fetchActiveParkingSlots() async {
    try {
      final response = await _supabase
          .from('parking_active_slots')
          .select()
          .order('date', ascending: true);

      return (response as List)
          .map((json) => ParkingSpot.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch parking slots: ${e.toString()}');
    }
  }

  /// Fetch parking slots for a specific date
  Future<ParkingSpot?> fetchParkingSlotByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0]; // Get YYYY-MM-DD
      final response = await _supabase
          .from('parking_active_slots')
          .select()
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return ParkingSpot.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch parking slot: ${e.toString()}');
    }
  }

  /// Fetch parking slots for today
  Future<ParkingSpot?> fetchTodayParkingSlots() async {
    return fetchParkingSlotByDate(DateTime.now());
  }

  /// Get real-time stream of parking slots
  /// This will automatically update when data changes in Supabase
  Stream<List<ParkingSpot>> watchActiveParkingSlots() {
    return _supabase
        .from('parking_active_slots')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true)
        .map((data) => data.map((json) => ParkingSpot.fromJson(json)).toList());
  }

  /// Get real-time stream for today's parking
  Stream<ParkingSpot?> watchTodayParkingSlots() {
    final today = DateTime.now().toIso8601String().split('T')[0];

    return _supabase
        .from('parking_active_slots')
        .stream(primaryKey: ['id'])
        .eq('date', today)
        .map((data) {
          if (data.isEmpty) return null;
          return ParkingSpot.fromJson(data.first);
        });
  }

  /// Subscribe to real-time changes
  /// Returns a RealtimeChannel that can be unsubscribed
  RealtimeChannel subscribeToParkingChanges({
    required void Function(ParkingSpot spot) onInsert,
    required void Function(ParkingSpot spot) onUpdate,
    required void Function(String id) onDelete,
  }) {
    final channel = _supabase.channel('parking_active_slots_changes');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'parking_active_slots',
          callback: (payload) {
            final spot = ParkingSpot.fromJson(payload.newRecord);
            onInsert(spot);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'parking_active_slots',
          callback: (payload) {
            final spot = ParkingSpot.fromJson(payload.newRecord);
            onUpdate(spot);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'parking_active_slots',
          callback: (payload) {
            final id = payload.oldRecord['id'] as String;
            onDelete(id);
          },
        )
        .subscribe();

    return channel;
  }

  /// Check availability for specific slot type
  Future<bool> hasAvailableCarSlots(DateTime date) async {
    final spot = await fetchParkingSlotByDate(date);
    return spot != null && spot.activeCarSlots > 0;
  }

  Future<bool> hasAvailableBikeSlots(DateTime date) async {
    final spot = await fetchParkingSlotByDate(date);
    return spot != null && spot.activeBikeSlots > 0;
  }
}
