import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EnhancedTransactionScreen extends StatefulWidget {
  static const String screenRoute = 'enhanced_transaction_screen';
  final String carWashId;

  const EnhancedTransactionScreen({super.key, required this.carWashId});

  @override
  _EnhancedTransactionScreenState createState() =>
      _EnhancedTransactionScreenState();
}

class _EnhancedTransactionScreenState extends State<EnhancedTransactionScreen> {
  List<Reservation> reservations = [];
  List<Reservation> filteredReservations = [];

  DateTime? selectedDate;
  String searchQuery = '';
  String selectedStatus = 'الكل';
  String sortBy = 'date'; // date, price, status
  bool isAscending = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/myapp/api/Transaction.php'),
        body: {'car_wash_id': widget.carWashId},
      );

      if (response.statusCode == 200) {
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
            _applyFilters();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching transactions: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredReservations = reservations.where((res) {
        // تصفية حسب التاريخ
        bool matchesDate = selectedDate == null ||
            (res.date.year == selectedDate!.year &&
                res.date.month == selectedDate!.month &&
                res.date.day == selectedDate!.day);

        // تصفية حسب البحث
        bool matchesSearch = searchQuery.isEmpty ||
            res.customerName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            res.service.toLowerCase().contains(searchQuery.toLowerCase());

        // تصفية حسب الحالة
        bool matchesStatus =
            selectedStatus == 'الكل' || res.status == selectedStatus;

        return matchesDate && matchesSearch && matchesStatus;
      }).toList();

      // ترتيب النتائج
      _sortReservations();
    });
  }

  void _sortReservations() {
    filteredReservations.sort((a, b) {
      int comparison = 0;
      switch (sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'price':
          comparison = (a.price ?? 0.0).compareTo(b.price ?? 0.0);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
      }
      return isAscending ? comparison : -comparison;
    });
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير المعاملات',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(
                  'التاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
              pw.Text('إجمالي المعاملات: ${filteredReservations.length}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['العميل', 'الخدمة', 'التاريخ', 'السعر', 'الحالة'],
                data: filteredReservations
                    .take(50)
                    .map((res) => [
                          res.customerName,
                          res.service,
                          DateFormat('yyyy-MM-dd').format(res.date),
                          '${res.price?.toStringAsFixed(2)} ر.س',
                          res.status,
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('إدارة المعاملات المتقدمة'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToPDF,
            tooltip: 'تصدير PDF',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (sortBy == value) {
                  isAscending = !isAscending;
                } else {
                  sortBy = value;
                  isAscending = true;
                }
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'date', child: Text('ترتيب حسب التاريخ')),
              const PopupMenuItem(
                  value: 'price', child: Text('ترتيب حسب السعر')),
              const PopupMenuItem(
                  value: 'status', child: Text('ترتيب حسب الحالة')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTransactions,
              child: CustomScrollView(
                slivers: [
                  // بطاقات الإحصائيات
                  SliverToBoxAdapter(
                    child: _buildStatisticsSection(stats),
                  ),

                  // الفلاتر
                  SliverToBoxAdapter(
                    child: _buildFiltersSection(),
                  ),

                  // رسم بياني مصغر
                  SliverToBoxAdapter(
                    child: _buildMiniChart(),
                  ),

                  // قائمة المعاملات
                  filteredReservations.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long,
                                    size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد معاملات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildReservationCard(
                                    filteredReservations[index]);
                              },
                              childCount: filteredReservations.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الأداء',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'إجمالي الأرباح',
                '${stats['totalRevenue'].toStringAsFixed(2)} ر.س',
                Icons.attach_money,
                Colors.green,
                '↑ ${stats['revenueChange']}%',
              ),
              _buildStatCard(
                'الحجوزات',
                '${stats['totalReservations']}',
                Icons.event_note,
                Colors.blue,
                '${stats['completionRate']}% إنجاز',
              ),
              _buildStatCard(
                'متوسط القيمة',
                '${stats['averageValue'].toStringAsFixed(2)} ر.س',
                Icons.trending_up,
                Colors.purple,
                'لكل حجز',
              ),
              _buildStatCard(
                'قيد الانتظار',
                '${stats['pendingCount']}',
                Icons.pending_actions,
                Colors.orange,
                'يحتاج متابعة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'تصفية وبحث',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // شريط البحث
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن عميل أو خدمة...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),

          // الفلاتر السريعة
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('الكل'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Completed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Pending'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('Canceled'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // اختيار التاريخ
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                  _applyFilters();
                });
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              selectedDate == null
                  ? 'اختر التاريخ'
                  : DateFormat('yyyy-MM-dd').format(selectedDate!),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (selectedDate != null)
            TextButton(
              onPressed: () {
                setState(() {
                  selectedDate = null;
                  _applyFilters();
                });
              },
              child: const Text('إلغاء تصفية التاريخ'),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = selectedStatus == status;
    return FilterChip(
      label: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = status;
          _applyFilters();
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'الكل':
        return 'الكل';
      case 'Completed':
        return 'مكتمل';
      case 'Pending':
        return 'منتظر';
      case 'Canceled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Widget _buildMiniChart() {
    if (filteredReservations.isEmpty) return const SizedBox.shrink();

    final dailyRevenue = <String, double>{};
    for (var res in filteredReservations) {
      final dateKey = DateFormat('MM/dd').format(res.date);
      dailyRevenue[dateKey] =
          (dailyRevenue[dateKey] ?? 0.0) + (res.price ?? 0.0);
    }

    final spots = dailyRevenue.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'الإيرادات اليومية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
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

  Widget _buildReservationCard(Reservation reservation) {
    final statusColor = _getStatusColor(reservation.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReservationDetails(reservation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reservation.service,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusLabel(reservation.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('yyyy-MM-dd').format(reservation.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      reservation.time,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reservation.price?.toStringAsFixed(2) ?? '0.00'} ر.س',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showReservationDetails(Reservation reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'تفاصيل الحجز',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildDetailRow(Icons.person, 'العميل', reservation.customerName),
              _buildDetailRow(Icons.phone, 'الهاتف', reservation.phone),
              _buildDetailRow(Icons.directions_car, 'السيارة',
                  '${reservation.carMake} ${reservation.carModel}'),
              _buildDetailRow(Icons.format_list_numbered, 'رقم اللوحة',
                  reservation.plateNumber),
              _buildDetailRow(Icons.build, 'الخدمة', reservation.service),
              _buildDetailRow(Icons.calendar_today, 'التاريخ',
                  DateFormat('yyyy-MM-dd').format(reservation.date)),
              _buildDetailRow(Icons.access_time, 'الوقت', reservation.time),
              _buildDetailRow(Icons.attach_money, 'السعر',
                  '${reservation.price?.toStringAsFixed(2) ?? '0.00'} ر.س'),
              _buildDetailRow(
                  Icons.info, 'الحالة', _getStatusLabel(reservation.status),
                  color: _getStatusColor(reservation.status)),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('إغلاق'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color ?? AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics() {
    double totalRevenue = 0.0;
    int completedCount = 0;
    int pendingCount = 0;

    for (var res in filteredReservations) {
      totalRevenue += res.price ?? 0.0;
      if (res.status == 'Completed') completedCount++;
      if (res.status == 'Pending') pendingCount++;
    }

    final averageValue = filteredReservations.isNotEmpty
        ? totalRevenue / filteredReservations.length
        : 0.0;

    final completionRate = filteredReservations.isNotEmpty
        ? (completedCount / filteredReservations.length * 100)
            .toStringAsFixed(1)
        : '0.0';

    return {
      'totalRevenue': totalRevenue,
      'totalReservations': filteredReservations.length,
      'averageValue': averageValue,
      'pendingCount': pendingCount,
      'completionRate': completionRate,
      'revenueChange': '12.5', // يمكن حسابها من البيانات السابقة
    };
  }
}

// نموذج الحجز
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
