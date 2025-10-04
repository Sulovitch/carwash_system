import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class ReceptionistService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  String _getReceptionistsCacheKey(String carWashId) =>
      'receptionists_$carWashId';
  String _getReservationsCacheKey(String carWashId) =>
      'reservations_carwash_$carWashId';

  Future<ApiResponse<bool>> addReceptionist({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String carWashId,
  }) async {
    try {
      AppLogger.network('POST', '${ApiConfig.receptionistEndpoint}?action=add');

      final response = await _network.post(
        Uri.parse(ApiConfig.receptionistEndpoint),
        body: {
          'action': 'add',
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'car_wash_id': carWashId,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كاش الموظفين عند الإضافة
          _cache.clearDataCache(_getReceptionistsCacheKey(carWashId));

          AppLogger.success('تم إضافة موظف استقبال: $name');
          return ApiResponse.success(true, 'تم إضافة الموظف بنجاح');
        } else {
          AppLogger.warning('فشل إضافة الموظف: ${data['message']}');
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة الموظف');
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في addReceptionist', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, String>>>> fetchReceptionists(
    String carWashId,
  ) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = _getReceptionistsCacheKey(carWashId);
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام الموظفين من الكاش', 'Receptionists');
        return ApiResponse.success(cached as List<Map<String, String>>);
      }

      final url =
          '${ApiConfig.fetchReceptionistsEndpoint}?car_wash_id=$carWashId';
      AppLogger.network('GET', url);

      final response = await _network.get(
        Uri.parse(url),
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final receptionists = (data['receptionists'] as List<dynamic>)
              .map<Map<String, String>>((receptionist) =>
                  (receptionist as Map<String, dynamic>).map<String, String>(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ))
              .toList();

          // حفظ في الكاش لمدة 10 دقائق
          _cache.cacheData(
            cacheKey,
            receptionists,
            duration: const Duration(minutes: 10),
          );

          AppLogger.success('تم جلب ${receptionists.length} موظف');
          return ApiResponse.success(receptionists);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الموظفين');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchReceptionists', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> updateReceptionist({
    required String receptionistId,
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    try {
      AppLogger.network(
          'POST', '${ApiConfig.receptionistEndpoint}?action=edit');

      final body = {
        'action': 'edit',
        'receptionist_id': receptionistId,
        'name': name,
        'email': email,
        'phone': phone,
      };

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await _network.post(
        Uri.parse(ApiConfig.receptionistEndpoint),
        body: body,
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كل كاش الموظفين
          _cache.clearCache();

          AppLogger.success('تم تحديث الموظف: $receptionistId');
          return ApiResponse.success(true, 'تم تحديث معلومات الموظف بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الموظف');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateReceptionist', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> deleteReceptionist(String receptionistId) async {
    try {
      AppLogger.network(
          'POST', '${ApiConfig.receptionistEndpoint}?action=delete');

      final response = await _network.post(
        Uri.parse(ApiConfig.receptionistEndpoint),
        body: {
          'action': 'delete',
          'receptionist_id': receptionistId,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كل كاش الموظفين
          _cache.clearCache();

          AppLogger.success('تم حذف الموظف: $receptionistId');
          return ApiResponse.success(true, 'تم حذف الموظف بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف الموظف');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في deleteReceptionist', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchReservationsForCarWash(
    String carWashId,
  ) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = _getReservationsCacheKey(carWashId);
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام حجوزات المغسلة من الكاش', 'Reservations');
        return ApiResponse.success(cached as List<Map<String, dynamic>>);
      }

      AppLogger.network('POST', ApiConfig.fetchReservationsEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.fetchReservationsEndpoint),
        body: {'car_wash_id': carWashId},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final reservations = (data['reservations'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          // حفظ في الكاش لمدة 2 دقيقة (البيانات تتغير بسرعة)
          _cache.cacheData(
            cacheKey,
            reservations,
            duration: const Duration(minutes: 2),
          );

          AppLogger.success('تم جلب ${reservations.length} حجز للمغسلة');
          return ApiResponse.success(reservations);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الحجوزات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchReservationsForCarWash', e, stack);
      return ApiResponse.error(e.toString());
    }
  }
}
