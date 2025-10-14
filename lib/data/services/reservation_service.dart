import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/api_response.dart';

class ReservationService {
  Future<ApiResponse<bool>> saveReservation({
    required String userId,
    required String carId,
    required String serviceId,
    required String date,
    required String time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reservationEndpoint),
        body: {
          'user_id': userId,
          'car_id': carId,
          'service_id': serviceId,
          'date': date,
          'time': time,
          'status': 'Pending',
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم حجز الموعد بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حجز الموعد');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchUserReservations(
    String userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.fetchUserReservationsEndpoint),
        body: {'user_id': userId},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final reservations = (data['reservations'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          return ApiResponse.success(reservations);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الحجوزات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> cancelReservation(int reservationId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.cancelReservationEndpoint),
        body: {'reservation_id': reservationId.toString()},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم إلغاء الحجز بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إلغاء الحجز');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> updateReservationStatus({
    required int reservationId,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateReservationStatusEndpoint),
        body: {
          'reservation_id': reservationId.toString(),
          'status': status,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم تحديث حالة الحجز');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الحالة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
