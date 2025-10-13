// lib/services/availability_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class AvailabilityService {
  Future<AvailabilityResponse> checkAvailability({
    required String carWashId,
    required String date,
    required String time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/check_availability.php'),
        body: {
          'car_wash_id': carWashId,
          'date': date,
          'time': time,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AvailabilityResponse.fromJson(data);
      } else {
        throw Exception('Failed to check availability');
      }
    } catch (e) {
      throw Exception('Error checking availability: $e');
    }
  }
  
  Future<ReservationResponse> reserveSlot({
    required String carWashId,
    required String date,
    required String time,
    required String userId,
    required String carId,
    required String serviceId,
    required String bookingSource,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reserve_slot.php'),
        body: {
          'car_wash_id': carWashId,
          'date': date,
          'time': time,
          'user_id': userId,
          'car_id': carId,
          'service_id': serviceId,
          'booking_source': bookingSource,
          if (createdBy != null) 'created_by': createdBy,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReservationResponse.fromJson(data);
      } else {
        throw Exception('Failed to reserve slot');
      }
    } catch (e) {
      throw Exception('Error reserving slot: $e');
    }
  }
}