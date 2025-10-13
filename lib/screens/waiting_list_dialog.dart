// lib/screens/waiting_list_dialog.dart
class WaitingListDialog extends StatelessWidget {
  final String carWashId;
  final String date;
  final String time;
  
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
          onPressed: () => Navigator.pop(context),
          child: const Text('لا، شكراً'),
        ),
        ElevatedButton.icon(
          onPressed: () => _joinWaitingList(context),
          icon: const Icon(Icons.add_alert),
          label: const Text('انضم لقائمة الانتظار'),
        ),
      ],
    );
  }
  
  void _joinWaitingList(BuildContext context) async {
    // إضافة لقائمة الانتظار
    final response = await WaitingListService().addToWaitingList(
      carWashId: carWashId,
      date: date,
      time: time,
      // ... بقية البيانات
    );
    
    if (response.success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافتك لقائمة الانتظار، سنخبرك عند توفر مكان'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}