import 'package:flutter/material.dart';
import '../../services/carwash_service.dart';
import '../../services/car_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../../models/Car.dart';
import '../Reservation_screen.dart';

class UserHomeTab extends StatefulWidget {
  final String userId;
  final Map<String, String> userProfile;

  const UserHomeTab({
    Key? key,
    required this.userId,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab> {
  final _carWashService = CarWashService();
  final _carService = CarService();

  List<Map<String, dynamic>> _carWashes = [];
  List<Map<String, dynamic>> _filteredCarWashes = [];
  List<Car> _userCars = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // تحميل المغاسل
      final carWashesResponse = await _carWashService.fetchCarWashes();
      if (carWashesResponse.success && carWashesResponse.data != null) {
        setState(() {
          _carWashes = carWashesResponse.data!;
          _filteredCarWashes = _carWashes;
          _sortCarWashes();
        });
      }

      // تحميل السيارات
      final carsResponse = await _carService.fetchUserCars(widget.userId);
      if (carsResponse.success && carsResponse.data != null) {
        setState(() {
          _userCars = carsResponse.data!;
        });
      }

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortCarWashes() {
    _filteredCarWashes.sort((a, b) {
      final aOpen = _isCarWashOpen(a);
      final bOpen = _isCarWashOpen(b);
      return aOpen == bOpen ? 0 : (aOpen ? -1 : 1);
    });
  }

  bool _isCarWashOpen(Map<String, dynamic> carWash) {
    final openTime = carWash['open_time']?.toString() ?? '';
    final closeTime = carWash['close_time']?.toString() ?? '';

    if (openTime.isEmpty || closeTime.isEmpty) return false;

    final now = TimeOfDay.now();
    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);

    if (close.hour < open.hour ||
        (close.hour == open.hour && close.minute < open.minute)) {
      return (now.hour > open.hour ||
              (now.hour == open.hour && now.minute >= open.minute)) ||
          (now.hour < close.hour ||
              (now.hour == close.hour && now.minute < close.minute));
    }

    return (now.hour > open.hour ||
            (now.hour == open.hour && now.minute >= open.minute)) &&
        (now.hour < close.hour ||
            (now.hour == close.hour && now.minute < close.minute));
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  void _filterCarWashes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCarWashes = _carWashes;
      } else {
        _filteredCarWashes = _carWashes.where((carWash) {
          final name = carWash['name']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase());
        }).toList();
      }
      _sortCarWashes();
    });
  }

  Future<void> _selectCarAndProceed(Map<String, dynamic> carWash) async {
    if (_userCars.isEmpty) {
      final addCar = await ErrorHandler.showConfirmDialog(
        context,
        title: 'لا توجد سيارات',
        content: 'يجب إضافة سيارة أولاً للمتابعة. هل تريد إضافة سيارة الآن؟',
        confirmText: 'إضافة سيارة',
        cancelText: 'إلغاء',
      );

      if (addCar && mounted) {
        // الانتقال إلى tab السيارات
        // يمكنك استخدام callback أو state management
      }
      return;
    }

    final selectedCar = await _showCarSelectionDialog();

    if (selectedCar != null && mounted) {
      final carData = {
        'car_id': selectedCar.carId,
        'make': selectedCar.selectedMake,
        'model': selectedCar.selectedModel,
        'year': selectedCar.selectedYear,
        'plateNumbers': selectedCar.selectedArabicNumbers +
            selectedCar.selectedLatinNumbers,
        'plateLetters': selectedCar.selectedArabicLetters +
            selectedCar.selectedLatinLetters,
      };

      await Navigator.pushNamed(
        context,
        ReservationScreen.screenRoute,
        arguments: {
          'carWashName': carWash['name'],
          'carWashId': carWash['id'],
          'car': carData,
          'userId': widget.userId,
          'name': widget.userProfile['name'],
          'phone': widget.userProfile['phone'],
          'userType': 'user',
          'duration': carWash['duration']?.toString() ?? '30',
          'capacity': carWash['capacity']?.toString() ?? '5',
        },
      );
    }
  }

  Future<Car?> _showCarSelectionDialog() async {
    return showDialog<Car>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر السيارة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _userCars.length,
            itemBuilder: (context, index) {
              final car = _userCars[index];
              return ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(
                  '${car.selectedMake ?? 'غير محدد'} ${car.selectedModel ?? ''}',
                ),
                subtitle: Text('السنة: ${car.selectedYear ?? 'غير محدد'}'),
                onTap: () => Navigator.pop(context, car),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showCarWashImages(List<dynamic> images) {
    if (images.isEmpty) {
      ErrorHandler.showInfoSnackBar(context, 'لا توجد صور متاحة');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('صور المغسلة'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                        child: Image.network(
                          images[index].toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // شريط البحث
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: TextField(
            onChanged: _filterCarWashes,
            decoration: InputDecoration(
              hintText: 'ابحث عن مغسلة...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),

        // قائمة المغاسل
        Expanded(
          child: _filteredCarWashes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        _searchQuery.isEmpty
                            ? 'لا توجد مغاسل متاحة'
                            : 'لم يتم العثور على نتائج',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium),
                    itemCount: _filteredCarWashes.length,
                    itemBuilder: (context, index) {
                      final carWash = _filteredCarWashes[index];
                      final isOpen = _isCarWashOpen(carWash);

                      return Card(
                        elevation: AppSizes.cardElevation,
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.medium),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.cardBorderRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // صورة المغسلة
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppSizes.cardBorderRadius),
                              ),
                              child: Image.network(
                                carWash['profile_image'] ?? '',
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.local_car_wash,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.medium),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // اسم المغسلة والحالة
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          carWash['name'] ?? 'مغسلة',
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
                                          color: isOpen
                                              ? Colors.green[50]
                                              : Colors.red[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOpen ? 'مفتوح' : 'مغلق',
                                          style: TextStyle(
                                            color: isOpen
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSpacing.small),

                                  // الموقع
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          carWash['location'] ?? 'لا يوجد موقع',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: AppSpacing.small),

                                  // ساعات العمل
                                  if (carWash['open_time'] != null &&
                                      carWash['close_time'] != null)
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          'من ${carWash['open_time']} إلى ${carWash['close_time']}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: AppSpacing.medium),

                                  // أزرار العمليات
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // زر الصور
                                      if (carWash['car_wash_images'] != null &&
                                          (carWash['car_wash_images'] as List)
                                              .isNotEmpty)
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.photo_library,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'الصور (${(carWash['car_wash_images'] as List).length})',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.grey[700],
                                            side: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          onPressed: () => _showCarWashImages(
                                            carWash['car_wash_images'],
                                          ),
                                        ),

                                      // زر الحجز - مُصحح
                                      SizedBox(
                                        width: 120, // عرض ثابت للزر
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                          ),
                                          label: const Text('احجز الآن'),
                                          onPressed: isOpen
                                              ? () =>
                                                  _selectCarAndProceed(carWash)
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isOpen
                                                ? AppColors.primary
                                                : Colors.grey[400],
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                Colors.grey[300],
                                            disabledForegroundColor:
                                                Colors.grey[600],
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
