import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class ReservationService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  Future<ApiResponse<bool>> saveReservation({
    required String userId,
    required String carId,
    required String serviceId,
    required String date,
    required String time,
  }) async {
    try {
      AppLogger.network('POST', ApiConfig.reservationEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.reservationEndpoint),
        body: {
          'user_id': userId,
          'car_id': carId,
          'service_id': serviceId,
          'date': date,
          'time': time,
          'status': 'Pending',
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح الكاش عند إضافة حجز جديد
          _cache.clearDataCache('user_reservations_$userId');

          AppLogger.success('تم حجز الموعد بنجاح');
          return ApiResponse.success(true, 'تم حجز الموعد بنجاح');
        } else {
          AppLogger.warning('فشل الحجز: ${data['message']}');
          return ApiResponse.error(data['message'] ?? 'فشل في حجز الموعد');
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في saveReservation', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchUserReservations(
    String userId,
  ) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = 'user_reservations_$userId';
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام بيانات من الكاش', 'Reservations');
        return ApiResponse.success(cached as List<Map<String, dynamic>>);
      }

      AppLogger.network('POST', ApiConfig.fetchUserReservationsEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.fetchUserReservationsEndpoint),
        body: {'user_id': userId},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final reservations = (data['reservations'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          // حفظ في الكاش
          _cache.cacheData(cacheKey, reservations);

          AppLogger.success('تم جلب ${reservations.length} حجز');
          return ApiResponse.success(reservations);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الحجوزات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchUserReservations', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> cancelReservation(int reservationId) async {
    try {
      AppLogger.network('POST', ApiConfig.cancelReservationEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.cancelReservationEndpoint),
        body: {'reservation_id': reservationId.toString()},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح الكاش عند الإلغاء
          _cache.clearCache();

          AppLogger.success('تم إلغاء الحجز');
          return ApiResponse.success(true, 'تم إلغاء الحجز بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إلغاء الحجز');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في cancelReservation', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> updateReservationStatus({
    required int reservationId,
    required String status,
  }) async {
    try {
      final response = await _network.post(
        Uri.parse(ApiConfig.updateReservationStatusEndpoint),
        body: {
          'reservation_id': reservationId.toString(),
          'status': status,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          _cache.clearCache();
          return ApiResponse.success(true, 'تم تحديث حالة الحجز');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الحالة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateReservationStatus', e, stack);
      return ApiResponse.error(e.toString());
    }
  }
}
