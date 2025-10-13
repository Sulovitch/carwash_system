// lib/screens/waiting_list_dialog.dart
import 'package:flutter/material.dart';

class WaitingListDialog extends StatelessWidget {
  final String carWashId;
  final String date;
  final String time;
  final String userId;
  final String carId;
  final String serviceId;

  const WaitingListDialog({
    Key? key,
    required this.carWashId,
    required this.date,
    required this.time,
    required this.userId,
    required this.carId,
    required this.serviceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.access_time_filled, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('الفترة ممتلئة'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('هذه الفترة ممتلئة حالياً'),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هل تريد الانضمام لقائمة الانتظار؟\nسنخبرك فور توفر مكان',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('لا، شكراً'),
        ),
        ElevatedButton.icon(
          onPressed: () => _joinWaitingList(context),
          icon: const Icon(Icons.add_alert),
          label: const Text('انضم لقائمة الانتظار'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  void _joinWaitingList(BuildContext context) async {
    try {
      // إضافة لقائمة الانتظار
      final response = await WaitingListService().addToWaitingList(
        carWashId: carWashId,
        date: date,
        time: time,
        userId: userId,
        carId: carId,
        serviceId: serviceId,
      );

      if (response.success) {
        if (!context.mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافتك لقائمة الانتظار، سنخبرك عند توفر مكان'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!context.mounted) return;
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'فشل الانضمام لقائمة الانتظار'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context, false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // دالة ثابتة لعرض الحوار
  static Future<bool?> show(
    BuildContext context, {
    required String carWashId,
    required String date,
    required String time,
    required String userId,
    required String carId,
    required String serviceId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => WaitingListDialog(
        carWashId: carWashId,
        date: date,
        time: time,
        userId: userId,
        carId: carId,
        serviceId: serviceId,
      ),
    );
  }
}

// خدمة قائمة الانتظار
class WaitingListService {
  Future<WaitingListResponse> addToWaitingList({
    required String carWashId,
    required String date,
    required String time,
    required String userId,
    required String carId,
    required String serviceId,
  }) async {
    try {
      // TODO: استبدل هذا بـ API call حقيقي
      await Future.delayed(const Duration(seconds: 1));

      // محاكاة استجابة ناجحة
      return WaitingListResponse(
        success: true,
        message: 'تمت الإضافة بنجاح',
      );

      /* 
      // الكود الحقيقي للـ API:
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/add_to_waiting_list.php'),
        body: {
          'car_wash_id': carWashId,
          'date': date,
          'time': time,
          'user_id': userId,
          'car_id': carId,
          'service_id': serviceId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WaitingListResponse.fromJson(data);
      }
      */
    } catch (e) {
      return WaitingListResponse(
        success: false,
        message: 'حدث خطأ: ${e.toString()}',
      );
    }
  }

  Future<bool> removeFromWaitingList({
    required String waitingListId,
  }) async {
    try {
      // TODO: استبدل هذا بـ API call حقيقي
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      return false;
    }
  }
}

class WaitingListResponse {
  final bool success;
  final String? message;
  final int? waitingListId;

  WaitingListResponse({
    required this.success,
    this.message,
    this.waitingListId,
  });

  factory WaitingListResponse.fromJson(Map<String, dynamic> json) {
    return WaitingListResponse(
      success: json['success'] == true || json['success'] == 1,
      message: json['message'] as String?,
      waitingListId: json['waiting_list_id'] != null
          ? int.tryParse(json['waiting_list_id'].toString())
          : null,
    );
  }
}
