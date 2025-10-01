import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fl_chart/fl_chart.dart'; // For fl_chart
import '../config/app_constants.dart';

class TransactionScreen extends StatefulWidget {
  static const String screenRoute = 'transaction_screen';
  final String carWashId; // Required parameter

  const TransactionScreen({super.key, required this.carWashId});

  @override
  _TransactionScreenState createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  List<Reservation> reservations = [];

  DateTime? selectedDate;
  String searchQuery = '';

  _fetchTransactions() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/myapp/api/Transaction.php'),
        body: {'car_wash_id': widget.carWashId},
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data['success'] == true) {
            setState(() {
              reservations = (data['reservations'] as List<dynamic>)
                  .map((item) => Reservation(
                        customerName: item['user_name'],
                        phone: item['user_phone'],
                        carMake: item['car_make'],
                        carModel: item['car_model'],
                        plateNumber: item['car_plate_number'],
                        service: item['service_name'],
                        date: DateTime.parse(item['date']),
                        time: item['time'],
                        price: double.tryParse(item['service_price']) ?? 0.0,
                        status: item['status'],
                      ))
                  .toList();
            });
          } else {
            print('Error: ${data['message']}');
          }
        } catch (e) {
          print('Error parsing response: $e');
          print(
              'Raw response: ${response.body}'); // Log raw response for debugging
        }
      } else {
        print(
            'Failed to load transactions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total earnings
    double totalEarnings = reservations
        .where((res) => res.status == 'Completed')
        .fold(0.0, (sum, res) => sum + (res.price ?? 0.0));

    // Calculate total reservations
    int totalReservations = reservations.length;

    // Filter reservations by selected date and search query
    List<Reservation> filteredReservations = reservations
        .where((res) =>
            (selectedDate == null || res.date.day == selectedDate!.day) &&
            (res.customerName
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                res.service.toLowerCase().contains(searchQuery.toLowerCase())))
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('المعاملات والإحصائيات'),
        backgroundColor: AppColors.background,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _showGraphDialog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Panel
            _buildStatisticsPanel(totalEarnings, totalReservations),
            const SizedBox(height: 20),
            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: 20),
            // Filter and Search Panel
            _buildFilterPanel(),
            const SizedBox(height: 20),
            // Reservations List
            Expanded(
              child: filteredReservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'لا توجد حجوزات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredReservations.length,
                      itemBuilder: (context, index) {
                        Reservation reservation = filteredReservations[index];
                        return _buildReservationCard(reservation);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show the date picker and set the selected date
  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to build statistics panel at the top
  Widget _buildStatisticsPanel(double totalEarnings, int totalReservations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'ملخص المعاملات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('إجمالي الأرباح',
                      '${totalEarnings.toStringAsFixed(2)} ريال'),
                  const SizedBox(width: 16),
                  _buildStatCard('إجمالي الحجوزات', '$totalReservations'),
                  const SizedBox(width: 16),
                  _buildStatCard('الحجوزات المكتملة',
                      '${reservations.where((r) => r.status == 'Completed').length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build each statistic card
  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Function to build reservation card
  Widget _buildReservationCard(Reservation reservation) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      elevation: AppSizes.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reservation Date and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy-MM-dd').format(reservation.date),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: reservation.status == 'Completed'
                        ? Colors.green[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reservation.status == 'Completed'
                        ? 'مكتمل'
                        : 'قيد الانتظار',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: reservation.status == 'Completed'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Information
            _buildInfoRow(Icons.person, 'العميل:', reservation.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'الهاتف:', reservation.phone),
            const SizedBox(height: 8),

            // Car Information
            _buildInfoRow(
              Icons.directions_car,
              'السيارة:',
              '${reservation.carMake} ${reservation.carModel}',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.format_list_numbered,
              'رقم اللوحة:',
              reservation.plateNumber,
            ),
            const SizedBox(height: 8),

            // Service and Time
            _buildInfoRow(Icons.local_car_wash, 'الخدمة:', reservation.service),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, 'الوقت:', reservation.time),
            const SizedBox(height: 8),

            // Price
            _buildInfoRow(
              Icons.attach_money,
              'السعر:',
              '${reservation.price?.toStringAsFixed(2) ?? '0.00'} ريال',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Filter panel with date picker and search options - تم إصلاح الأزرار هنا
  Widget _buildFilterPanel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // زر اختيار التاريخ - مُصلح
        SizedBox(
          width: 160,
          child: ElevatedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              selectedDate == null
                  ? 'اختر التاريخ'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!),
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // زر تصفية الخدمات - مُصلح
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: () {
              _showServiceFilterDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'تصفية الخدمات',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showServiceFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية حسب الخدمة'),
        content: const Text('هذه الخاصية قيد التطوير'),
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ),
        ],
      ),
    );
  }

  // Function to build the search bar
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'ابحث في الحجوزات...',
        hintText: 'أدخل اسم العميل أو الخدمة',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  // Function to show graph dialog using fl_chart
  _showGraphDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الرسوم البيانية للإيرادات والحجوزات',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
                  width: double.infinity,
                  child: _buildChart(),
                ),
                const SizedBox(height: 20),
                // هذا هو الزر المسبب للمشكلة في السطر 338 - تم إصلاحه
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to build the bar chart using fl_chart
  Widget _buildChart() {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'لا توجد بيانات للعرض',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Grouping reservations by date for the bar chart
    Map<DateTime, double> earningsByDate = {};
    Map<DateTime, int> reservationsByDate = {};

    for (var reservation in reservations) {
      var date = DateTime(
          reservation.date.year, reservation.date.month, reservation.date.day);
      earningsByDate[date] =
          (earningsByDate[date] ?? 0.0) + (reservation.price ?? 0.0);
      reservationsByDate[date] = (reservationsByDate[date] ?? 0) + 1;
    }

    // Prepare the data points for the chart
    List<BarChartGroupData> barGroups = [];
    List<String> daysOfWeek = [];

    earningsByDate.forEach((date, earnings) {
      String dayLabel = DateFormat('EEE').format(date);
      daysOfWeek.add(dayLabel);

      barGroups.add(BarChartGroupData(
        x: date.millisecondsSinceEpoch,
        barRods: [
          BarChartRodData(
            toY: reservationsByDate[date]!.toDouble(),
            color: AppColors.primary,
            width: 16,
          ),
        ],
      ));
    });

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value % 1 == 0 ? value.toInt().toString() : '');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < daysOfWeek.length) {
                  return Text(daysOfWeek[index]);
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

// Reservation class to store reservation data
class Reservation {
  final String customerName;
  final String phone;
  final String carMake;
  final String carModel;
  final String plateNumber;
  final String service;
  final DateTime date;
  final String time;
  final double? price;
  String status;

  Reservation({
    required this.customerName,
    required this.phone,
    required this.carMake,
    required this.carModel,
    required this.plateNumber,
    required this.service,
    required this.date,
    required this.time,
    required this.price,
    this.status = 'Pending',
  });
}
