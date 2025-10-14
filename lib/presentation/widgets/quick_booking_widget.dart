// lib/widgets/quick_booking_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuickBookingWidget extends StatefulWidget {
  final String carWashId;
  final Function(String date, String time) onBookingSelected;

  const QuickBookingWidget({
    Key? key,
    required this.carWashId,
    required this.onBookingSelected,
  }) : super(key: key);

  @override
  State<QuickBookingWidget> createState() => _QuickBookingWidgetState();
}

class _QuickBookingWidgetState extends State<QuickBookingWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _quickTimeSlots = [
    '09:00',
    '12:00',
    '15:00',
    '18:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'حجز سريع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // اختيار التاريخ
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? 'اختر التاريخ'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            const SizedBox(height: 12),

            // أوقات سريعة
            if (_selectedDate != null) ...[
              const Text(
                'اختر وقت سريع:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTimeSlots.map((time) {
                  final isSelected = _selectedTime?.format(context) == time;
                  return FilterChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        final parts = time.split(':');
                        setState(() {
                          _selectedTime = TimeOfDay(
                            hour: int.parse(parts[0]),
                            minute: int.parse(parts[1]),
                          );
                        });
                      }
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // زر الحجز
              if (_selectedTime != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmQuickBooking,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('تأكيد الحجز السريع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  void _confirmQuickBooking() {
    if (_selectedDate != null && _selectedTime != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      widget.onBookingSelected(formattedDate, formattedTime);
    }
  }
}
