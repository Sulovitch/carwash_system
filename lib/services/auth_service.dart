import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class AuthService {
  final _network = NetworkHelper();

  Future<ApiResponse<Map<String, dynamic>>> signIn({
    required String login,
    required String password,
    required String userType,
  }) async {
    try {
      AppLogger.info('محاولة تسجيل الدخول كـ: $userType');
      AppLogger.network('POST', ApiConfig.authEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.authEndpoint),
        body: {
          'login': login,
          'password': password,
          'user_type': userType,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final userId = data['data']?['id']?.toString() ?? 'unknown';
          AppLogger.success('تم تسجيل الدخول بنجاح - User ID: $userId');

          return ApiResponse.fromJson(
            data,
            (json) => json as Map<String, dynamic>,
          );
        } else {
          AppLogger.warning('فشل تسجيل الدخول: ${data['message']}');
          return ApiResponse.fromJson(
            data,
            (json) => json as Map<String, dynamic>,
          );
        }
      } else {
        AppLogger.error('HTTP Error في تسجيل الدخول: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في signIn', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      AppLogger.info('محاولة إنشاء حساب جديد كـ: $userType');
      AppLogger.network('POST', ApiConfig.signupEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.signupEndpoint),
        body: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'user_type': userType,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final userId = data['owner_id']?.toString() ??
              data['user_id']?.toString() ??
              'unknown';
          AppLogger.success('تم إنشاء الحساب بنجاح - User ID: $userId');

          return ApiResponse.fromJson(
            data,
            (json) => json as Map<String, dynamic>,
          );
        } else {
          AppLogger.warning('فشل إنشاء الحساب: ${data['message']}');
          return ApiResponse.fromJson(
            data,
            (json) => json as Map<String, dynamic>,
          );
        }
      } else {
        AppLogger.error('HTTP Error في التسجيل: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في signUp', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  /// تسجيل الخروج (مسح الكاش المحلي)
  Future<void> signOut() async {
    try {
      AppLogger.info('تسجيل الخروج');
      // يمكن إضافة منطق إضافي هنا مثل مسح الكاش
      AppLogger.success('تم تسجيل الخروج بنجاح');
    } catch (e, stack) {
      AppLogger.error('خطأ في signOut', e, stack);
    }
  }
}
