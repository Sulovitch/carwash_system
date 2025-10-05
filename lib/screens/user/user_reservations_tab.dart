import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/reservation_service.dart';
import '../../services/carwash_service.dart';
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
  final _carWashService = CarWashService();
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
        final sortedReservations = response.data!;

        try {
          final cwResp = await _carWashService.fetchCarWashes();
          if (cwResp.success && cwResp.data != null) {
            final carWashes = cwResp.data!;
            final Map<String, Map<String, dynamic>> byId = {
              for (final cw in carWashes) (cw['id']?.toString() ?? ''): cw,
            };
            for (final r in sortedReservations) {
              final String cwId = (r['car_wash_id'] ??
                          r['carWashId'] ??
                          (r['car_wash'] is Map ? r['car_wash']['id'] : null))
                      ?.toString() ??
                  '';
              if (cwId.isNotEmpty && byId.containsKey(cwId)) {
                final cw = byId[cwId]!;
                r['car_wash_name'] = r['car_wash_name'] ?? cw['name'];
                r['car_wash_profile_image'] =
                    r['car_wash_profile_image'] ?? cw['profile_image'];
                r['car_wash_phone'] = r['car_wash_phone'] ?? cw['phone'];
              }
            }
          }
        } catch (_) {}

        sortedReservations.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _reservations = sortedReservations;
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
      confirmText: 'تأكيد الإلغاء',
      cancelText: 'رجوع',
    );

    if (!confirm) return;

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
        setState(() {
          _reservations[index]['status'] = previousStatus;
        });
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reservations[index]['status'] = previousStatus;
      });
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _undoCancellation(
      int index, int reservationId, String previousStatus) async {
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
        ErrorHandler.showSuccessSnackBar(context, 'تم التراجع عن الإلغاء');
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // تنظيف رقم الهاتف من المسافات والرموز غير الضرورية
    final cleanNumber = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');

    if (cleanNumber.isEmpty) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'رقم الهاتف غير متوفر');
      }
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    try {
      // استخدم LaunchMode.externalApplication بشكل صريح
      final bool launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'لا يوجد تطبيق هاتف متاح على هذا الجهاز',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'خطأ في إجراء المكالمة: ${e.toString()}',
        );
      }
    }
  }

  void _openChat(Map<String, dynamic> reservation) {
    // TODO: فتح صفحة الدردشة
    ErrorHandler.showInfoSnackBar(context, 'ميزة الدردشة قريباً');
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

  String _getCarWashName(Map<String, dynamic> r) {
    final candidates = [
      r['car_wash_name'],
      r['carWashName'],
      r['car_wash_title'],
      r['carwash_name'],
      r['carwash_title'],
      r['name'],
    ];
    for (final c in candidates) {
      final s = c?.toString();
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    final cw = r['car_wash'];
    if (cw is Map) {
      final nestedCandidates = [cw['name'], cw['title']];
      for (final c in nestedCandidates) {
        final s = c?.toString();
        if (s != null && s.trim().isNotEmpty) return s.trim();
      }
    }
    return '';
  }

  String _getCarWashImageUrl(Map<String, dynamic> r) {
    final candidates = [
      r['car_wash_profile_image'],
      r['profile_image'],
      r['car_wash_image'],
      r['carWashProfileImage'],
      r['logo'],
      r['image'],
    ];
    for (final c in candidates) {
      final s = c?.toString();
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    final cw = r['car_wash'];
    if (cw is Map) {
      final nestedCandidates = [
        cw['profile_image'],
        cw['image'],
        cw['logo'],
      ];
      for (final c in nestedCandidates) {
        final s = c?.toString();
        if (s != null && s.trim().isNotEmpty) return s.trim();
      }
    }
    return '';
  }

  Widget _buildCarWashAvatar(Map<String, dynamic> reservation) {
    final url = _getCarWashImageUrl(reservation);
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.local_car_wash, color: Colors.blue, size: 16),
      );
    }
    return const Icon(Icons.local_car_wash, color: Colors.blue, size: 16);
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
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'لا توجد حجوزات حالياً',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'قم بالحجز من الصفحة الرئيسية',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
          final phoneNumber = reservation['car_wash_phone']?.toString() ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation['service_name'] ?? 'خدمة غير محددة',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.blueAccent.withOpacity(0.08),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildCarWashAvatar(reservation),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Builder(
                                      builder: (_) {
                                        final name =
                                            _getCarWashName(reservation);
                                        return Text(
                                          name.isEmpty ? '-' : name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    reservation['date'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    reservation['time'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(status).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.directions_car,
                                    color: Colors.blue, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${reservation['car_make'] ?? ''} ${reservation['car_model'] ?? ''}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'سنة: ${reservation['car_year'] ?? 'غير محدد'}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (reservation['price'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.payments, 'السعر',
                              '${reservation['price']} ريال'),
                        ],

                        const SizedBox(height: 16),

                        // أزرار الإجراءات
                        Row(
                          children: [
                            // زر الاتصال
                            if (phoneNumber.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _makePhoneCall(phoneNumber),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green[700],
                                    side: BorderSide(color: Colors.green[300]!),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.phone, size: 18),
                                  label: const Text('اتصال',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ),

                            if (phoneNumber.isNotEmpty)
                              const SizedBox(width: 8),

                            // زر الدردشة
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openChat(reservation),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(color: Colors.blue[300]!),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline,
                                    size: 18),
                                label: const Text('دردشة',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),

                        if (canCancel) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _cancelReservation(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red[700],
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.red[200]!),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text(
                                'إلغاء الحجز',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
