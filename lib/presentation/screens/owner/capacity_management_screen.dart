// lib/screens/owner/capacity_management_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/time_slot.dart';
import '../../../data/services/capacity_service.dart';

class CapacityManagementScreen extends StatefulWidget {
  final String carWashId;

  const CapacityManagementScreen({
    Key? key,
    required this.carWashId,
  }) : super(key: key);

  @override
  _CapacityManagementScreenState createState() =>
      _CapacityManagementScreenState();
}

class _CapacityManagementScreenState extends State<CapacityManagementScreen> {
  final CapacityService _capacityService = CapacityService();

  Map<DateTime, List<TimeSlot>> _timeSlots = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDaySlots(_selectedDay);
  }

  Future<void> _loadDaySlots(DateTime day) async {
    setState(() {
      _isLoading = true;
      _selectedDay = day;
    });

    try {
      final slots = await _capacityService.getDaySlots(
        carWashId: widget.carWashId,
        date: day,
      );

      setState(() {
        _timeSlots[day] = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السعة والتوفر'),
        backgroundColor: const Color(0xFF370175),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDaySlots(_selectedDay),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // تقويم لاختيار اليوم
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadDaySlots(selectedDay);
              },
              calendarFormat: CalendarFormat.week,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF370175),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue[300],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // عرض الإحصائيات السريعة
          _buildQuickStats(),

          // قائمة الفترات الزمنية لليوم المختار
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _timeSlots[_selectedDay] == null ||
                        _timeSlots[_selectedDay]!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد فترات لهذا اليوم',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadDaySlots(_selectedDay),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _timeSlots[_selectedDay]!.length,
                          itemBuilder: (context, index) {
                            final slot = _timeSlots[_selectedDay]![index];
                            return _buildSlotCard(slot);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTimeSlot,
        backgroundColor: const Color(0xFF370175),
        icon: const Icon(Icons.add),
        label: const Text('إضافة فترة'),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_timeSlots[_selectedDay] == null || _timeSlots[_selectedDay]!.isEmpty) {
      return const SizedBox.shrink();
    }

    final slots = _timeSlots[_selectedDay]!;
    final totalCapacity =
        slots.fold<int>(0, (sum, slot) => sum + slot.capacity);
    final totalBooked =
        slots.fold<int>(0, (sum, slot) => sum + slot.bookedCount);
    final availableSlots =
        slots.where((s) => s.bookedCount < s.capacity).length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.event_available,
              label: 'فترات متاحة',
              value: availableSlots.toString(),
              color: Colors.green,
            ),
            _buildStatItem(
              icon: Icons.people,
              label: 'إجمالي الحجوزات',
              value: totalBooked.toString(),
              color: Colors.blue,
            ),
            _buildStatItem(
              icon: Icons.assessment,
              label: 'السعة الكلية',
              value: totalCapacity.toString(),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSlotCard(TimeSlot slot) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSlotColor(slot),
          child: Text(
            '${slot.bookedCount}/${slot.capacity}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 4),
            Text(
              'الساعة: ${slot.time}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: slot.capacity > 0 ? slot.bookedCount / slot.capacity : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getSlotColor(slot),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text('App: ${slot.appBookings}'),
                  backgroundColor: Colors.blue[100],
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text('Walk-in: ${slot.walkInBookings}'),
                  backgroundColor: Colors.green[100],
                  visualDensity: VisualDensity.compact,
                ),
                if (slot.phoneBookings > 0)
                  Chip(
                    label: Text('Phone: ${slot.phoneBookings}'),
                    backgroundColor: Colors.orange[100],
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.edit),
                title: Text('تعديل السعة'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                Future.delayed(Duration.zero, () => _editCapacity(slot));
              },
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  slot.isActive ? Icons.block : Icons.check_circle,
                ),
                title: Text(slot.isActive ? 'إغلاق الفترة' : 'تفعيل الفترة'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                Future.delayed(Duration.zero, () => _toggleSlot(slot));
              },
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.visibility),
                title: Text('عرض الحجوزات'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                Future.delayed(Duration.zero, () => _viewReservations(slot));
              },
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('حذف الفترة', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () {
                Future.delayed(Duration.zero, () => _deleteSlot(slot));
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getSlotColor(TimeSlot slot) {
    if (slot.capacity == 0) return Colors.grey;
    final percentage = slot.bookedCount / slot.capacity;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.5) return Colors.yellow[700]!;
    return Colors.green;
  }

  void _addNewTimeSlot() {
    showDialog(
      context: context,
      builder: (context) => _TimeSlotDialog(
        carWashId: widget.carWashId,
        date: _selectedDay,
        onSaved: () => _loadDaySlots(_selectedDay),
      ),
    );
  }

  void _editCapacity(TimeSlot slot) {
    showDialog(
      context: context,
      builder: (context) => _EditCapacityDialog(
        slot: slot,
        onSaved: () => _loadDaySlots(_selectedDay),
      ),
    );
  }

  void _toggleSlot(TimeSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(slot.isActive ? 'إغلاق الفترة' : 'تفعيل الفترة'),
        content: Text(
          slot.isActive
              ? 'هل أنت متأكد من إغلاق هذه الفترة؟'
              : 'هل تريد تفعيل هذه الفترة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _capacityService.toggleSlot(
          slotId: slot.id,
          isActive: !slot.isActive,
        );
        _loadDaySlots(_selectedDay);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(slot.isActive ? 'تم إغلاق الفترة' : 'تم تفعيل الفترة'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _deleteSlot(TimeSlot slot) async {
    if (slot.bookedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف فترة تحتوي على حجوزات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الفترة'),
        content: const Text('هل أنت متأكد من حذف هذه الفترة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _capacityService.deleteSlot(slotId: slot.id);
        _loadDaySlots(_selectedDay);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الفترة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewReservations(TimeSlot slot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlotReservationsScreen(
          slot: slot,
          date: _selectedDay,
        ),
      ),
    );
  }
}

// حوار تعديل السعة
class _EditCapacityDialog extends StatefulWidget {
  final TimeSlot slot;
  final VoidCallback onSaved;

  const _EditCapacityDialog({
    required this.slot,
    required this.onSaved,
  });

  @override
  State<_EditCapacityDialog> createState() => _EditCapacityDialogState();
}

class _EditCapacityDialogState extends State<_EditCapacityDialog> {
  late TextEditingController _capacityController;
  final CapacityService _capacityService = CapacityService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController(
      text: widget.slot.capacity.toString(),
    );
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل السعة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('الوقت: ${widget.slot.time}'),
          const SizedBox(height: 16),
          TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'السعة الجديدة',
              border: const OutlineInputBorder(),
              helperText: 'الحجوزات الحالية: ${widget.slot.bookedCount}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCapacity,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  void _saveCapacity() async {
    final newCapacity = int.tryParse(_capacityController.text);

    if (newCapacity == null || newCapacity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سعة صحيحة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newCapacity < widget.slot.bookedCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'السعة الجديدة ($newCapacity) أقل من عدد الحجوزات الحالية (${widget.slot.bookedCount})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _capacityService.updateCapacity(
        slotId: widget.slot.id,
        newCapacity: newCapacity,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث السعة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// حوار إضافة فترة جديدة
class _TimeSlotDialog extends StatefulWidget {
  final String carWashId;
  final DateTime date;
  final VoidCallback onSaved;

  const _TimeSlotDialog({
    required this.carWashId,
    required this.date,
    required this.onSaved,
  });

  @override
  State<_TimeSlotDialog> createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<_TimeSlotDialog> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _capacityController =
      TextEditingController(text: '5');
  final CapacityService _capacityService = CapacityService();
  bool _isLoading = false;

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة فترة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(_selectedTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: _selectTime,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'السعة',
              border: OutlineInputBorder(),
              helperText: 'عدد الحجوزات المسموح بها',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveSlot,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إضافة'),
        ),
      ],
    );
  }

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveSlot() async {
    final capacity = int.tryParse(_capacityController.text);

    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سعة صحيحة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _capacityService.addTimeSlot(
        carWashId: widget.carWashId,
        date: widget.date,
        time: _selectedTime,
        capacity: capacity,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الفترة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// شاشة عرض حجوزات الفترة
class SlotReservationsScreen extends StatelessWidget {
  final TimeSlot slot;
  final DateTime date;

  const SlotReservationsScreen({
    Key? key,
    required this.slot,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حجوزات ${slot.time}'),
        backgroundColor: const Color(0xFF370175),
      ),
      body: Center(
        child: Text('عرض الحجوزات لـ ${slot.time}'),
      ),
    );
  }
}
