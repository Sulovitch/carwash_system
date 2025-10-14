// lib/widgets/booking_sources_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BookingSourcesChart extends StatelessWidget {
  final Map<String, int> bookingSources;

  const BookingSourcesChart({
    Key? key,
    required this.bookingSources,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مصادر الحجوزات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ملخص النسب المئوية
            ...bookingSources.entries.map((entry) {
              final total = bookingSources.values.reduce((a, b) => a + b);
              final percentage = total > 0
                  ? (entry.value / total * 100).toStringAsFixed(1)
                  : '0.0';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getSourceColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_getSourceLabel(entry.key)),
                      ],
                    ),
                    Text('$percentage% (${entry.value} حجز)'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return [
      PieChartSectionData(
        value: bookingSources['app']?.toDouble() ?? 0,
        title: '${bookingSources['app'] ?? 0}',
        color: Colors.blue,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: bookingSources['walk-in']?.toDouble() ?? 0,
        title: '${bookingSources['walk-in'] ?? 0}',
        color: Colors.green,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: bookingSources['phone']?.toDouble() ?? 0,
        title: '${bookingSources['phone'] ?? 0}',
        color: Colors.orange,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'app':
        return Colors.blue;
      case 'walk-in':
        return Colors.green;
      case 'phone':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'app':
        return 'عبر التطبيق';
      case 'walk-in':
        return 'زيارة مباشرة';
      case 'phone':
        return 'عبر الهاتف';
      default:
        return source;
    }
  }
}
