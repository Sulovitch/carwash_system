// lib/services/availability_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// استيراد ApiConfig من المشروع
class ApiConfig {
  static const String baseUrl =
      'YOUR_API_BASE_URL'; // استبدل هذا برابط API الخاص بك
}

// نموذج الاستجابة للتوفر
class AvailabilityResponse {
  final bool success;
  final bool available;
  final String? message;
  final int? availableSpots;
  final int? totalCapacity;

  AvailabilityResponse({
    required this.success,
    required this.available,
    this.message,
    this.availableSpots,
    this.totalCapacity,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return AvailabilityResponse(
      success: json['success'] == true || json['success'] == 1,
      available: json['available'] == true || json['available'] == 1,
      message: json['message'] as String?,
      availableSpots: json['available_spots'] != null
          ? int.tryParse(json['available_spots'].toString())
          : null,
      totalCapacity: json['total_capacity'] != null
          ? int.tryParse(json['total_capacity'].toString())
          : null,
    );
  }
}

// نموذج الاستجابة للحجز
class ReservationResponse {
  final bool success;
  final String? message;
  final int? reservationId;

  ReservationResponse({
    required this.success,
    this.message,
    this.reservationId,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      success: json['success'] == true || json['success'] == 1,
      message: json['message'] as String?,
      reservationId: json['reservation_id'] != null
          ? int.tryParse(json['reservation_id'].toString())
          : null,
    );
  }
}

class AvailabilityService {
  Future<AvailabilityResponse> checkAvailability({
    required String carWashId,
    required String date,
    required String time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/check_availability.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'car_wash_id': carWashId,
          'date': date,
          'time': time,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AvailabilityResponse.fromJson(data);
      } else {
        throw Exception('فشل التحقق من التوفر: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في التحقق من التوفر: $e');
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
      final Map<String, String> body = {
        'car_wash_id': carWashId,
        'date': date,
        'time': time,
        'user_id': userId,
        'car_id': carId,
        'service_id': serviceId,
        'booking_source': bookingSource,
      };

      if (createdBy != null) {
        body['created_by'] = createdBy;
      }

      final response = await http
          .post(
        Uri.parse('${ApiConfig.baseUrl}/reserve_slot.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ReservationResponse.fromJson(data);
      } else {
        throw Exception('فشل حجز الفترة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في حجز الفترة: $e');
    }
  }

  // دالة إضافية للحصول على الأوقات المتاحة ليوم كامل
  Future<List<String>> getAvailableTimesForDay({
    required String carWashId,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/get_available_times.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'car_wash_id': carWashId,
          'date': date,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['available_times'] != null) {
          return List<String>.from(data['available_times']);
        }
        return [];
      } else {
        throw Exception('فشل جلب الأوقات المتاحة');
      }
    } catch (e) {
      throw Exception('خطأ في جلب الأوقات المتاحة: $e');
    }
  }
}
