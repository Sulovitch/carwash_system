import 'package:flutter/material.dart';
import '../../services/reservation_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';

class UserReservationsTab extends StatefulWidget {
  final String userId;

  const UserReservationsTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserReservationsTab> createState() => _UserReservationsTabState();
}

class _UserReservationsTabState extends State<UserReservationsTab> {
  final _reservationService = ReservationService();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      final response = await _reservationService.fetchUserReservations(
        widget.userId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _reservations = response.data!;
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

  Future<void> _cancelReservation(int index) async {
    final reservation = _reservations[index];
    final reservationId = reservation['reservation_id'];
    final previousStatus = reservation['status'];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'إلغاء الحجز',
      content: 'هل أنت متأكد من إلغاء هذا الحجز؟',
      confirmText: 'نعم، إلغاء',
      cancelText: 'لا',
    );

    if (!confirm) return;

    // تحديث واجهة المستخدم مؤقتاً
    setState(() {
      _reservations[index]['status'] = 'جاري الإلغاء...';
    });

    try {
      final response =
          await _reservationService.cancelReservation(reservationId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _reservations[index]['status'] = 'Canceled';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إلغاء الحجز بنجاح'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () =>
                  _undoCancellation(index, reservationId, previousStatus),
            ),
          ),
        );
      } else {
        // استعادة الحالة السابقة
        setState(() {
          _reservations[index]['status'] = previousStatus;
        });
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      // استعادة الحالة السابقة
      setState(() {
        _reservations[index]['status'] = previousStatus;
      });
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _undoCancellation(
    int index,
    int reservationId,
    String previousStatus,
  ) async {
    try {
      final response = await _reservationService.updateReservationStatus(
        reservationId: reservationId,
        status: previousStatus,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _reservations[index]['status'] = previousStatus;
        });
        ErrorHandler.showSuccessSnackBar(context, 'تم استعادة الحجز');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
      case 'Canceled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'قيد الانتظار';
      case 'Approved':
        return 'مقبول';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
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
            const SizedBox(height: AppSpacing.small),
            Text(
              'احجز موعداً للبدء',
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
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.medium),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          final status = reservation['status']?.toString() ?? 'Pending';
          final canCancel = status == 'Pending';

          return Card(
            elevation: AppSizes.cardElevation,
            margin: const EdgeInsets.only(bottom: AppSpacing.medium),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رأس البطاقة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          reservation['service_name'] ?? 'خدمة غير محددة',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.small,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.large),

                  // تفاصيل السيارة
                  _buildDetailRow(
                    Icons.directions_car,
                    'السيارة',
                    '${reservation['car_make']} ${reservation['car_model']} (${reservation['car_year']})',
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // التاريخ
                  _buildDetailRow(
                    Icons.calendar_today,
                    'التاريخ',
                    reservation['date'] ?? '',
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // الوقت
                  _buildDetailRow(
                    Icons.access_time,
                    'الوقت',
                    reservation['time'] ?? '',
                  ),

                  // زر الإلغاء
                  if (canCancel) ...[
                    const SizedBox(height: AppSpacing.medium),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelReservation(index),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text('إلغاء الحجز'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: AppSpacing.small),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
