import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' show cos, sqrt, asin;
import '../../services/carwash_service.dart';
import '../../services/car_service.dart';
import '../../utils/error_handler.dart';
import '../../utils/logger.dart';
import '../../config/app_constants.dart';
import '../../config/image_config.dart';
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

class _UserHomeTabState extends State<UserHomeTab>
    with AutomaticKeepAliveClientMixin {
  final _carWashService = CarWashService();
  final _carService = CarService();

  List<Map<String, dynamic>> _carWashes = [];
  List<Map<String, dynamic>> _filteredCarWashes = [];
  List<Car> _userCars = [];

  bool _isLoading = true;
  String _searchQuery = '';
  Position? _currentPosition;
  bool _showMap = false;
  int? _selectedMarkerIndex;

  // للحفاظ على حالة الـ tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    AppLogger.info('بدء تحميل بيانات الصفحة الرئيسية');

    // تحميل متوازي للبيانات
    await Future.wait([
      _loadData(),
      _getCurrentLocation(),
    ]);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('خدمة الموقع غير مفعلة');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('تم رفض إذن الموقع');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('تم رفض إذن الموقع بشكل دائم');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _calculateDistances();
        });
        AppLogger.success('تم الحصول على الموقع الحالي');
      }
    } catch (e) {
      AppLogger.error('خطأ في الحصول على الموقع', e);
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
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // تحميل متوازي
      final results = await Future.wait([
        _carWashService.fetchCarWashes(),
        _carService.fetchUserCars(widget.userId),
      ]);

      if (!mounted) return;

      // معالجة نتائج المغاسل
      final carWashesResponse = results[0];
      if (carWashesResponse.success && carWashesResponse.data != null) {
        setState(() {
          _carWashes =
              (carWashesResponse.data! as List).cast<Map<String, dynamic>>();
          _filteredCarWashes = _carWashes;
          _calculateDistances();
          _sortCarWashes();
        });
        AppLogger.success('تم تحميل ${_carWashes.length} مغسلة');
      }

      // معالجة نتائج السيارات
      final carsResponse = results[1];
      if (carsResponse.success && carsResponse.data != null) {
        setState(() {
          _userCars = (carsResponse.data! as List).cast<Car>();
        });
        AppLogger.success('تم تحميل ${_userCars.length} سيارة');
      }
    } catch (e) {
      if (mounted) {
        AppLogger.error('خطأ في تحميل البيانات', e);
        ErrorHandler.showErrorSnackBar(context, e);
      }
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
          final location = carWash['location']?.toString().toLowerCase() ?? '';
          final q = query.toLowerCase();
          return name.contains(q) || location.contains(q);
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
        // TODO: الانتقال إلى tab السيارات
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'اختر سيارتك',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ImageConfig.buildCarIcon(size: 50),
                  title: Text(
                    '${car.selectedMake ?? 'غير محدد'} ${car.selectedModel ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'السنة: ${car.selectedYear ?? 'غير محدد'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'اللوحة: ${_formatPlate(car)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.pop(context, car),
                ),
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

  String _formatPlate(Car car) {
    final arabicLetters = car.selectedArabicLetters.join(' ');
    final latinLetters = car.selectedLatinLetters.join('');
    final numbers =
        (car.selectedArabicNumbers + car.selectedLatinNumbers).join('');
    return '$arabicLetters $latinLetters $numbers';
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
                      child: ImageConfig.buildNetworkImage(
                        imageUrl: images[index].toString(),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
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
    super.build(context); // مهم للـ AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: _showMap ? _buildMap() : _buildCarWashesList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
                  color: _showMap ? Colors.blue[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showMap ? Colors.blue : Colors.grey[300]!,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.map,
                    color: _showMap ? Colors.blue : Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _showMap = !_showMap;
                    });
                  },
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
                  Icon(Icons.location_on, size: 16, color: Colors.blue[700]),
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
    );
  }

  Widget _buildCarWashesList() {
    if (_filteredCarWashes.isEmpty) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.medium),
        itemCount: _filteredCarWashes.length,
        itemBuilder: (context, index) {
          final carWash = _filteredCarWashes[index];
          final isOpen = _isCarWashOpen(carWash);
          final distance = carWash['distance'] as double?;

          return _buildCarWashCard(carWash, isOpen, distance);
        },
      ),
    );
  }

  Widget _buildCarWashCard(
    Map<String, dynamic> carWash,
    bool isOpen,
    double? distance,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة المغسلة
            _buildCarWashImage(carWash, isOpen, distance),

            // معلومات المغسلة
            _buildCarWashInfo(carWash, isOpen),
          ],
        ),
      ),
    );
  }

  Widget _buildCarWashImage(
    Map<String, dynamic> carWash,
    bool isOpen,
    double? distance,
  ) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: ImageConfig.buildNetworkImage(
            imageUrl: carWash['profile_image'] ?? '',
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorWidget: ImageConfig.buildCarWashIcon(size: 64),
          ),
        ),
        // شارة الحالة
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                ),
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
        // المسافة
        if (distance != null)
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.near_me,
                    color: Colors.white,
                    size: 14,
                  ),
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
    );
  }

  Widget _buildCarWashInfo(Map<String, dynamic> carWash, bool isOpen) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            carWash['name'] ?? 'مغسلة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // الموقع
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  carWash['location'] ?? 'لا يوجد موقع',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ساعات العمل
          if (carWash['open_time'] != null && carWash['close_time'] != null)
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'من ${carWash['open_time']} - ${carWash['close_time']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          // الأزرار
          Row(
            children: [
              // زر الصور
              if (carWash['car_wash_images'] != null &&
                  (carWash['car_wash_images'] as List).isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: Text(
                      'صور (${(carWash['car_wash_images'] as List).length})',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _showCarWashImages(
                      carWash['car_wash_images'],
                    ),
                  ),
                ),

              const SizedBox(width: 8),

              // زر الحجز
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event_available, size: 18),
                  label: const Text(
                    'احجز الآن',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed:
                      isOpen ? () => _selectCarAndProceed(carWash) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOpen ? AppColors.primary : Colors.grey[400],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // نفس الكود من المثال السابق
    final markers = <Marker>[];

    for (int i = 0; i < _filteredCarWashes.length; i++) {
      final carWash = _filteredCarWashes[i];
      final lat = double.tryParse(carWash['latitude']?.toString() ?? '') ?? 0;
      final lng = double.tryParse(carWash['longitude']?.toString() ?? '') ?? 0;
      if (lat == 0 && lng == 0) continue;

      final point = LatLng(lat, lng);
      markers.add(
        Marker(
          point: point,
          width: 200,
          height: 100,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMarkerIndex = i;
              });
            },
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 36,
            ),
          ),
        ),
      );
    }

    if (_currentPosition != null) {
      final userPoint =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      markers.add(
        Marker(
          point: userPoint,
          width: 44,
          height: 44,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 28,
          ),
        ),
      );
    }

    LatLng center;
    if (_currentPosition != null) {
      center = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else if (markers.isNotEmpty) {
      center = markers.first.point;
    } else {
      center = const LatLng(24.7136, 46.6753);
    }

    if (markers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد مواقع لعرضها'),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 12,
          onTap: (tapPos, latLng) {
            setState(() => _selectedMarkerIndex = null);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
