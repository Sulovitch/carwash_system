// lib/core/network/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiClient {
  final http.Client _client = http.Client();
  String? _authToken;

  // Singleton Pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);

      final response = await _client
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on http.ClientException {
      return ApiResponse.error('فشل الاتصال بالخادم');
    } on TimeoutException {
      return ApiResponse.error('انتهت مهلة الاتصال');
    } catch (e) {
      return ApiResponse.error('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);

      final response = await _client
          .post(
            uri,
            headers: _getHeaders(),
            body: json.encode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } on http.ClientException {
      return ApiResponse.error('فشل الاتصال بالخادم');
    } on TimeoutException {
      return ApiResponse.error('انتهت مهلة الاتصال');
    } catch (e) {
      return ApiResponse.error('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  // للتعامل مع الـ PHP APIs التي تستخدم form-data
  Future<ApiResponse<T>> postFormData<T>(
    String endpoint, {
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // إضافة الـ headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // إضافة الحقول
      request.fields.addAll(fields);

      // إضافة الملفات
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت');
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await _client
          .put(
            uri,
            headers: _getHeaders(),
            body: json.encode(body),
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await _client
          .delete(uri, headers: _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('حدث خطأ: ${e.toString()}');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      try {
        final jsonData = json.decode(response.body);

        // Handle PHP format: {success: true, message: "", data: {}}
        if (jsonData is Map<String, dynamic>) {
          final success =
              jsonData['success'] == true || jsonData['success'] == 1;
          final message = jsonData['message'] as String?;

          if (!success) {
            return ApiResponse<T>(
              success: false,
              message: message ?? 'فشلت العملية',
              data: null,
            );
          }

          final data = jsonData['data'];

          if (data != null && fromJson != null) {
            return ApiResponse<T>(
              success: true,
              message: message,
              data: fromJson(data),
            );
          }

          return ApiResponse<T>(
            success: true,
            message: message,
            data: data as T?,
          );
        }

        return ApiResponse.error('صيغة الاستجابة غير صحيحة');
      } catch (e) {
        return ApiResponse.error('خطأ في معالجة البيانات: ${e.toString()}');
      }
    } else if (statusCode == 401) {
      // Handle unauthorized - clear token and redirect to login
      clearAuthToken();
      return ApiResponse.error('انتهت الجلسة، يرجى تسجيل الدخول مجدداً');
    } else if (statusCode == 404) {
      return ApiResponse.error('الصفحة المطلوبة غير موجودة');
    } else if (statusCode >= 500) {
      return ApiResponse.error('خطأ في الخادم، يرجى المحاولة لاحقاً');
    } else {
      return ApiResponse.error('حدث خطأ (${statusCode})');
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.error(String message) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
    );
  }

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'انتهت مهلة الاتصال']);

  @override
  String toString() => message;
}
