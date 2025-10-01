import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class ProfileService {
  Future<ApiResponse<bool>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateUserProfileEndpoint),
        body: {
          'userId': userId,
          'name': name,
          'email': email,
          'phone': phone,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم تحديث الملف الشخصي بنجاح');
        } else {
          return ApiResponse.error(
              data['message'] ?? 'فشل في تحديث الملف الشخصي');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse(ApiConfig.updateOwnerProfileEndpoint),
        body: {
          'userId': ownerId,
          'name': name,
          'email': email,
          'phone': phone,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم تحديث الملف الشخصي بنجاح');
        } else {
          return ApiResponse.error(
              data['message'] ?? 'فشل في تحديث الملف الشخصي');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, String>>> getProfile({
    required String userId,
    required bool isOwner,
  }) async {
    try {
      final endpoint = isOwner
          ? '${ApiConfig.baseUrl}/get_owner_profile.php'
          : '${ApiConfig.baseUrl}/get_user_profile.php';

      final response = await http.post(
        Uri.parse(endpoint),
        body: {'userId': userId},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['profile'] != null) {
          final profile = {
            'userId': data['profile']['id']?.toString() ?? userId,
            'name': data['profile']['name']?.toString() ?? '',
            'email': data['profile']['email']?.toString() ?? '',
            'phone': data['profile']['phone']?.toString() ?? '',
          };
          return ApiResponse.success(profile);
        } else {
          return ApiResponse.error(
              data['message'] ?? 'فشل في جلب الملف الشخصي');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
