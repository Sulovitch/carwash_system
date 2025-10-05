import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../services/carwash_service.dart';
import '../../services/car_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../../models/Car.dart';
import '../Reservation_screen.dart';
import 'map_view_screen.dart';

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
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _calculateDistances();
        });
      }
    } catch (e) {
      print('خطأ في الموقع: $e');
    }
  }

  void _calculateDistances() {
    if (_currentPosition == null) return;

    for (var carWash in _carWashes) {
      final lat = double.tryParse(carWash['latitude']?.toString() ?? '0') ?? 0;
      final lng = double.tryParse(carWash['longitude']?.toString() ?? '0') ?? 0;

      if (lat != 0 && lng != 0) {
        final distance = _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );
        carWash['distance'] = distance;
      }
    }

    setState(() {
      _sortCarWashes();
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final carWashesResponse = await _carWashService.fetchCarWashes();
      if (carWashesResponse.success && carWashesResponse.data != null) {
        setState(() {
          _carWashes = carWashesResponse.data!;
          _filteredCarWashes = _carWashes;
          _calculateDistances();
          _sortCarWashes();
        });
      }

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

      if (aOpen != bOpen) {
        return aOpen ? -1 : 1;
      }

      if (_currentPosition != null &&
          a['distance'] != null &&
          b['distance'] != null) {
        return (a['distance'] as double).compareTo(b['distance'] as double);
      }

      return 0;
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

  // فتح شاشة الخريطة
  void _openMapView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapViewScreen(
          carWashes: _filteredCarWashes,
          userCars: _userCars,
          userId: widget.userId,
          userProfile: widget.userProfile,
        ),
      ),
    );
  }

  Future<void> _selectCarAndProceed(Map<String, dynamic> carWash) async {
    if (_userCars.isEmpty) {
      await ErrorHandler.showConfirmDialog(
        context,
        title: 'لا توجد سيارات',
        content: 'يجب إضافة سيارة أولاً للمتابعة. هل تريد إضافة سيارة الآن؟',
        confirmText: 'إضافة سيارة',
        cancelText: 'إلغاء',
      );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('اختر سيارتك',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _userCars.length,
              itemBuilder: (context, index) {
                final car = _userCars[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.directions_car,
                          color: Colors.blue, size: 28),
                    ),
                    title: Text(
                      '${car.selectedMake ?? 'غير محدد'} ${car.selectedModel ?? ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('السنة: ${car.selectedYear ?? 'غير محدد'}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pop(context, car),
                  ),
                );
              },
            ),
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
        // شريط البحث والخريطة
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: _filterCarWashes,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن مغسلة...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadius),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: _openMapView,
                      tooltip: 'عرض الخريطة',
                    ),
                  ),
                ],
              ),
              if (_currentPosition != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'موقعك الحالي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: _filteredCarWashes.length,
                    itemBuilder: (context, index) {
                      final carWash = _filteredCarWashes[index];
                      final isOpen = _isCarWashOpen(carWash);
                      final distance = carWash['distance'] as double?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    child: Image.network(
                                      carWash['profile_image'] ?? '',
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 180,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue[100]!,
                                                Colors.blue[300]!
                                              ],
                                            ),
                                          ),
                                          child: const Icon(
                                              Icons.local_car_wash,
                                              size: 64,
                                              color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            isOpen ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isOpen ? 'مفتوح' : 'مغلق',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (distance != null)
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.near_me,
                                                color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${distance.toStringAsFixed(1)} كم',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      carWash['name'] ?? 'مغسلة',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            carWash['location'] ??
                                                'لا يوجد موقع',
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (carWash['open_time'] != null &&
                                        carWash['close_time'] != null)
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'من ${carWash['open_time']} - ${carWash['close_time']}',
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        if (carWash['car_wash_images'] !=
                                                null &&
                                            (carWash['car_wash_images'] as List)
                                                .isNotEmpty)
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(
                                                  Icons.photo_library,
                                                  size: 18),
                                              label: Text(
                                                'صور (${(carWash['car_wash_images'] as List).length})',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey[700],
                                                side: BorderSide(
                                                    color: Colors.grey[300]!),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                              onPressed: () =>
                                                  _showCarWashImages(carWash[
                                                      'car_wash_images']),
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                                Icons.event_available,
                                                size: 18),
                                            label: const Text('احجز الآن',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            onPressed: isOpen
                                                ? () => _selectCarAndProceed(
                                                    carWash)
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
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
