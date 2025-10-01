import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/service_service.dart';
import '../services/reservation_service.dart';
import '../utils/error_handler.dart';
import '../config/app_constants.dart';
import '../models/Service.dart';
import 'PaymentScreen.dart';

class ReservationScreen extends StatefulWidget {
  static const String screenRoute = 'Reservation_screen';

  const ReservationScreen({Key? key}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _serviceService = ServiceService();
  final _reservationService = ReservationService();

  Service? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<Service> _services = [];
  bool _isLoadingServices = false;
  bool _isSubmitting = false;
  bool _hasInitialized = false;

  String _carWashName = '';
  int _carWashId = 0;
  String _userName = '';
  String _userPhone = '';
  Map<String, dynamic> _selectedCar = {};
  String _userId = '';
  int _duration = 30;

  // منع النقرات المتكررة
  DateTime? _lastClickTime;

  @override
  void initState() {
    super.initState();
    // تأجيل العمليات الثقيلة لما بعد بناء الواجهة
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    if (!mounted || _hasInitialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      setState(() {
        _carWashName = args['carWashName'] ?? 'مغسلة';
        _carWashId = int.tryParse(args['carWashId']?.toString() ?? '0') ?? 0;
        _userName = args['name'] ?? 'مستخدم';
        _userPhone = args['phone'] ?? '';
        _selectedCar = args['car'] as Map<String, dynamic>? ?? {};
        _userId = args['userId']?.toString() ?? '';
        _duration = int.tryParse(args['duration']?.toString() ?? '30') ?? 30;
        _hasInitialized = true;
      });

      if (_carWashId > 0) {
        _loadServices();
      }
    }
  }

  @override
  void dispose() {
    // تنظيف الموارد
    _services.clear();
    super.dispose();
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

  Future<void> _loadServices() async {
    if (!mounted || _isLoadingServices) return;

    setState(() => _isLoadingServices = true);

    try {
      final response =
          await _serviceService.fetchServices(_carWashId.toString()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _services = response.data!;
          _isLoadingServices = false;
        });
      } else {
        setState(() => _isLoadingServices = false);
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            response.message ?? 'حدث خطأ في تحميل الخدمات',
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingServices = false);
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في تحميل الخدمات: ${e.toString()}',
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF370175),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  List<TimeOfDay> _getAvailableTimeSlots() {
    if (_selectedDate == null) return [];

    final List<TimeOfDay> slots = [];
    final now = DateTime.now();
    final isToday = _selectedDate!.day == now.day &&
        _selectedDate!.month == now.month &&
        _selectedDate!.year == now.year;

    // حساب ساعة البداية
    int startHour;
    int startMinute = 0;

    if (isToday) {
      startHour = now.hour;
      startMinute = ((now.minute ~/ _duration) + 1) * _duration;
      if (startMinute >= 60) {
        startHour++;
        startMinute = 0;
      }
    } else {
      startHour = 8;
    }

    // توليد الفترات الزمنية بكفاءة
    for (int hour = startHour; hour < 22; hour++) {
      int minuteStart = (hour == startHour) ? startMinute : 0;
      for (int minute = minuteStart; minute < 60; minute += _duration) {
        slots.add(TimeOfDay(hour: hour, minute: minute));

        // تحديد عدد الفترات لتجنب الحمل الزائد
        if (slots.length >= 50) break;
      }
      if (slots.length >= 50) break;
    }

    return slots;
  }

  Future<void> _submitReservation() async {
    if (_isDoubleClick() || _isSubmitting) return;

    if (_selectedService == null) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى اختيار الخدمة');
      return;
    }

    if (_selectedDate == null) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى اختيار التاريخ');
      return;
    }

