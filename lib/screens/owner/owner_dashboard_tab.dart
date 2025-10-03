import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../services/transaction_service.dart';
import '../../services/receptionist_service.dart';
import '../../services/service_service.dart';
import '../../utils/error_handler.dart';

class OwnerDashboardTab extends StatefulWidget {
  final Map<String, dynamic> carWashInfo;
  final VoidCallback onRefresh;

  const OwnerDashboardTab({
    Key? key,
    required this.carWashInfo,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<OwnerDashboardTab> createState() => _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends State<OwnerDashboardTab> {
  final _transactionService = TransactionService();
  final _receptionistService = ReceptionistService();
  final _serviceService = ServiceService();

  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _recentReservations = [];
  int _totalServices = 0;
  int _totalReceptionists = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final carWashId = widget.carWashInfo['carWashId']?.toString() ?? '';

      // تحميل المعاملات والإحصائيات
      final transactionsResponse =
          await _transactionService.fetchTransactions(carWashId);

      if (transactionsResponse.success && transactionsResponse.data != null) {
        final transactions = transactionsResponse.data!;
        _statistics = _transactionService.calculateStatistics(transactions);

        // أحدث 5 حجوزات
        _recentReservations = transactions.take(5).toList();
        _recentReservations.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });
      }

      // تحميل عدد الخدمات
      final servicesResponse = await _serviceService.fetchServices(carWashId);
      if (servicesResponse.success && servicesResponse.data != null) {
        _totalServices = servicesResponse.data!.length;
      }

      // تحميل عدد الموظفين
      final receptionistsResponse =
          await _receptionistService.fetchReceptionists(carWashId);
      if (receptionistsResponse.success && receptionistsResponse.data != null) {
        _totalReceptionists = receptionistsResponse.data!.length;
      }

      if (mounted) {
        setState(() => _isLoading = false);
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
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترحيب وبيانات المغسلة
            _buildWelcomeCard(),
            const SizedBox(height: AppSpacing.large),

            // الإحصائيات الرئيسية
            _buildStatisticsCards(),
            const SizedBox(height: AppSpacing.large),

            // ملخص سريع
            _buildQuickSummary(),
            const SizedBox(height: AppSpacing.large),

            // أحدث الحجوزات
            _buildRecentReservations(),
            const SizedBox(height: AppSpacing.large),

            // إجراءات سريعة
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final ownerProfile =
        widget.carWashInfo['ownerProfile'] as Map<String, dynamic>?;
    final ownerName = ownerProfile?['name']?.toString() ?? 'المالك';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.local_car_wash,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، $ownerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.carWashInfo['name'] ?? 'مغسلة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.carWashInfo['location'] ?? 'لا يوجد موقع',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final totalEarnings = _statistics['totalEarnings'] ?? 0.0;
    final totalReservations = _statistics['totalReservations'] ?? 0;
    final completedReservations = _statistics['completedReservations'] ?? 0;
    final pendingReservations = _statistics['pendingReservations'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظرة عامة على الأداء',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'إجمالي الأرباح',
              '${totalEarnings.toStringAsFixed(2)} ر.س',
              Icons.attach_money,
              Colors.green,
              Colors.green.shade50,
            ),
            _buildStatCard(
              'إجمالي الحجوزات',
              '$totalReservations',
              Icons.event_note,
              Colors.blue,
              Colors.blue.shade50,
            ),
            _buildStatCard(
              'الحجوزات المكتملة',
              '$completedReservations',
              Icons.check_circle,
              Colors.purple,
              Colors.purple.shade50,
            ),
            _buildStatCard(
              'قيد الانتظار',
              '$pendingReservations',
              Icons.pending_actions,
              Colors.orange,
              Colors.orange.shade50,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSummary() {
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
            'ملخص سريع',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            Icons.build_circle,
            'عدد الخدمات',
            '$_totalServices خدمة',
            Colors.blue,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.people,
            'عدد الموظفين',
            '$_totalReceptionists موظف',
            Colors.green,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.access_time,
            'ساعات العمل',
            '${widget.carWashInfo['open_time']} - ${widget.carWashInfo['close_time']}',
            Colors.orange,
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            Icons.timer,
            'مدة الخدمة',
            '${widget.carWashInfo['duration']} دقيقة',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'أحدث الحجوزات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // الانتقال لتبويب التحليلات
                // TODO: تنفيذ الانتقال
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentReservations.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد حجوزات حديثة',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentReservations.length,
            itemBuilder: (context, index) {
              final reservation = _recentReservations[index];
              return _buildReservationItem(reservation);
            },
          ),
      ],
    );
  }

  Widget _buildReservationItem(Map<String, dynamic> reservation) {
    final status = reservation['status']?.toString() ?? 'Pending';
    Color statusColor;
    String statusText;

    switch (status) {
      case 'Completed':
        statusColor = Colors.green;
        statusText = 'مكتمل';
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        break;
      case 'Canceled':
        statusColor = Colors.red;
        statusText = 'ملغي';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.event_available,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation['service_name'] ?? 'خدمة',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation['user_name'] ?? 'عميل'} • ${reservation['date'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'إضافة خدمة',
                Icons.add_circle_outline,
                Colors.blue,
                () {
                  // الانتقال لتبويب الخدمات
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'إضافة موظف',
                Icons.person_add_outlined,
                Colors.green,
                () {
                  // الانتقال لتبويب الموظفين
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
