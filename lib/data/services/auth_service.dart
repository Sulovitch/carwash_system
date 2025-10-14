import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class AuthService {
  Future<ApiResponse<Map<String, dynamic>>> signIn({
    required String login,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authEndpoint),
        body: {
          'login': login,
          'password': password,
          'user_type': userType,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.fromJson(
            data, (json) => json as Map<String, dynamic>);
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse(ApiConfig.signupEndpoint),
        body: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'user_type': userType,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.fromJson(
            data, (json) => json as Map<String, dynamic>);
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