    if (_selectedTime == null) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى اختيار الوقت');
      return;
    }

    // الانتقال لشاشة الدفع
    final paymentSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: _selectedService!.price,
        ),
      ),
    );

    if (paymentSuccess != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      final response = await _reservationService
          .saveReservation(
        userId: _userId,
        carId: _selectedCar['car_id']?.toString() ?? '',
        serviceId: _selectedService!.id.toString(),
        date: formattedDate,
        time: formattedTime,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('انتهت مهلة الاتصال');
        },
      );

      if (!mounted) return;

      if (response.success) {
        ErrorHandler.showSuccessSnackBar(context, 'تم تأكيد الحجز بنجاح');

        final reservationData = {
          'user_id': _userId,
          'car_id': _selectedCar['car_id'],
          'service_id': _selectedService!.id,
          'service_name': _selectedService!.name,
          'car_make': _selectedCar['make'],
          'car_model': _selectedCar['model'],
          'car_year': _selectedCar['year'],
          'date': formattedDate,
          'time': formattedTime,
          'status': 'Pending',
        };

        if (mounted) {
          Navigator.pop(context, reservationData);
        }
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          response.message ?? 'فشل تأكيد الحجز',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في تأكيد الحجز: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('جاري التحميل...'),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_selectedService == null) {
      return _buildServiceSelection();
    } else {
      return _buildReservationDetails();
    }
  }

  Widget _buildServiceSelection() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الخدمة'),
        backgroundColor: AppColors.background,
        elevation: 1,
      ),
      body: _isLoadingServices
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        'لا توجد خدمات متاحة',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      ElevatedButton.icon(
                        onPressed: _loadServices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServices,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: AppSpacing.medium,
                      mainAxisSpacing: AppSpacing.medium,
                    ),
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return _buildServiceCard(service);
                    },
                  ),
                ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      elevation: AppSizes.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          if (!_isDoubleClick()) {
            setState(() {
              _selectedService = service;
            });
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardBorderRadius),
                ),
                child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                        memCacheWidth: 300,
                        memCacheHeight: 300,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.build, size: 50),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${service.price.toStringAsFixed(2)} ريال',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetails() {
    final availableSlots = _getAvailableTimeSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الحجز'),
        backgroundColor: AppColors.background,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (!_isDoubleClick()) {
              setState(() {
                _selectedService = null;
                _selectedDate = null;
                _selectedTime = null;
              });
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة معلومات الحجز
            Card(
              elevation: AppSizes.cardElevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        Icons.local_car_wash, 'المغسلة', _carWashName),
                    _buildInfoRow(Icons.person, 'الاسم', _userName),
                    _buildInfoRow(Icons.phone, 'الجوال', _userPhone),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.directions_car,
                      'السيارة',
                      '${_selectedCar['make'] ?? ''} ${_selectedCar['model'] ?? ''} (${_selectedCar['year'] ?? ''})',
                    ),
                    _buildInfoRow(
                      Icons.build_circle,
                      'الخدمة',
                      '${_selectedService!.name} - ${_selectedService!.price} ريال',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.large),

            // زر اختيار التاريخ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF370175),
                  minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: Text(
                  _selectedDate == null
                      ? 'اختر التاريخ'
                      : 'التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            // قسم اختيار الوقت
            if (_selectedDate != null) ...[
              const SizedBox(height: AppSpacing.large),
              const Text(
                'اختر الوقت:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.medium),
              if (availableSlots.isEmpty)
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: const Text(
                    'لا توجد أوقات متاحة في هذا التاريخ',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    itemCount: availableSlots.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final time = availableSlots[index];
                      final isSelected = _selectedTime == time;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!_isDoubleClick()) {
                              setState(() => _selectedTime = time);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.large,
                              vertical: AppSpacing.medium,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.success
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.success
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  time.format(context),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const Spacer(),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: AppSpacing.xlarge),

            // زر تأكيد الحجز
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedDate != null &&
                        _selectedTime != null &&
                        !_isSubmitting)
                    ? _submitReservation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'تأكيد الحجز',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
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
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
