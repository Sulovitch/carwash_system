import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/api_response.dart';
import '../models/Car.dart';

class CarService {
  Future<ApiResponse<int>> addCar({
    required String userId,
    required String make,
    required String model,
    required String year,
    required String plateNumbers,
    required String plateLetters,
  }) async {
    try {
      final response = await http.post(
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
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(
            data['car_id'] as int,
            'تم إضافة السيارة بنجاح',
          );
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في إضافة السيارة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<Car>>> fetchUserCars(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getCarsEndpoint),
        body: {'user_id': userId},
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['cars'] is List) {
          final cars = (data['cars'] as List).map((carData) {
            String plateNumbers = carData['plateNumbers']?.toString() ?? '';
            String plateLetters = carData['plateLetters']?.toString() ?? '';

            // تحويل إلى List<String> (بدون null)
            List<String> arabicNums = [];
            List<String> latinNums = [];
            List<String> arabicLetters = [];
            List<String> latinLetters = [];

            if (plateNumbers.length >= 8) {
              arabicNums = plateNumbers.substring(0, 4).split('');
              latinNums = plateNumbers.substring(4, 8).split('');
            } else {
              // استخدام قيم فارغة بدلاً من null
              arabicNums = ['', '', '', ''];
              latinNums = ['', '', '', ''];
            }

            if (plateLetters.length >= 6) {
              arabicLetters = plateLetters.substring(0, 3).split('');
              latinLetters = plateLetters.substring(3, 6).split('');
            } else {
              arabicLetters = ['', '', ''];
              latinLetters = ['', '', ''];
            }

            return Car(
              carId: carData['Car_id'],
              selectedMake: carData['Car_make']?.toString(),
              selectedModel: carData['Car_model']?.toString(),
              selectedYear: carData['Car_year']?.toString(),
              selectedArabicNumbers: arabicNums,
              selectedLatinNumbers: latinNums,
              selectedArabicLetters: arabicLetters,
              selectedLatinLetters: latinLetters,
            );
          }).toList();

          return ApiResponse.success(cars);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب السيارات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('خطأ: ${e.toString()}');
    }
  }

  Future<ApiResponse<bool>> deleteCar(int carId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.carEndpoint),
        body: {
          'action': 'delete',
          'Car_id': carId.toString(),
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(true, 'تم حذف السيارة بنجاح');
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في حذف السيارة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> updateCar({
    required int carId,
    required String make,
    required String model,
    required String year,
    required String plateNumbers,
    required String plateLetters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.carEndpoint),
        body: {
          'action': 'update',
          'Car_id': carId.toString(),
          'car_make': make,
          'car_model': model,
          'car_year': year,
          'plateNumbers': plateNumbers,
          'plateLetters': plateLetters,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApiResponse.success(
            true,
            'تم تحديث السيارة بنجاح',
          );
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في تحديث السيارة');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
