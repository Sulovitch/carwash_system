import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/Car.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class CarService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  String _getUserCarsCacheKey(String userId) => 'user_cars_$userId';

  Future<ApiResponse<int>> addCar({
    required String userId,
    required String make,
    required String model,
    required String year,
    required String plateNumbers,
    required String plateLetters,
  }) async {
    try {
      AppLogger.network('POST', '${ApiConfig.carEndpoint}?action=add');

      final response = await _network.post(
        Uri.parse(ApiConfig.carEndpoint),
        body: {
          'action': 'add',
          'user_id': userId,
          'car_make': make,
          'car_model': model,
          'car_year': year,
          'plateNumbers': plateNumbers,
          'plateLetters': plateLetters,
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كاش سيارات المستخدم
          _cache.clearDataCache(_getUserCarsCacheKey(userId));

          final carId = data['car_id'] as int;
          AppLogger.success('تم إضافة السيارة: $carId');

          return ApiResponse.success(
            carId,
            'تم إضافة السيارة بنجاح',
          );
        } else {
          AppLogger.warning('فشل إضافة السيارة: ${data['message']}');
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة السيارة');
        }
      } else {
        AppLogger.error('HTTP Error: ${response.statusCode}');
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في addCar', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Car>>> fetchUserCars(String userId) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = _getUserCarsCacheKey(userId);
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام سيارات المستخدم من الكاش', 'Cars');
        return ApiResponse.success(cached as List<Car>);
      }

      AppLogger.network('POST', ApiConfig.getCarsEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.getCarsEndpoint),
        body: {'user_id': userId},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['cars'] is List) {
          final cars = (data['cars'] as List).map((carData) {
            return Car(
              carId: carData['Car_id'],
              selectedMake: carData['Car_make']?.toString(),
              selectedModel: carData['Car_model']?.toString(),
              selectedYear: carData['Car_year']?.toString(),
              selectedArabicNumbers:
                  _splitPlateNumbers(carData['plateNumbers'], 0, 4),
              selectedLatinNumbers:
                  _splitPlateNumbers(carData['plateNumbers'], 4, 8),
              selectedArabicLetters:
                  _splitPlateLetters(carData['plateLetters'], 0, 3),
              selectedLatinLetters:
                  _splitPlateLetters(carData['plateLetters'], 3, 6),
            );
          }).toList();

          // حفظ في الكاش لمدة 15 دقيقة
          _cache.cacheData(
            cacheKey,
            cars,
            duration: const Duration(minutes: 15),
          );

          AppLogger.success('تم جلب ${cars.length} سيارة');
          return ApiResponse.success(cars);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب السيارات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchUserCars', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> deleteCar(int carId) async {
    try {
      AppLogger.network('POST', '${ApiConfig.carEndpoint}?action=delete');

      final response = await _network.post(
        Uri.parse(ApiConfig.carEndpoint),
        body: {
          'action': 'delete',
          'Car_id': carId.toString(),
        },
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // مسح كل كاش السيارات
          _cache.clearCache();

          AppLogger.success('تم حذف السيارة: $carId');
          return ApiResponse.success(true, 'تم حذف السيارة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف السيارة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في deleteCar', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  // دوال مساعدة لتقسيم أرقام وحروف اللوحة
  List<String> _splitPlateNumbers(String? plateNumbers, int start, int end) {
    if (plateNumbers == null || plateNumbers.length < end) {
      return List.filled(end - start, '');
    }
    return plateNumbers.substring(start, end).split('');
  }

  List<String> _splitPlateLetters(String? plateLetters, int start, int end) {
    if (plateLetters == null || plateLetters.length < end) {
      return List.filled(end - start, '');
    }
    return plateLetters.substring(start, end).split('');
  }
}
