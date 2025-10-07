import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../services/reservation_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/error_handler.dart';

class OwnerReservationsTab extends StatefulWidget {
  final String carWashId;

  const OwnerReservationsTab({
    Key? key,
    required this.carWashId,
  }) : super(key: key);

  @override
  State<OwnerReservationsTab> createState() => _OwnerReservationsTabState();
}

// دالة مساعدة لتنسيق التاريخ
String _formatDate(DateTime date) {
  final year = date.year;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

class _OwnerReservationsTabState extends State<OwnerReservationsTab>
    with TickerProviderStateMixin {
  final _transactionService = TransactionService();
  final _reservationService = ReservationService();

  List<Map<String, dynamic>> _allReservations = [];
  List<Map<String, dynamic>> _filteredReservations = [];
  bool _isLoading = true;

  String _selectedFilter = 'all';
  String _searchQuery = '';
  DateTime? _selectedDate;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await _transactionService.fetchTransactions(widget.carWashId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _allReservations = response.data!;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReservations = _allReservations.where((reservation) {
        bool matchesSearch = true;
        bool matchesDate = true;
        bool matchesStatus = true;

        if (_searchQuery.isNotEmpty) {
          final userName =
              reservation['user_name']?.toString().toLowerCase() ?? '';
          final serviceName =
              reservation['service_name']?.toString().toLowerCase() ?? '';
          final query = _searchQuery.toLowerCase();
          matchesSearch =
              userName.contains(query) || serviceName.contains(query);
        }

        if (_selectedDate != null) {
          final reservationDate = DateTime.tryParse(reservation['date'] ?? '');
          if (reservationDate != null) {
            matchesDate = reservationDate.year == _selectedDate!.year &&
                reservationDate.month == _selectedDate!.month &&
                reservationDate.day == _selectedDate!.day;
          } else {
            matchesDate = false;
          }
        }

        if (_selectedFilter != 'all') {
          matchesStatus = reservation['status']?.toString() == _selectedFilter;
        }

        return matchesSearch && matchesDate && matchesStatus;
      }).toList();

      _filteredReservations.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    });
  }

  Future<void> _updateReservationStatus(int index, String newStatus) async {
    final reservation = _filteredReservations[index];
    final reservationId = reservation['reservation_id'];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'تأكيد التغيير',
      content: 'هل تريد تغيير حالة الحجز إلى "${_getStatusText(newStatus)}"؟',
      confirmText: 'نعم',
      cancelText: 'إلغاء',
    );

    if (!confirm) return;

    try {
      final response = await _reservationService.updateReservationStatus(
        reservationId: reservationId,
        status: newStatus,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          final allIndex = _allReservations.indexWhere(
            (r) => r['reservation_id'] == reservationId,
          );
          if (allIndex != -1) {
            _allReservations[allIndex]['status'] = newStatus;
            _applyFilters();
          }
        });
        ErrorHandler.showSuccessSnackBar(context, 'تم تحديث حالة الحجز بنجاح');
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
      case 'Canceled':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'قيد الانتظار';
      case 'Approved':
        return 'معتمد';
      case 'Rejected':
        return 'مرفوض';
      case 'Canceled':
        return 'ملغي';
      case 'Completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending_actions;
      case 'Approved':
        return Icons.check_circle;
      case 'Rejected':
        return Icons.cancel;
      case 'Canceled':
        return Icons.block;
      case 'Completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingReservations =
        _allReservations.where((r) => r['status'] == 'Pending').toList();
    final approvedReservations =
        _allReservations.where((r) => r['status'] == 'Approved').toList();
    final completedReservations =
        _allReservations.where((r) => r['status'] == 'Completed').toList();
    final canceledReservations = _allReservations
        .where((r) => r['status'] == 'Rejected' || r['status'] == 'Canceled')
        .toList();

    return Column(
      children: [
        _buildSearchAndFilterBar(),
        _buildStatsOverview(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReservationsList(_filteredReservations, 'الكل'),
              _buildReservationsList(pendingReservations, 'قيد الانتظار'),
              _buildReservationsList(approvedReservations, 'معتمد'),
              _buildReservationsList(completedReservations, 'مكتمل'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن حجز...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _applyFilters();
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _selectedDate == null
                        ? 'اختر التاريخ'
                        : _formatDate(_selectedDate!),
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'قيد الانتظار'),
              Tab(text: 'معتمد'),
              Tab(text: 'مكتمل'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final pending =
        _allReservations.where((r) => r['status'] == 'Pending').length;
    final approved =
        _allReservations.where((r) => r['status'] == 'Approved').length;
    final completed =
        _allReservations.where((r) => r['status'] == 'Completed').length;
    final total = _allReservations.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip('الإجمالي', '$total', Colors.blue),
          ),
          Expanded(
            child: _buildStatChip('قيد الانتظار', '$pending', Colors.orange),
          ),
          Expanded(
            child: _buildStatChip('معتمد', '$approved', Colors.green),
          ),
          Expanded(
            child: _buildStatChip('مكتمل', '$completed', Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
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
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(
      List<Map<String, dynamic>> reservations, String title) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد حجوزات $title',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index], index);
        },
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation, int index) {
    final status = reservation['status']?.toString() ?? 'Pending';
    final statusColor = _getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['service_name'] ?? 'خدمة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'حجز #${reservation['reservation_id']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(status),
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person, 'العميل',
                    reservation['user_name'] ?? 'غير محدد'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone, 'الهاتف',
                    reservation['user_phone'] ?? 'غير محدد'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.directions_car,
                  'السيارة',
                  '${reservation['car_make'] ?? ''} ${reservation['car_model'] ?? ''} ${reservation['car_year'] ?? ''}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'التاريخ',
                    reservation['date'] ?? 'غير محدد'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'الوقت',
                    reservation['time'] ?? 'غير محدد'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.attach_money,
                  'السعر',
                  '${reservation['service_price'] ?? '0'} ر.س',
                ),
                const SizedBox(height: 16),
                if (status == 'Pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateReservationStatus(index, 'Approved'),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('قبول'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _updateReservationStatus(index, 'Rejected'),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('رفض'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (status == 'Approved')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _updateReservationStatus(index, 'Completed'),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('تحديد كمكتمل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'غير محدد' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
