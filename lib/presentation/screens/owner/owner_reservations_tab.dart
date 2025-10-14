import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../services/transaction_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/date_formatter.dart';

class OwnerReservationsTab extends StatefulWidget {
  final String carWashId;

  const OwnerReservationsTab({
    Key? key,
    required this.carWashId,
  }) : super(key: key);

  @override
  State<OwnerReservationsTab> createState() => _OwnerReservationsTabState();
}

class _OwnerReservationsTabState extends State<OwnerReservationsTab> {
  final _transactionService = TransactionService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allReservations = [];
  List<Map<String, dynamic>> _filteredReservations = [];
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;

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
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            response.message ?? 'فشل في تحميل الحجوزات',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allReservations);

    // فلتر حسب الحالة
    if (_selectedFilter != 'all') {
      filtered = filtered.where((r) {
        final status = (r['status'] ?? '').toString().toLowerCase();
        return status == _selectedFilter.toLowerCase();
      }).toList();
    }

    // فلتر حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final userName = (r['user_name'] ?? '').toString().toLowerCase();
        final serviceName = (r['service_name'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return userName.contains(query) || serviceName.contains(query);
      }).toList();
    }

    // ترتيب حسب التاريخ (الأحدث أولاً)
    filtered.sort((a, b) {
      final dateA =
          DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1970);
      final dateB =
          DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    _filteredReservations = filtered;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'مكتمل';
      case 'pending':
        return 'قيد الانتظار';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع الحجوزات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
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
          // شريط البحث
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'البحث عن حجز...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // أزرار الفلتر
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'الكل', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'pending', 'قيد الانتظار', Icons.pending_actions),
                const SizedBox(width: 8),
                _buildFilterChip('approved', 'مكتمل', Icons.check_circle),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'ملغي', Icons.cancel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildReservationsList() {
    if (_filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.event_busy,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد حجوزات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isEmpty && _selectedFilter == 'all')
              const SizedBox(height: 8),
            if (_searchQuery.isEmpty && _selectedFilter == 'all')
              Text(
                'لم يتم إنشاء أي حجوزات بعد',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredReservations.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final reservation = _filteredReservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status']?.toString() ?? 'Pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    final dateStr = reservation['date']?.toString() ?? '';
    String formattedDate = '';
    String formattedTime = '';

    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormatter.formatShortDate(date);
        formattedTime = DateFormatter.formatTime(date);
      } catch (e) {
        formattedDate = dateStr;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: () => _showReservationDetails(reservation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation['service_name']?.toString() ?? 'خدمة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              reservation['user_name']?.toString() ?? 'عميل',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'التاريخ',
                      formattedDate,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'الوقت',
                      formattedTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.attach_money,
                      'السعر',
                      '${reservation['service_price'] ?? '0'} ر.س',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.phone,
                      'الهاتف',
                      reservation['user_phone']?.toString() ?? 'غير متوفر',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReservationDetails(Map<String, dynamic> reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final status = reservation['status']?.toString() ?? 'Pending';
          final statusColor = _getStatusColor(status);
          final statusText = _getStatusText(status);

          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getStatusIcon(status),
                            color: statusColor, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تفاصيل الحجز',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    'الخدمة',
                    reservation['service_name']?.toString() ?? 'غير متوفر',
                    Icons.build_circle,
                  ),
                  _buildDetailRow(
                    'العميل',
                    reservation['user_name']?.toString() ?? 'غير متوفر',
                    Icons.person,
                  ),
                  _buildDetailRow(
                    'رقم الهاتف',
                    reservation['user_phone']?.toString() ?? 'غير متوفر',
                    Icons.phone,
                  ),
                  _buildDetailRow(
                    'التاريخ',
                    DateFormatter.formatFullDate(
                      DateTime.tryParse(
                              reservation['date']?.toString() ?? '') ??
                          DateTime.now(),
                    ),
                    Icons.calendar_today,
                  ),
                  _buildDetailRow(
                    'السعر',
                    '${reservation['service_price'] ?? '0'} ر.س',
                    Icons.attach_money,
                  ),
                  const SizedBox(height: 24),
                  if (status.toLowerCase() == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateReservationStatus(
                                reservation,
                                'approved', // تم التغيير من Completed إلى approved
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('إتمام الحجز'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateReservationStatus(
                                reservation,
                                'cancelled', // تم التغيير من Cancelled إلى cancelled
                              );
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('إلغاء'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
      ),
    );
  }

  Future<void> _updateReservationStatus(
    Map<String, dynamic> reservation,
    String newStatus,
  ) async {
    try {
      final reservationId = reservation['reservation_id']?.toString();
      if (reservationId == null) {
        throw 'معرف الحجز غير موجود';
      }

      // عرض مؤشر التحميل
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final response = await _transactionService.updateTransactionStatus(
        reservationId,
        newStatus,
      );

      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
      }

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('تم تحديث حالة الحجز إلى ${_getStatusText(newStatus)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadReservations(); // إعادة تحميل البيانات
      } else {
        throw response.message ?? 'فشل تحديث الحجز';
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل إن وجد
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }
}
