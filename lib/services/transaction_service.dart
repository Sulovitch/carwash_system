import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/cache_manager.dart';
import '../utils/logger.dart';
import '../utils/network_helper.dart';

class TransactionService {
  final _cache = CacheManager();
  final _network = NetworkHelper();

  String _getTransactionsCacheKey(String carWashId) =>
      'transactions_$carWashId';

  Future<ApiResponse<List<Map<String, dynamic>>>> fetchTransactions(
    String carWashId,
  ) async {
    try {
      // تحقق من الكاش أولاً
      final cacheKey = _getTransactionsCacheKey(carWashId);
      final cached = _cache.getData(cacheKey);

      if (cached != null) {
        AppLogger.info('استخدام المعاملات من الكاش', 'Transactions');
        return ApiResponse.success(cached as List<Map<String, dynamic>>);
      }

      AppLogger.network('POST', ApiConfig.transactionEndpoint);

      final response = await _network.post(
        Uri.parse(ApiConfig.transactionEndpoint),
        body: {'car_wash_id': carWashId},
        timeout: ApiConfig.connectionTimeout,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final reservations = (data['reservations'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          // حفظ في الكاش لمدة 3 دقائق
          _cache.cacheData(
            cacheKey,
            reservations,
            duration: const Duration(minutes: 3),
          );

          AppLogger.success('تم جلب ${reservations.length} معاملة');
          return ApiResponse.success(reservations);
        } else {
          return ApiResponse.error(data['message'] ?? 'فشل في جلب المعاملات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e, stack) {
      AppLogger.error('خطأ في fetchTransactions', e, stack);
      return ApiResponse.error(e.toString());
    }
  }

  /// حساب الإحصائيات من المعاملات
  Map<String, dynamic> calculateStatistics(
    List<Map<String, dynamic>> transactions,
  ) {
    double totalEarnings = 0.0;
    int totalReservations = transactions.length;
    int completedReservations = 0;
    int pendingReservations = 0;
    int canceledReservations = 0;

    for (var transaction in transactions) {
      final status = transaction['status']?.toString() ?? '';
      final price =
          double.tryParse(transaction['service_price']?.toString() ?? '0') ??
              0.0;

      if (status == 'Completed') {
        completedReservations++;
        totalEarnings += price;
      } else if (status == 'Pending') {
        pendingReservations++;
      } else if (status == 'Canceled') {
        canceledReservations++;
      }
    }

    AppLogger.info(
      'إحصائيات: $totalReservations حجز، $completedReservations مكتمل، ${totalEarnings.toStringAsFixed(2)} ريال',
      'Statistics',
    );

    return {
      'totalEarnings': totalEarnings,
      'totalReservations': totalReservations,
      'completedReservations': completedReservations,
      'pendingReservations': pendingReservations,
      'canceledReservations': canceledReservations,
    };
  }

  /// حساب الأرباح حسب التاريخ
  Map<DateTime, double> getEarningsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<DateTime, double> earningsByDate = {};

    for (var transaction in transactions) {
      if (transaction['status'] == 'Completed') {
        try {
          final date = DateTime.parse(transaction['date']);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final price = double.tryParse(
                  transaction['service_price']?.toString() ?? '0') ??
              0.0;

          earningsByDate[normalizedDate] =
              (earningsByDate[normalizedDate] ?? 0.0) + price;
        } catch (e) {
          AppLogger.warning(
              'تاريخ غير صالح في المعاملات: ${transaction['date']}');
          continue;
        }
      }
    }

    return earningsByDate;
  }

  /// حساب الحجوزات حسب التاريخ
  Map<DateTime, int> getReservationsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<DateTime, int> reservationsByDate = {};

    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['date']);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        reservationsByDate[normalizedDate] =
            (reservationsByDate[normalizedDate] ?? 0) + 1;
      } catch (e) {
        AppLogger.warning('تاريخ غير صالح: ${transaction['date']}');
        continue;
      }
    }

    return reservationsByDate;
  }

  /// تصفية المعاملات
  List<Map<String, dynamic>> filterTransactions({
    required List<Map<String, dynamic>> transactions,
    DateTime? selectedDate,
    String? searchQuery,
    String? statusFilter,
  }) {
    return transactions.where((transaction) {
      bool matchesDate = true;
      bool matchesSearch = true;
      bool matchesStatus = true;

      // تصفية حسب التاريخ
      if (selectedDate != null) {
        try {
          final transactionDate = DateTime.parse(transaction['date']);
          matchesDate = transactionDate.year == selectedDate.year &&
              transactionDate.month == selectedDate.month &&
              transactionDate.day == selectedDate.day;
        } catch (e) {
          matchesDate = false;
        }
      }

      // تصفية حسب البحث
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final customerName =
            transaction['user_name']?.toString().toLowerCase() ?? '';
        final serviceName =
            transaction['service_name']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();

        matchesSearch =
            customerName.contains(query) || serviceName.contains(query);
      }

      // تصفية حسب الحالة
      if (statusFilter != null && statusFilter.isNotEmpty) {
        matchesStatus = transaction['status']?.toString() == statusFilter;
      }

      return matchesDate && matchesSearch && matchesStatus;
    }).toList();
  }

  /// مسح كاش المعاملات
  void clearTransactionsCache(String carWashId) {
    _cache.clearDataCache(_getTransactionsCacheKey(carWashId));
    AppLogger.info('تم مسح كاش المعاملات للمغسلة: $carWashId');
  }
}
