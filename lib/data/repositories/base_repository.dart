// lib/data/repositories/base_repository.dart
import '../../core/network/api_client.dart';

abstract class BaseRepository {
  final ApiClient apiClient;

  BaseRepository(this.apiClient);

  // Helper methods يمكن استخدامها في كل الـ Repositories

  /// معالجة الأخطاء بشكل موحد
  ApiResponse<T> handleError<T>(dynamic error) {
    if (error is ApiResponse) {
      return error as ApiResponse<T>;
    }
    return ApiResponse.error(error.toString());
  }

  /// تحويل List من JSON
  List<T> parseList<T>(
    dynamic json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json is! List) return [];

    return json
        .map((item) {
          if (item is Map<String, dynamic>) {
            return fromJson(item);
          }
          return null;
        })
        .whereType<T>()
        .toList();
  }

  /// التحقق من وجود قيمة
  bool isNotEmpty(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }
}
