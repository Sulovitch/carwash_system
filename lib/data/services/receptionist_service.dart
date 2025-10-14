import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/api_response.dart';

class ReceptionistService {
  Future<ApiResponse<bool>> addReceptionist({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String carWashId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.receptionistEndpoint),
        body: {
          'action': 'add',
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'car_wash_id': carWashId,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم إضافة الموظف بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة الموظف');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, String>>>> fetchReceptionists(
    String carWashId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '${ApiConfig.fetchReceptionistsEndpoint}?car_wash_id=$carWashId'),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final receptionists = (data['receptionists'] as List<dynamic>)
              .map<Map<String, String>>((receptionist) =>
                  (receptionist as Map<String, dynamic>).map<String, String>(
                    (key, value) => MapEntry(key.toString(), value.toString()),
                  ))
              .toList();
          return ApiResponse.success(receptionists);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الموظفين');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
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

      final response = await http
          .post(
            Uri.parse(ApiConfig.receptionistEndpoint),
            body: body,
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم تحديث معلومات الموظف بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الموظف');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> deleteReceptionist(String receptionistId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.receptionistEndpoint),
        body: {
          'action': 'delete',
          'receptionist_id': receptionistId,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم حذف الموظف بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف الموظف');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchReservationsForCarWash(
    String carWashId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.fetchReservationsEndpoint),
        body: {'car_wash_id': carWashId},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final reservations = (data['reservations'] as List<dynamic>)
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
}
