import 'dart:convert';
import 'package:app/data/models/time_slot.dart';
import 'package:http/http.dart' as http;
import '../models/dashboard_data.dart';

class DashboardService {
  static const String baseUrl = 'YOUR_API_BASE_URL'; // استبدل بـ URL الخاص بك

  Future<DashboardData> getDashboardData({
    required String carWashId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_dashboard_data.php'),
        body: {
          'car_wash_id': carWashId,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return DashboardData.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'فشل جلب البيانات');
        }
      } else {
        throw Exception('خطأ في الاتصال بالخادم');
      }
    } catch (e) {
      throw Exception('خطأ في جلب بيانات لوحة التحكم: $e');
    }
  }

  // دالة مساعدة لإنشاء بيانات تجريبية
  Future<DashboardData> getMockDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));

    return DashboardData(
      todayBookings: 15,
      activeBookings: 3,
      completedBookings: 10,
      todayRevenue: 2500.0,
      availableSpots: 8,
      totalCapacity: 20,
      bookingSources: {
        'app': 10,
        'walk-in': 3,
        'phone': 2,
      },
      recentBookings: [
        RecentBooking(
          id: '1',
          customerName: 'أحمد محمد',
          serviceName: 'غسيل خارجي',
          time: '14:30',
          status: 'in_progress',
          source: 'التطبيق',
        ),
        RecentBooking(
          id: '2',
          customerName: 'فاطمة علي',
          serviceName: 'غسيل شامل',
          time: '15:00',
          status: 'pending',
          source: 'Walk-in',
        ),
      ],
      criticalSlots: [
        TimeSlot(
          id: '1',
          time: '16:00',
          capacity: 5,
          bookedCount: 5,
          appBookings: 4,
          walkInBookings: 1,
        ),
        TimeSlot(
          id: '2',
          time: '17:00',
          capacity: 5,
          bookedCount: 4,
          appBookings: 3,
          walkInBookings: 1,
        ),
      ],
    );
  }
}
