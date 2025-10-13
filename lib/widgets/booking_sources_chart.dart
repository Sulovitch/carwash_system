// lib/widgets/booking_sources_chart.dart
class BookingSourcesChart extends StatelessWidget {
  final Map<String, int> bookingSources;
  
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
                  sections: [
                    PieChartSectionData(
                      value: bookingSources['app']!.toDouble(),
                      title: 'التطبيق\n${bookingSources['app']}',
                      color: Colors.blue,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: bookingSources['walk-in']!.toDouble(),
                      title: 'Walk-in\n${bookingSources['walk-in']}',
                      color: Colors.green,
                      radius: 100,
                    ),
                    PieChartSectionData(
                      value: bookingSources['phone']!.toDouble(),
                      title: 'الهاتف\n${bookingSources['phone']}',
                      color: Colors.orange,
                      radius: 100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ملخص النسب المئوية
            ...bookingSources.entries.map((entry) {
              final total = bookingSources.values.reduce((a, b) => a + b);
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getSourceLabel(entry.key)),
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
  
  String _getSourceLabel(String source) {
    switch (source) {
      case 'app': return 'عبر التطبيق';
      case 'walk-in': return 'زيارة مباشرة';
      case 'phone': return 'عبر الهاتف';
      default: return source;
    }
  }
}