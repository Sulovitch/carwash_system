import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class CarWashService {
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

      final response =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        if (data['success'] == true) {
          return ApiResponse.success(
            data,
            'تم حفظ معلومات المغسلة بنجاح',
          );
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حفظ المعلومات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchCarWashes() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.fetchCarWashesEndpoint),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final carWashes = (data['carWashes'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          return ApiResponse.success(carWashes);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب المغاسل');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
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

      final response =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        if (data['success'] == true) {
          return ApiResponse.success(
            data,
            'تم تحديث معلومات المغسلة بنجاح',
          );
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في التحديث');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
