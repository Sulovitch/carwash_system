// lib/screens/owner/capacity_management_screen.dart
class CapacityManagementScreen extends StatefulWidget {
  final String carWashId;
  
  @override
  _CapacityManagementScreenState createState() => _CapacityManagementScreenState();
}

class _CapacityManagementScreenState extends State<CapacityManagementScreen> {
  Map<DateTime, List<TimeSlot>> _timeSlots = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السعة والتوفر'),
      ),
      body: Column(
        children: [
          // تقويم لاختيار اليوم
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _selectedDay,
            onDaySelected: (selectedDay, focusedDay) {
              _loadDaySlots(selectedDay);
            },
          ),
          
          // قائمة الفترات الزمنية لليوم المختار
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots[_selectedDay]?.length ?? 0,
              itemBuilder: (context, index) {
                final slot = _timeSlots[_selectedDay]![index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getSlotColor(slot),
                      child: Text(
                        '${slot.bookedCount}/${slot.capacity}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('الساعة: ${slot.time}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: slot.bookedCount / slot.capacity,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text('App: ${slot.appBookings}'),
                              backgroundColor: Colors.blue[100],
                            ),
                            const SizedBox(width: 4),
                            Chip(
                              label: Text('Walk-in: ${slot.walkInBookings}'),
                              backgroundColor: Colors.green[100],
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('تعديل السعة'),
                          onTap: () => _editCapacity(slot),
                        ),
                        PopupMenuItem(
                          child: const Text('إغلاق الفترة'),
                          onTap: () => _closeSlot(slot),
                        ),
                        PopupMenuItem(
                          child: const Text('عرض الحجوزات'),
                          onTap: () => _viewReservations(slot),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getSlotColor(TimeSlot slot) {
    final percentage = slot.bookedCount / slot.capacity;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.5) return Colors.yellow[700]!;
    return Colors.green;
  }
}