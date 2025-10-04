import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class ProfileService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  String _getUserProfileCacheKey(String userId) => 'user_profile_$userId';
  String _getOwnerProfileCacheKey(String ownerId) => 'owner_profile_$ownerId';

  Future<ApiResponse<bool>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      AppLogger.network('POST', ApiConfig.updateUserProfileEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.updateUserProfileEndpoint),
        body: {
          'userId': userId,
          'name': name,
          'email': email,
          'phone': phone,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كاش الملف الشخصي عند التحديث
          _cache.clearDataCache(_getUserProfileCacheKey(userId));

          AppLogger.success('تم تحديث ملف المستخدم: $userId');
          return ApiResponse.success(true, 'تم تحديث الملف الشخصي بنجاح');
        } else {
          AppLogger.warning('فشل تحديث الملف: ${data['message']}');
          return ApiResponse.error(
            data['message'] ?? 'فشل في تحديث الملف الشخصي',
          );
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateUserProfile', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> updateOwnerProfile({
    required String ownerId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      AppLogger.network('POST', ApiConfig.updateOwnerProfileEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.updateOwnerProfileEndpoint),
        body: {
          'userId': ownerId,
          'name': name,
          'email': email,
          'phone': phone,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كاش الملف الشخصي عند التحديث
          _cache.clearDataCache(_getOwnerProfileCacheKey(ownerId));

          AppLogger.success('تم تحديث ملف المالك: $ownerId');
          return ApiResponse.success(true, 'تم تحديث الملف الشخصي بنجاح');
        } else {
          AppLogger.warning('فشل تحديث ملف المالك: ${data['message']}');
          return ApiResponse.error(
            data['message'] ?? 'فشل في تحديث الملف الشخصي',
          );
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateOwnerProfile', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, String>>> getProfile({
    required String userId,
    required bool isOwner,
  }) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = isOwner
          ? _getOwnerProfileCacheKey(userId)
          : _getUserProfileCacheKey(userId);

      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام الملف الشخصي من الكاش', 'Profile');
        return ApiResponse.success(cached as Map<String, String>);
      }

      final endpoint = isOwner
          ? '${ApiConfig.baseUrl}/get_owner_profile.php'
          : '${ApiConfig.baseUrl}/get_user_profile.php';

      AppLogger.network('POST', endpoint);

      final response = await _network.post(
        Uri.parse(endpoint),
        body: {'userId': userId},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['profile'] != null) {
          final profile = {
            'userId': data['profile']['id']?.toString() ?? userId,
            'name': data['profile']['name']?.toString() ?? '',
            'email': data['profile']['email']?.toString() ?? '',
            'phone': data['profile']['phone']?.toString() ?? '',
          };

          // حفظ في الكاش لمدة 10 دقائق
          _cache.cacheData(
            cacheKey,
            profile,
            duration: const Duration(minutes: 10),
          );

          AppLogger.success('تم جلب الملف الشخصي: $userId');
          return ApiResponse.success(profile);
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل في جلب الملف الشخصي',
          );
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في getProfile', e, stack);
      return ApiResponse.error(e.toString());
    }
  }
}
