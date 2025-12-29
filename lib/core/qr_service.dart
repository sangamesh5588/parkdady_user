import 'dart:convert';
import 'package:uuid/uuid.dart';

class QRService {
  static const String _appIdentifier = 'PARKING_APP';

  /// Generate QR code data for a booking
  static String generateBookingQR({
    required String bookingId,
    required String parkingSpaceId,
    required String userId,
    required String hostId,
    required DateTime startTime,
    required DateTime endTime,
    required String vehicleNumber,
    required double totalAmount,
  }) {
    final qrData = {
      'app': _appIdentifier,
      'version': '1.0',
      'type': 'booking',
      'bookingId': bookingId,
      'parkingSpaceId': parkingSpaceId,
      'userId': userId,
      'hostId': hostId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'totalAmount': totalAmount,
      'timestamp': DateTime.now().toIso8601String(),
      'validUntil': endTime.add(const Duration(hours: 2)).toIso8601String(), // Valid 2 hours after booking ends
    };

    return jsonEncode(qrData);
  }

  /// Parse QR code data and validate booking
  static QRBookingData? parseBookingQR(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);

      // Validate app identifier and type
      if (data['app'] != _appIdentifier || data['type'] != 'booking') {
        return null;
      }

      // Check if QR code is still valid
      final validUntil = DateTime.parse(data['validUntil']);
      if (DateTime.now().isAfter(validUntil)) {
        return null; // QR code expired
      }

      return QRBookingData(
        bookingId: data['bookingId'],
        parkingSpaceId: data['parkingSpaceId'],
        userId: data['userId'],
        hostId: data['hostId'],
        startTime: DateTime.parse(data['startTime']),
        endTime: DateTime.parse(data['endTime']),
        vehicleNumber: data['vehicleNumber'],
        totalAmount: data['totalAmount'].toDouble(),
        timestamp: DateTime.parse(data['timestamp']),
        validUntil: validUntil,
      );
    } catch (e) {
      return null; // Invalid QR data
    }
  }

  /// Generate a unique booking ID
  static String generateBookingId() {
    const uuid = Uuid();
    return 'BK-${uuid.v4().substring(0, 8).toUpperCase()}';
  }

  /// Validate if a QR code is from our app
  static bool isValidAppQR(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);
      return data['app'] == _appIdentifier;
    } catch (e) {
      return false;
    }
  }
}

class QRBookingData {
  final String bookingId;
  final String parkingSpaceId;
  final String userId;
  final String hostId;
  final DateTime startTime;
  final DateTime endTime;
  final String vehicleNumber;
  final double totalAmount;
  final DateTime timestamp;
  final DateTime validUntil;

  const QRBookingData({
    required this.bookingId,
    required this.parkingSpaceId,
    required this.userId,
    required this.hostId,
    required this.startTime,
    required this.endTime,
    required this.vehicleNumber,
    required this.totalAmount,
    required this.timestamp,
    required this.validUntil,
  });

  /// Check if booking is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if booking is expired
  bool get isExpired {
    return DateTime.now().isAfter(endTime);
  }

  /// Check if booking is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startTime);
  }

  /// Get remaining time until booking starts
  Duration? get timeUntilStart {
    if (isUpcoming) {
      return startTime.difference(DateTime.now());
    }
    return null;
  }

  /// Get remaining time until booking ends
  Duration? get timeUntilEnd {
    if (isActive) {
      return endTime.difference(DateTime.now());
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'parkingSpaceId': parkingSpaceId,
      'userId': userId,
      'hostId': hostId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
    };
  }
}
