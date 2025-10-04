import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class CarWashService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  static const String _carWashesCacheKey = 'all_carwashes';

  Future<ApiResponse<Map<String, dynamic>>> saveCarWashInfo({
    required String ownerId,
    required String name,
    required String location,
    required String phone,
    required String openTime,
    required String closeTime,
    required String duration,
    required String capacity,
  }) async {
    try {
      AppLogger.network('POST', ApiConfig.carWashEndpoint);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.carWashEndpoint),
      )
        ..fields['name'] = name
        ..fields['location'] = location
        ..fields['phone'] = phone
        ..fields['OwnerId'] = ownerId
        ..fields['openTime'] = openTime
        ..fields['closeTime'] = closeTime
        ..fields['duration'] = duration
        ..fields['capacity'] = capacity;

      final response = await request.send().timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
          );

      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);

        if (data['success'] == true) {
          // مسح كاش المغاسل عند الإضافة
          _cache.clearDataCache(_carWashesCacheKey);

          AppLogger.success('تم حفظ معلومات المغسلة');
          return ApiResponse.success(data, 'تم حفظ معلومات المغسلة بنجاح');
        } else {
          AppLogger.warning('فشل حفظ المغسلة: ${data['message']}');
          return ApiResponse.error(data['message'] ?? 'فشل في حفظ المعلومات');
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في saveCarWashInfo', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchCarWashes() async {
    try {
      // تحقق من الكاش أولاً
      final cached = _cache.getData(_carWashesCacheKey);

      if (cached != null) {
        AppLogger.info('استخدام بيانات المغاسل من الكاش');
        return ApiResponse.success(cached as List<Map<String, dynamic>>);
      }

      AppLogger.network('GET', ApiConfig.fetchCarWashesEndpoint);

      final response = await _network.get(
        Uri.parse(ApiConfig.fetchCarWashesEndpoint),
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final carWashes = (data['carWashes'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          // حفظ في الكاش لمدة 5 دقائق
          _cache.cacheData(
            _carWashesCacheKey,
            carWashes,
            duration: const Duration(minutes: 5),
          );

          AppLogger.success('تم جلب ${carWashes.length} مغسلة');
          return ApiResponse.success(carWashes);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب المغاسل');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchCarWashes', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCarWashInfo({
    required String carWashId,
    required String name,
    required String location,
    required String phone,
    required String openTime,
    required String closeTime,
    required String duration,
    required String capacity,
  }) async {
    try {
      AppLogger.network('POST', '${ApiConfig.carWashEndpoint}?action=update');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.carWashEndpoint),
      )
        ..fields['action'] = 'update'
        ..fields['carWashId'] = carWashId
        ..fields['name'] = name
        ..fields['location'] = location
        ..fields['phone'] = phone
        ..fields['openTime'] = openTime
        ..fields['closeTime'] = closeTime
        ..fields['duration'] = duration
        ..fields['capacity'] = capacity;

      final response = await request.send().timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
          );

      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);

        if (data['success'] == true) {
          // مسح الكاش عند التحديث
          _cache.clearDataCache(_carWashesCacheKey);

          AppLogger.success('تم تحديث المغسلة');
          return ApiResponse.success(data, 'تم تحديث معلومات المغسلة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في التحديث');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateCarWashInfo', e, stack);
      return ApiResponse.error(e.toString());
    }
  }
}
