import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/Service.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class ServiceService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  String _getCacheKey(String carWashId) => 'services_$carWashId';

  Future<ApiResponse<List<Service>>> fetchServices(String carWashId) async {
    try {
      // تحقق من الكاش
      final cacheKey = _getCacheKey(carWashId);
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام الخدمات من الكاش', 'Services');
        return ApiResponse.success(cached as List<Service>);
      }

      AppLogger.network('POST', ApiConfig.serviceEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.serviceEndpoint),
        body: {
          'action': 'get_services',
          'car_wash_id': carWashId,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final services = (data['data'] as List<dynamic>)
              .map((item) => Service.fromJson(item))
              .toList();

          // حفظ في الكاش لمدة 10 دقائق
          _cache.cacheData(
            cacheKey,
            services,
            duration: const Duration(minutes: 10),
          );

          AppLogger.success('تم جلب ${services.length} خدمة');
          return ApiResponse.success(services);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب الخدمات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchServices', e, stack);
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
      AppLogger.network('POST', '${ApiConfig.serviceEndpoint}?action=add');

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

      final response = await request.send().timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
          );

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

          // مسح الكاش
          _cache.clearDataCache(_getCacheKey(carWashId));

          AppLogger.success('تم إضافة الخدمة');
          return ApiResponse.success(service, 'تم إضافة الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في addService', e, stack);
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
      AppLogger.network('POST', '${ApiConfig.serviceEndpoint}?action=edit');

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

      final response = await request.send().timeout(
            ApiConfig.connectionTimeout,
            onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
          );

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

          // مسح كل كاش الخدمات
          _cache.clearCache();

          AppLogger.success('تم تحديث الخدمة');
          return ApiResponse.success(service, 'تم تحديث الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في updateService', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> deleteService(int serviceId) async {
    try {
      AppLogger.network('POST', '${ApiConfig.serviceEndpoint}?action=delete');

      final response = await _network.post(
        Uri.parse(ApiConfig.serviceEndpoint),
        body: {
          'action': 'delete',
          'ServiceID': serviceId.toString(),
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح الكاش
          _cache.clearCache();

          AppLogger.success('تم حذف الخدمة');
          return ApiResponse.success(true, 'تم حذف الخدمة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف الخدمة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في deleteService', e, stack);
      return ApiResponse.error(e.toString());
    }
  }
}
