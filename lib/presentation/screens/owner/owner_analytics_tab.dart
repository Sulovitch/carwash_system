import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/transaction_service.dart';
import '../../../core/utils/error_handler.dart';

class OwnerAnalyticsTab extends StatefulWidget {
  final String carWashId;

  const OwnerAnalyticsTab({
    Key? key,
    required this.carWashId,
  }) : super(key: key);

  @override
  State<OwnerAnalyticsTab> createState() => _OwnerAnalyticsTabState();
}

class _OwnerAnalyticsTabState extends State<OwnerAnalyticsTab> {
  final _transactionService = TransactionService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _statistics = {};
  String _selectedPeriod = 'week';
  Map<DateTime, double> _earningsByDate = {};
  Map<DateTime, int> _reservationsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await _transactionService.fetchTransactions(widget.carWashId);

      if (response.success && response.data != null) {
        setState(() {
          _transactions = response.data!;
          _statistics = _transactionService.calculateStatistics(_transactions);
          _earningsByDate =
              _transactionService.getEarningsByDate(_transactions);
          _reservationsByDate =
              _transactionService.getReservationsByDate(_transactions);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: AppSpacing.large),
            _buildMainStatistics(),
            const SizedBox(height: AppSpacing.large),
            _buildEarningsChart(),
            const SizedBox(height: AppSpacing.large),
            _buildReservationsChart(),
            const SizedBox(height: AppSpacing.large),
            _buildStatusDistribution(),
            const SizedBox(height: AppSpacing.large),
            _buildTopServices(),
            const SizedBox(height: AppSpacing.large),
            _buildDailyPerformance(),
            const SizedBox(height: AppSpacing.large),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('أسبوع', 'week'),
          _buildPeriodButton('شهر', 'month'),
          _buildPeriodButton('سنة', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatistics() {
    final totalEarnings = _statistics['totalEarnings'] ?? 0.0;
    final totalReservations = _statistics['totalReservations'] ?? 0;
    final completedReservations = _statistics['completedReservations'] ?? 0;
    final averageRevenue =
        totalReservations > 0 ? totalEarnings / totalReservations : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الأداء المالي',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                'إجمالي الأرباح',
                '${totalEarnings.toStringAsFixed(2)} ر.س',
                Icons.trending_up,
                Colors.green,
                '+12.5%',
                true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                'متوسط الإيراد',
                '${averageRevenue.toStringAsFixed(2)} ر.س',
                Icons.attach_money,
                Colors.blue,
                '+5.2%',
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatisticCard(
                'معدل الإنجاز',
                '${totalReservations > 0 ? (completedReservations / totalReservations * 100).toStringAsFixed(1) : 0}%',
                Icons.check_circle,
                Colors.purple,
                '+3.1%',
                true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticCard(
                'الحجوزات النشطة',
                '${_statistics['pendingReservations'] ?? 0}',
                Icons.pending_actions,
                Colors.orange,
                '',
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool showTrend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (showTrend && trend.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 12,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart() {
    if (_earningsByDate.isEmpty) {
      return _buildEmptyChart('لا توجد بيانات للأرباح');
    }

    final sortedDates = _earningsByDate.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      final earnings = _earningsByDate[sortedDates[i]] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), earnings));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تطور الأرباح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.show_chart, color: Colors.green.shade600),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length)
                          return const Text('');
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsChart() {
    if (_reservationsByDate.isEmpty) {
      return _buildEmptyChart('لا توجد بيانات للحجوزات');
    }

    final sortedDates = _reservationsByDate.keys.toList()..sort();
    final bars = <BarChartGroupData>[];

    for (int i = 0; i < sortedDates.length && i < 7; i++) {
      final count = _reservationsByDate[sortedDates[i]] ?? 0;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'توزيع الحجوزات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.bar_chart, color: Colors.blue.shade600),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (bars
                        .map((e) => e.barRods[0].toY)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length)
                          return const Text('');
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('EEE').format(date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final completed = _statistics['completedReservations'] ?? 0;
    final pending = _statistics['pendingReservations'] ?? 0;
    final canceled = _statistics['canceledReservations'] ?? 0;
    final total = completed + pending + canceled;

    if (total == 0) {
      return _buildEmptyChart('لا توجد حجوزات');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع الحجوزات حسب الحالة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          title: '$completed',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: pending.toDouble(),
                          title: '$pending',
                          color: Colors.orange,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: canceled.toDouble(),
                          title: '$canceled',
                          color: Colors.red,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('مكتمل', Colors.green, completed, total),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'قيد الانتظار', Colors.orange, pending, total),
                    const SizedBox(height: 12),
                    _buildLegendItem('ملغي', Colors.red, canceled, total),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count, int total) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopServices() {
    final Map<String, int> serviceCount = {};
    for (var transaction in _transactions) {
      final serviceName = transaction['service_name']?.toString() ?? 'غير محدد';
      serviceCount[serviceName] = (serviceCount[serviceName] ?? 0) + 1;
    }

    final sortedServices = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أكثر الخدمات طلباً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.star, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),
          if (sortedServices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا توجد بيانات'),
              ),
            )
          else
            ...sortedServices.take(5).map((entry) {
              final index = sortedServices.indexOf(entry);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.amber.shade100
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0
                                ? Colors.amber.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value} حجز',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDailyPerformance() {
    final totalReservations = _statistics['totalReservations'] ?? 0;
    final completedReservations = _statistics['completedReservations'] ?? 0;
    final totalEarnings = _statistics['totalEarnings'] ?? 0.0;

    final daysCount =
        _reservationsByDate.length > 0 ? _reservationsByDate.length : 1;
    final avgDailyReservations =
        (totalReservations / daysCount).toStringAsFixed(1);
    final avgDailyEarnings = (totalEarnings / daysCount).toStringAsFixed(2);
    final completionRate = totalReservations > 0
        ? (completedReservations / totalReservations * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'متوسط الأداء اليومي',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceItem(
                  'متوسط الحجوزات',
                  avgDailyReservations,
                  'حجز/يوم',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _buildPerformanceItem(
                  'متوسط الإيرادات',
                  avgDailyEarnings,
                  'ر.س/يوم',
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _buildPerformanceItem(
                  'معدل الإنجاز',
                  completionRate,
                  '%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
              const SizedBox(width: 12),
              const Text(
                'توصيات لتحسين الأداء',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendations.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade700, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'أداؤك ممتاز! استمر في العمل الجيد 👏',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...recommendations.map((rec) => _buildRecommendationItem(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (recommendation['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (recommendation['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (recommendation['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              recommendation['icon'] as IconData,
              color: recommendation['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: recommendation['color'] as Color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation['description'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    final completedReservations = _statistics['completedReservations'] ?? 0;
    final totalReservations = _statistics['totalReservations'] ?? 0;
    final canceledReservations = _statistics['canceledReservations'] ?? 0;
    final pendingReservations = _statistics['pendingReservations'] ?? 0;

    if (totalReservations > 0 &&
        (canceledReservations / totalReservations) > 0.15) {
      recommendations.add({
        'icon': Icons.warning_amber_rounded,
        'title':
            'معدل الإلغاء مرتفع (${(canceledReservations / totalReservations * 100).toStringAsFixed(1)}%)',
        'description':
            'معدل الإلغاء يتجاوز 15%. راجع جودة الخدمة وتواصل مع العملاء لمعرفة الأسباب وتحسين تجربتهم.',
        'color': Colors.orange,
      });
    }

    if (totalReservations > 0 &&
        (completedReservations / totalReservations) < 0.7) {
      recommendations.add({
        'icon': Icons.trending_down,
        'title':
            'معدل الإنجاز يحتاج تحسين (${(completedReservations / totalReservations * 100).toStringAsFixed(1)}%)',
        'description':
            'حاول تحسين سرعة الخدمة وزيادة عدد الموظفين في أوقات الذروة لرفع معدل الإنجاز.',
        'color': Colors.red,
      });
    }

    if (pendingReservations > 10) {
      recommendations.add({
        'icon': Icons.pending_actions,
        'title': 'حجوزات معلقة كثيرة ($pendingReservations حجز)',
        'description':
            'لديك عدد كبير من الحجوزات المعلقة. راجعها وقم بالموافقة أو الرفض لتحسين تجربة العملاء.',
        'color': Colors.blue,
      });
    }

    final daysCount =
        _reservationsByDate.length > 0 ? _reservationsByDate.length : 1;
    final avgDailyReservations = totalReservations / daysCount;
    if (totalReservations > 0 && avgDailyReservations < 5) {
      recommendations.add({
        'icon': Icons.campaign,
        'title':
            'متوسط الحجوزات منخفض (${avgDailyReservations.toStringAsFixed(1)} حجز/يوم)',
        'description':
            'جرّب حملات تسويقية، عروض خاصة، أو برامج ولاء لزيادة عدد الحجوزات اليومية.',
        'color': Colors.purple,
      });
    }

    if (_reservationsByDate.isNotEmpty) {
      final totalDaysInPeriod = DateTime.now()
              .difference(_reservationsByDate.keys
                  .reduce((a, b) => a.isBefore(b) ? a : b))
              .inDays +
          1;
      final emptyDays = totalDaysInPeriod - _reservationsByDate.length;

      if (emptyDays > 2) {
        recommendations.add({
          'icon': Icons.event_busy,
          'title': 'أيام بدون حجوزات ($emptyDays يوم)',
          'description':
              'فكر في إضافة عروض خاصة لأيام محددة أو إطلاق حملات تسويقية مستهدفة لملء الأيام الفارغة.',
          'color': Colors.deepOrange,
        });
      }
    }

    if (totalReservations > 0 &&
        (completedReservations / totalReservations) > 0.9) {
      recommendations.add({
        'icon': Icons.emoji_events,
        'title': 'معدل إنجاز ممتاز! 🏆',
        'description':
            'معدل الإنجاز لديك يتجاوز 90%! هذا دليل على جودة الخدمة. استمر في الحفاظ على هذا المستوى.',
        'color': Colors.green,
      });
    }

    if (_reservationsByDate.length >= 7) {
      final lastWeek = _reservationsByDate.entries
          .where((e) => DateTime.now().difference(e.key).inDays <= 7)
          .fold(0, (sum, e) => sum + e.value);
      final previousWeek = _reservationsByDate.entries
          .where((e) =>
              DateTime.now().difference(e.key).inDays > 7 &&
              DateTime.now().difference(e.key).inDays <= 14)
          .fold(0, (sum, e) => sum + e.value);

      if (previousWeek > 0 && lastWeek > previousWeek) {
        final growthRate =
            ((lastWeek - previousWeek) / previousWeek * 100).toStringAsFixed(1);
        recommendations.add({
          'icon': Icons.trending_up,
          'title': 'نمو في الحجوزات! 📈',
          'description':
              'حجوزاتك ارتفعت بنسبة $growthRate% مقارنة بالأسبوع الماضي. استمر في استراتيجيتك الحالية!',
          'color': Colors.teal,
        });
      }
    }

    return recommendations;
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
