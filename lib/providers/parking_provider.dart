import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/parking_spot.dart';
import '../services/parking_service.dart';

/// Parking State
class ParkingState {
  final List<ParkingSpot> spots;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ParkingState({
    this.spots = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ParkingState copyWith({
    List<ParkingSpot>? spots,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ParkingState(
      spots: spots ?? this.spots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get today's parking spot
  ParkingSpot? get todaySpot {
    final today = DateTime.now();
    try {
      return spots.firstWhere(
        (spot) =>
            spot.date.year == today.year &&
            spot.date.month == today.month &&
            spot.date.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get available spots count
  int get availableCarSlots => todaySpot?.activeCarSlots ?? 0;
  int get availableBikeSlots => todaySpot?.activeBikeSlots ?? 0;
  int get totalAvailableSlots => availableCarSlots + availableBikeSlots;
}

/// Parking Notifier
class ParkingNotifier extends StateNotifier<ParkingState> {
  final ParkingService _parkingService;
  RealtimeChannel? _realtimeChannel;

  ParkingNotifier(this._parkingService) : super(const ParkingState()) {
    _init();
  }

  /// Initialize - fetch data and setup real-time
  Future<void> _init() async {
    await fetchParkingSlots();
    _setupRealtime();
  }

  /// Fetch all parking slots
  Future<void> fetchParkingSlots() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final spots = await _parkingService.fetchActiveParkingSlots();
      state = state.copyWith(
        spots: spots,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Setup real-time subscription
  void _setupRealtime() {
    _realtimeChannel = _parkingService.subscribeToParkingChanges(
      onInsert: (spot) {
        // Add new spot to list
        final updatedSpots = [...state.spots, spot];
        updatedSpots.sort((a, b) => a.date.compareTo(b.date));
        state = state.copyWith(
          spots: updatedSpots,
          lastUpdated: DateTime.now(),
        );
      },
      onUpdate: (spot) {
        // Update existing spot
        final updatedSpots = state.spots.map((s) {
          return s.id == spot.id ? spot : s;
        }).toList();
        state = state.copyWith(
          spots: updatedSpots,
          lastUpdated: DateTime.now(),
        );
      },
      onDelete: (id) {
        // Remove deleted spot
        final updatedSpots = state.spots.where((s) => s.id != id).toList();
        state = state.copyWith(
          spots: updatedSpots,
          lastUpdated: DateTime.now(),
        );
      },
    );
  }

  /// Refresh data manually
  Future<void> refresh() async {
    await fetchParkingSlots();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}

/// Parking Service Provider
final parkingServiceProvider = Provider<ParkingService>((ref) {
  return ParkingService();
});

/// Parking State Provider
final parkingProvider = StateNotifierProvider<ParkingNotifier, ParkingState>((ref) {
  final parkingService = ref.watch(parkingServiceProvider);
  return ParkingNotifier(parkingService);
});

/// Today's Parking Spot Provider
final todayParkingProvider = Provider<ParkingSpot?>((ref) {
  final parkingState = ref.watch(parkingProvider);
  return parkingState.todaySpot;
});

/// Available Slots Provider
final availableSlotsProvider = Provider<Map<String, int>>((ref) {
  final parkingState = ref.watch(parkingProvider);
  return {
    'car': parkingState.availableCarSlots,
    'bike': parkingState.availableBikeSlots,
    'total': parkingState.totalAvailableSlots,
  };
});
