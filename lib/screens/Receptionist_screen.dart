import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'Reservation_screen.dart';
import 'CarInput_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReceptionistScreen extends StatefulWidget {
  static const String routeName = 'receptionist_screen';
  final Map<String, dynamic> receptionist;
  final Map<String, dynamic> carWashInfo;

  const ReceptionistScreen({
    Key? key,
    required this.receptionist,
    required this.carWashInfo,
  }) : super(key: key);

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

class _ReceptionistScreenState extends State<ReceptionistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> allReservations = [];
  List<Map<String, dynamic>> pendingReservations = [];
  List<Map<String, dynamic>> approvedReservations = [];
  List<Map<String, dynamic>> rejectedReservations = [];

  bool isLoadingReservations = false;
  bool hasInitialized = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Map<String, dynamic>? _selectedCar;
  DateTime? _lastClickTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  void _initializeData() {
    if (!mounted || hasInitialized) return;

    setState(() {
      hasInitialized = true;
    });

    final carWashId = widget.carWashInfo['carWashId']?.toString() ?? '';
    if (carWashId.isNotEmpty) {
      fetchReservations(carWashId);
    }
  }

  bool _isDoubleClick() {
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inMilliseconds < 500) {
      return true;
    }
    _lastClickTime = now;
    return false;
  }

  Future<void> fetchReservations(String carWashId) async {
    if (carWashId.isEmpty || !mounted || isLoadingReservations) return;

    setState(() => isLoadingReservations = true);

    const String url = 'http://10.0.2.2/myapp/api/fetch_reservations.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'car_wash_id': carWashId},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success']) {
          final reservations = (data['reservations'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [];

          // ترتيب من الأحدث
          reservations.sort((a, b) {
            final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
            final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
            return dateB.compareTo(dateA);
          });

          setState(() {
            allReservations = reservations;
            _categorizeReservations();
            isLoadingReservations = false;
          });
        } else {
          setState(() => isLoadingReservations = false);
          _showMessage('فشل في تحميل الحجوزات: ${data['message']}');
        }
      } else {
        setState(() => isLoadingReservations = false);
        _showMessage('خطأ في الخادم: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingReservations = false);
        _showMessage('خطأ في تحميل الحجوزات: $e');
      }
    }
  }

  void _categorizeReservations() {
    pendingReservations =
        allReservations.where((res) => res['status'] == 'Pending').toList();
    approvedReservations =
        allReservations.where((res) => res['status'] == 'Approved').toList();
    rejectedReservations = allReservations
        .where(
            (res) => res['status'] == 'Rejected' || res['status'] == 'Canceled')
        .toList();
  }

  Future<void> _updateReservationStatus(
      int reservationId, String status) async {
    if (_isDoubleClick()) return;

    const String url =
        'http://10.0.2.2/myapp/api/update_reservation_status.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'reservation_id': reservationId.toString(),
          'status': status,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            final index = allReservations.indexWhere(
              (res) => res['reservation_id'] == reservationId,
            );
            if (index != -1) {
              allReservations[index]['status'] = status;
              _categorizeReservations();
            }
          });
          _showMessage('تم تحديث حالة الحجز إلى $status', isError: false);
        } else {
          _showMessage(data['message'] ?? 'فشل في تحديث الحالة');
        }
      } else {
        throw Exception('فشل في تحديث حالة الحجز');
      }
    } catch (e) {
      _showMessage('خطأ: $e');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildReservationsTab(
      List<Map<String, dynamic>> reservations, String title) {
    if (!hasInitialized || isLoadingReservations) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text('جاري تحميل الحجوزات...'),
          ],
        ),
      );
    }

    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'لا توجد حجوزات $title',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final carWashId = widget.carWashInfo['carWashId']?.toString() ?? '';
        if (carWashId.isNotEmpty) {
          await fetchReservations(carWashId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index]);
        },
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status'];
    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';
    final isRejected = status == 'Rejected' || status == 'Canceled';

    final String userName =
        reservation['user_name'] ?? reservation['name'] ?? 'غير محدد';
    final String userPhone =
        reservation['user_phone'] ?? reservation['phone'] ?? 'غير محدد';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation['service_name'] ?? 'خدمة غير محددة',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusTextColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildDetailRow(Icons.person, 'العميل', userName),
            _buildDetailRow(Icons.phone, 'الهاتف', userPhone),
            _buildDetailRow(
              Icons.directions_car,
              'السيارة',
              '${reservation['car_make'] ?? ''} ${reservation['car_model'] ?? ''} ${reservation['car_year'] ?? ''}',
            ),
            _buildDetailRow(
                Icons.date_range, 'التاريخ', reservation['date'] ?? 'غير محدد'),
            _buildDetailRow(
                Icons.access_time, 'الوقت', reservation['time'] ?? 'غير محدد'),

            if (isPending) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateReservationStatus(
                      reservation['reservation_id'],
                      'Approved',
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('قبول'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _updateReservationStatus(
                      reservation['reservation_id'],
                      'Rejected',
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[700]!),
                    ),
                  ),
                ],
              ),
            ],

            // زر التراجع للحجوزات المقبولة أو المرفوضة
            if (isApproved || isRejected) ...[
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _updateReservationStatus(
                    reservation['reservation_id'],
                    'Pending',
                  ),
                  icon: const Icon(Icons.undo),
                  label: const Text('تراجع - إعادة لقيد الانتظار'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[700]!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
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
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green[50]!;
      case 'Rejected':
        return Colors.red[50]!;
      case 'Canceled':
        return Colors.grey[200]!;
      default:
        return Colors.orange[50]!;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'Approved':
        return Colors.green[800]!;
      case 'Rejected':
        return Colors.red[800]!;
      case 'Canceled':
        return Colors.grey[600]!;
      default:
        return Colors.orange[800]!;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'Approved':
        return 'مقبول';
      case 'Rejected':
        return 'مرفوض';
      case 'Canceled':
        return 'ملغي';
      case 'Pending':
        return 'قيد الانتظار';
      default:
        return status ?? 'غير محدد';
    }
  }

  // باقي الكود كما هو...
  Widget _buildMakeReservationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المعلومات الشخصية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الجوال',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      // TODO: البحث عن السيارات المرتبطة برقم الجوال
                      if (value.length == 10) {
                        _searchCarsByPhone(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_isDoubleClick()) return;

                final carDetails = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarInputScreen(
                      userId:
                          widget.receptionist['ReceptionistID']?.toString() ??
                              '1',
                    ),
                  ),
                );

                if (carDetails != null && mounted) {
                  setState(() {
                    _selectedCar = carDetails as Map<String, dynamic>;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF370175),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(_selectedCar == null ? Icons.add : Icons.edit),
              label: Text(
                _selectedCar == null ? 'إضافة سيارة' : 'تعديل السيارة',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (_selectedCar != null)
            Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الماركة: ${_selectedCar!['make'] ?? 'غير محدد'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'الموديل: ${_selectedCar!['model'] ?? 'غير محدد'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'السنة: ${_selectedCar!['year'] ?? 'غير محدد'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _proceedToReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'متابعة',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchCarsByPhone(String phone) async {
    // TODO: تنفيذ البحث عن السيارات المرتبطة برقم الجوال
    // يمكن إضافة API endpoint جديد للبحث
  }

  void _proceedToReservation() {
    if (_isDoubleClick()) return;

    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : widget.receptionist['Name'] ?? 'موظف الاستقبال';

    final userPhone = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : widget.receptionist['Phone'] ?? '';

    if (userName.isEmpty || _selectedCar == null) {
      _showMessage('يرجى إكمال جميع الحقول وإضافة سيارة');
      return;
    }

    Navigator.pushNamed(
      context,
      ReservationScreen.screenRoute,
      arguments: {
        'carWashName': widget.carWashInfo['name'],
        'carWashId': widget.carWashInfo['carWashId'],
        'car': _selectedCar,
        'userId': widget.receptionist['ReceptionistID']?.toString() ?? '1',
        'name': userName,
        'phone': userPhone,
        'userType': 'receptionist',
        'duration': widget.carWashInfo['duration']?.toString() ?? '30',
        'capacity': widget.carWashInfo['capacity']?.toString() ?? '5',
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic> && mounted) {
        result['name'] = userName;
        result['phone'] = userPhone;
        result['user_name'] = userName;
        result['user_phone'] = userPhone;

        setState(() {
          allReservations.insert(0, result);
          _categorizeReservations();
        });
        _showMessage('تمت إضافة الحجز بنجاح!', isError: false);

        _nameController.clear();
        _phoneController.clear();
        setState(() {
          _selectedCar = null;
        });
      }
    });
  }

  Widget _buildReceptionistDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.receptionist['Name'] ??
                        widget.receptionist['name'] ??
                        'غير محدد',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'موظف استقبال',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 40),
                  _buildInfoItem(
                    Icons.email,
                    'البريد الإلكتروني',
                    widget.receptionist['Email'] ??
                        widget.receptionist['email'] ??
                        'غير محدد',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    Icons.phone,
                    'رقم الجوال',
                    widget.receptionist['Phone'] ??
                        widget.receptionist['phone'] ??
                        'غير محدد',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    allReservations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              if (!_isDoubleClick()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'قيد الانتظار'),
            Tab(icon: Icon(Icons.check_circle), text: 'مقبول'),
            Tab(icon: Icon(Icons.cancel), text: 'مرفوض'),
            Tab(icon: Icon(Icons.add_circle_outline), text: 'حجز جديد'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsTab(pendingReservations, 'قيد الانتظار'),
          _buildReservationsTab(approvedReservations, 'مقبولة'),
          _buildReservationsTab(rejectedReservations, 'مرفوضة'),
          _buildMakeReservationTab(),
        ],
      ),
    );
  }
}
