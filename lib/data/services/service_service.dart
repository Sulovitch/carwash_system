import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/Service.dart';

class ServiceService {
  Future<ApiResponse<List<Service>>> fetchServices(String carWashId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.serviceEndpoint),
        body: {
          'action': 'get_services',
          'car_wash_id': carWashId,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final services = (data['data'] as List<dynamic>)
              .map((item) => Service.fromJson(item))
              .toList();
          return ApiResponse.success(services);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الخدمات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Service>> addService({
    required String carWashId,
    required String name,
    required String description,
    required double price,
    required String imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.serviceEndpoint),
      )
        ..fields['action'] = 'add'
        ..fields['name'] = name
        ..fields['description'] = description
        ..fields['price'] = price.toString()
        ..fields['car_wash_id'] = carWashId;

      if (imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('service_image', imagePath),
        );
      }

      final response =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data['success'] == true) {
          final service = Service(
            id: int.tryParse(data['ServiceID']?.toString() ?? '0'),
            name: name,
            description: description,
            price: price,
            imageUrl: data['image_url'],
          );
          return ApiResponse.success(service, 'تم إضافة الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Service>> updateService({
    required int serviceId,
    required String name,
    required String description,
    required double price,
    String? imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.serviceEndpoint),
      )
        ..fields['action'] = 'edit'
        ..fields['ServiceID'] = serviceId.toString()
        ..fields['name'] = name
        ..fields['description'] = description
        ..fields['price'] = price.toString();

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('service_image', imagePath),
        );
      }

      final response =
          await request.send().timeout(ApiConfig.connectionTimeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);

        if (data['success'] == true) {
          final service = Service(
            id: serviceId,
            name: name,
            description: description,
            price: price,
            imageUrl: data['image_url'],
          );
          return ApiResponse.success(service, 'تم تحديث الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> deleteService(int serviceId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.serviceEndpoint),
        body: {
          'action': 'delete',
          'ServiceID': serviceId.toString(),
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم حذف الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
