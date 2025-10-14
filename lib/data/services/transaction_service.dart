import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import '../models/api_response.dart';

class TransactionService {
  Future<ApiResponse<List<Map<String, dynamic>>>> fetchTransactions(
    String carWashId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.transactionEndpoint),
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
          return ApiResponse.error(data['message'] ?? 'فشل في جلب المعاملات');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Add this method to update reservation status
  Future<ApiResponse<void>> updateTransactionStatus(
    String reservationId,
    String newStatus,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.transactionEndpoint),
        body: {
          'reservation_id': reservationId,
          'status': newStatus,
        },
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return ApiResponse.success(null);
        } else {
          return ApiResponse.error(
              data['message'] ?? 'فشل في تحديث حالة الحجز');
        }
      } else {
        return ApiResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Map<String, dynamic> calculateStatistics(
    List<Map<String, dynamic>> transactions,
  ) {
    double totalEarnings = 0.0;
    int totalReservations = transactions.length;
    int completedReservations = 0;
    int pendingReservations = 0;
    int canceledReservations = 0;

    for (var transaction in transactions) {
      final status = transaction['status']?.toString().toLowerCase() ?? '';
      final price =
          double.tryParse(transaction['service_price']?.toString() ?? '0') ??
              0.0;

      if (status == 'approved') {
        completedReservations++;
        totalEarnings += price;
      } else if (status == 'pending') {
        pendingReservations++;
      } else if (status == 'cancelled') {
        canceledReservations++;
      }
    }

    return {
      'totalEarnings': totalEarnings,
      'totalReservations': totalReservations,
      'completedReservations': completedReservations,
      'pendingReservations': pendingReservations,
      'canceledReservations': canceledReservations,
    };
  }

  Map<DateTime, double> getEarningsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    Map<DateTime, double> earningsByDate = {};

    for (var transaction in transactions) {
      if (transaction['status']?.toString().toLowerCase() == 'approved') {
        try {
          final date = DateTime.parse(transaction['date']);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          final price = double.tryParse(
                  transaction['service_price']?.toString() ?? '0') ??
              0.0;

          earningsByDate[normalizedDate] =
              (earningsByDate[normalizedDate] ?? 0.0) + price;
        } catch (e) {
          // Skip invalid dates
          continue;
        }
      }
    }

    return earningsByDate;
  }

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
        // Skip invalid dates
        continue;
      }
    }

    return reservationsByDate;
  }

  List<Map<String, dynamic>> filterTransactions({
    required List<Map<String, dynamic>> transactions,
    DateTime? selectedDate,
    String? searchQuery,
  }) {
    return transactions.where((transaction) {
      bool matchesDate = true;
      bool matchesSearch = true;

      // Filter by date
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

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final customerName =
            transaction['user_name']?.toString().toLowerCase() ?? '';
        final serviceName =
            transaction['service_name']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();

        matchesSearch =
            customerName.contains(query) || serviceName.contains(query);
      }

      return matchesDate && matchesSearch;
    }).toList();
  }
}
