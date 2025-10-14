import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../data/models/Car.dart';
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

  // Reservations data
  List<Map<String, dynamic>> allReservations = [];
  List<Map<String, dynamic>> pendingReservations = [];
  List<Map<String, dynamic>> approvedReservations = [];
  List<Map<String, dynamic>> rejectedReservations = [];

  bool isLoadingReservations = false;
  bool hasInitialized = false;

  // Quick booking data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  List<Car> _foundCars = [];
  Car? _selectedCar;
  bool _isSearchingCars = false;
  bool _showCarsList = false;
  String _searchQuery = '';
  String _selectedFilter = 'الكل';

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
        onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success']) {
          final reservations = (data['reservations'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [];

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

  List<Map<String, dynamic>> _getFilteredReservations(
      List<Map<String, dynamic>> reservations) {
    if (_searchQuery.isEmpty) return reservations;

    return reservations.where((res) {
      final name = res['user_name']?.toString().toLowerCase() ?? '';
      final phone = res['user_phone']?.toString().toLowerCase() ?? '';
      final service = res['service_name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          phone.contains(query) ||
          service.contains(query);
    }).toList();
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
        onTimeout: () => throw Exception('انتهت مهلة الاتصال'),
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

  Future<void> _searchCarsByPhone(String phone) async {
    if (phone.length < 10) {
      setState(() {
        _foundCars = [];
        _showCarsList = false;
      });
      return;
    }

    setState(() {
      _isSearchingCars = true;
      _showCarsList = false;
    });

    try {
      // نحتاج userId من الهاتف - يمكن عمل API endpoint جديد
      // هنا سنستخدم طريقة مؤقتة للبحث
      final response = await http.post(
        Uri.parse('http://10.0.2.2/myapp/api/search_cars_by_phone.php'),
        body: {'phone': phone},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['cars'] is List) {
          final cars = (data['cars'] as List).map((carData) {
            String plateNumbers = carData['plateNumbers']?.toString() ?? '';
            String plateLetters = carData['plateLetters']?.toString() ?? '';

            List<String> arabicNums = ['', '', '', ''];
            List<String> latinNums = ['', '', '', ''];
            List<String> arabicLetters = ['', '', ''];
            List<String> latinLetters = ['', '', ''];

            if (plateNumbers.length >= 8) {
              arabicNums = plateNumbers.substring(0, 4).split('');
              latinNums = plateNumbers.substring(4, 8).split('');
            }

            if (plateLetters.length >= 6) {
              arabicLetters = plateLetters.substring(0, 3).split('');
              latinLetters = plateLetters.substring(3, 6).split('');
            }

            return Car(
              carId: carData['Car_id'],
              selectedMake: carData['Car_make']?.toString(),
              selectedModel: carData['Car_model']?.toString(),
              selectedYear: carData['Car_year']?.toString(),
              selectedArabicNumbers: arabicNums,
              selectedLatinNumbers: latinNums,
              selectedArabicLetters: arabicLetters,
              selectedLatinLetters: latinLetters,
            );
          }).toList();

          setState(() {
            _foundCars = cars;
            _isSearchingCars = false;
            _showCarsList = cars.isNotEmpty;

            if (cars.isEmpty) {
              _showMessage('لم يتم العثور على سيارات مسجلة بهذا الرقم',
                  isError: false);
            }
          });
        } else {
          setState(() {
            _foundCars = [];
            _isSearchingCars = false;
            _showCarsList = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearchingCars = false;
          _showCarsList = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _proceedToReservation() {
    if (_isDoubleClick()) return;

    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : widget.receptionist['Name'] ?? 'موظف الاستقبال';

    final userPhone = _phoneController.text.isNotEmpty
        ? _phoneController.text
        : widget.receptionist['Phone'] ?? '';

    if (userName.isEmpty || _selectedCar == null || userPhone.isEmpty) {
      _showMessage('يرجى إكمال جميع الحقول وإضافة سيارة');
      return;
    }

    Navigator.pushNamed(
      context,
      ReservationScreen.screenRoute,
      arguments: {
        'carWashName': widget.carWashInfo['name'],
        'carWashId': widget.carWashInfo['carWashId'],
        'car': {
          'car_id': _selectedCar!.carId,
          'make': _selectedCar!.selectedMake,
          'model': _selectedCar!.selectedModel,
          'year': _selectedCar!.selectedYear,
          'plateNumbers': _selectedCar!.selectedArabicNumbers +
              _selectedCar!.selectedLatinNumbers,
          'plateLetters': _selectedCar!.selectedArabicLetters +
              _selectedCar!.selectedLatinLetters,
        },
        'userId': widget.receptionist['ReceptionistID']?.toString() ?? '1',
        'name': userName,
        'phone': userPhone,
        'userType': 'receptionist',
        'duration': widget.carWashInfo['duration']?.toString() ?? '30',
        'capacity': widget.carWashInfo['capacity']?.toString() ?? '5',
        'bookingSource': 'walk-in',
        'createdBy': widget.receptionist['ReceptionistID'],
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
          _foundCars = [];
          _showCarsList = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    allReservations.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لوحة التحكم', style: TextStyle(fontSize: 18)),
            Text(
              widget.receptionist['Name'] ?? 'موظف استقبال',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () {
                if (!_isDoubleClick()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: Icon(Icons.add_circle_outline, size: 20),
              text: 'حجز جديد',
            ),
            Tab(
              icon: Icon(Icons.pending_actions, size: 20),
              text: 'قيد الانتظار',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline, size: 20),
              text: 'مقبول',
            ),
            Tab(
              icon: Icon(Icons.cancel_outlined, size: 20),
              text: 'مرفوض',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickBookingTab(),
          _buildReservationsTab(pendingReservations, 'قيد الانتظار', true),
          _buildReservationsTab(approvedReservations, 'مقبولة', false),
          _buildReservationsTab(rejectedReservations, 'مرفوضة', false),
        ],
      ),
    );
  }

  Widget _buildQuickBookingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_business,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حجز سريع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'أضف حجز جديد بسرعة وسهولة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Customer Info Card
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person_outline,
                          color: Colors.blue.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'معلومات العميل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم العميل *',
                    hintText: 'أدخل الاسم الكامل',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),

                // Phone Field with Search
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'رقم الجوال *',
                    hintText: '05xxxxxxxx',
                    prefixIcon: const Icon(Icons.phone),
                    suffixIcon: _isSearchingCars
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    if (value.length == 10) {
                      _searchCarsByPhone(value);
                    } else {
                      setState(() {
                        _foundCars = [];
                        _showCarsList = false;
                      });
                    }
                  },
                ),

                // Found Cars List
                if (_showCarsList && _foundCars.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'تم العثور على ${_foundCars.length} سيارة مسجلة',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...(_foundCars.map((car) => _buildCarOption(car))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Selected Car or Add New
          if (_selectedCar != null)
            _buildSelectedCarCard()
          else
            _buildAddCarButton(),

          const SizedBox(height: 24),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (_nameController.text.isNotEmpty &&
                      _phoneController.text.length == 10 &&
                      _selectedCar != null)
                  ? _proceedToReservation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'متابعة للحجز',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarOption(Car car) {
    final isSelected = _selectedCar?.carId == car.carId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCar = car;
              _showCarsList = false;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.selectedMake ?? ''} ${car.selectedModel ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? Colors.blue.shade900
                              : Colors.black87,
                        ),
                      ),
                      Text(
                        'سنة: ${car.selectedYear ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle,
                      color: Colors.blue.shade700, size: 24)
                else
                  Icon(Icons.circle_outlined,
                      color: Colors.grey.shade400, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.check_circle,
                    color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'السيارة المختارة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue.shade700,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarInputScreen(
                        userId:
                            widget.receptionist['ReceptionistID']?.toString() ??
                                '1',
                        existingCar: _selectedCar,
                      ),
                    ),
                  );

                  if (result != null && mounted) {
                    // تحديث السيارة المختارة
                    final plateNumbers = result['plateNumbers'] as List;
                    final plateLetters = result['plateLetters'] as List;

                    setState(() {
                      _selectedCar = Car(
                        carId: result['car_id'],
                        selectedMake: result['make'],
                        selectedModel: result['model'],
                        selectedYear: result['year'],
                        selectedArabicNumbers: plateNumbers
                            .sublist(0, 4)
                            .map((e) => e?.toString())
                            .toList(),
                        selectedLatinNumbers: plateNumbers
                            .sublist(4, 8)
                            .map((e) => e?.toString())
                            .toList(),
                        selectedArabicLetters: plateLetters
                            .sublist(0, 3)
                            .map((e) => e?.toString())
                            .toList(),
                        selectedLatinLetters: plateLetters
                            .sublist(3, 6)
                            .map((e) => e?.toString())
                            .toList(),
                      );
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _selectedCar = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.directions_car,
                    color: Colors.blue.shade700, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCar!.selectedMake ?? ''} ${_selectedCar!.selectedModel ?? ''}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'سنة الصنع: ${_selectedCar!.selectedYear ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCarButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        if (_isDoubleClick()) return;

        final carDetails = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarInputScreen(
              userId: widget.receptionist['ReceptionistID']?.toString() ?? '1',
            ),
          ),
        );

        if (carDetails != null && mounted) {
          setState(() {
            final plateNumbers = carDetails['plateNumbers'] as List;
            final plateLetters = carDetails['plateLetters'] as List;

            _selectedCar = Car(
              carId: carDetails['car_id'],
              selectedMake: carDetails['make'],
              selectedModel: carDetails['model'],
              selectedYear: carDetails['year'],
              selectedArabicNumbers:
                  plateNumbers.sublist(0, 4).map((e) => e?.toString()).toList(),
              selectedLatinNumbers:
                  plateNumbers.sublist(4, 8).map((e) => e?.toString()).toList(),
              selectedArabicLetters:
                  plateLetters.sublist(0, 3).map((e) => e?.toString()).toList(),
              selectedLatinLetters:
                  plateLetters.sublist(3, 6).map((e) => e?.toString()).toList(),
            );
          });
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue.shade700,
        side: BorderSide(color: Colors.blue.shade200, width: 2),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(Icons.add_circle_outline, size: 24),
      label: const Text(
        'إضافة سيارة جديدة',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildReservationsTab(
    List<Map<String, dynamic>> reservations,
    String title,
    bool showActions,
  ) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن عميل، خدمة، أو رقم جوال...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('الكل', Icons.list),
                    const SizedBox(width: 8),
                    _buildFilterChip('اليوم', Icons.today),
                    const SizedBox(width: 8),
                    _buildFilterChip('هذا الأسبوع', Icons.date_range),
                    const SizedBox(width: 8),
                    _buildFilterChip('هذا الشهر', Icons.calendar_month),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reservations List
        Expanded(
          child: !hasInitialized || isLoadingReservations
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تحميل الحجوزات...'),
                    ],
                  ),
                )
              : _getFilteredReservations(reservations).isEmpty
                  ? _buildEmptyState(title)
                  : RefreshIndicator(
                      onRefresh: () async {
                        final carWashId =
                            widget.carWashInfo['carWashId']?.toString() ?? '';
                        if (carWashId.isNotEmpty) {
                          await fetchReservations(carWashId);
                        }
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            _getFilteredReservations(reservations).length,
                        itemBuilder: (context, index) {
                          return _buildReservationCard(
                            _getFilteredReservations(reservations)[index],
                            showActions,
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
          // هنا يمكن إضافة منطق الفلترة حسب التاريخ
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد حجوزات $title',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'جرب البحث بكلمات أخرى' : '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(
    Map<String, dynamic> reservation,
    bool showActions,
  ) {
    final status = reservation['status'];
    final isPending = status == 'Pending';
    final isApproved = status == 'Approved';

    final String userName =
        reservation['user_name'] ?? reservation['name'] ?? 'غير محدد';
    final String userPhone =
        reservation['user_phone'] ?? reservation['phone'] ?? 'غير محدد';

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (isPending) {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
      statusIcon = Icons.pending_actions;
    } else if (isApproved) {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation['service_name'] ?? 'خدمة غير محددة',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#${reservation['reservation_id']}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body with Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.person, 'العميل', userName),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone, 'الهاتف', userPhone),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.directions_car,
                  'السيارة',
                  '${reservation['car_make'] ?? ''} ${reservation['car_model'] ?? ''} ${reservation['car_year'] ?? ''}',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        Icons.date_range,
                        'التاريخ',
                        reservation['date'] ?? 'غير محدد',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailRow(
                        Icons.access_time,
                        'الوقت',
                        reservation['time'] ?? 'غير محدد',
                      ),
                    ),
                  ],
                ),

                // Actions
                if (showActions && isPending) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateReservationStatus(
                            reservation['reservation_id'],
                            'Approved',
                          ),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('قبول'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateReservationStatus(
                            reservation['reservation_id'],
                            'Rejected',
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('رفض'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[700],
                            side: BorderSide(color: Colors.red[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (!isPending) ...[
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _updateReservationStatus(
                        reservation['reservation_id'],
                        'Pending',
                      ),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('إعادة لقيد الانتظار'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'غير محدد' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
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
}
