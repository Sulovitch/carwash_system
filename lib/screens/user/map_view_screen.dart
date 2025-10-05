import 'package:app/config/app_constants.dart';
import 'package:app/models/Car.dart';
import 'package:app/screens/Reservation_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carWashes;
  final List<Car> userCars;
  final String userId;
  final Map<String, String> userProfile;

  const MapViewScreen({
    Key? key,
    required this.carWashes,
    required this.userCars,
    required this.userId,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  int? _selectedMarkerIndex;
  bool _showSidebar = true;
  bool _isLoadingLocation = true;
  bool _isLoadingRoute = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _routeAnimationController;
  late Animation<double> _routeAnimation;
  double _sidebarWidth = 0.85;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _routeAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _routeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _routeAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
      if (_showSidebar) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  void _onMarkerTap(int index, double lat, double lng) async {
    setState(() {
      _selectedMarkerIndex = index;
      _sidebarWidth = 0.35;
      _isLoadingRoute = true;
      _routePoints = [];
    });

    if (_currentPosition != null) {
      await _fetchRoute(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
    }

    if (_currentPosition != null) {
      final bounds = LatLngBounds.fromPoints([
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(lat, lng),
      ]);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * _sidebarWidth + 50,
            right: 50,
            top: 100,
            bottom: 150,
          ),
        ),
      );
    }
  }

  Future<void> _fetchRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;

        final points = coordinates.map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();

        setState(() {
          _routePoints = points;
          _isLoadingRoute = false;
        });

        _routeAnimationController.forward(from: 0.0);
      }
    } catch (e) {
      print('خطأ في جلب الطريق: $e');
      setState(() {
        _routePoints = [
          LatLng(startLat, startLng),
          LatLng(endLat, endLng),
        ];
        _isLoadingRoute = false;
      });
      _routeAnimationController.forward(from: 0.0);
    }
  }

  void _resetSelection() {
    setState(() {
      _selectedMarkerIndex = null;
      _sidebarWidth = 0.85;
      _routePoints = [];
    });
    _routeAnimationController.reset();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  List<Map<String, dynamic>> _getSortedCarWashes() {
    final List<Map<String, dynamic>> sorted = List.from(widget.carWashes);

    if (_currentPosition != null) {
      for (var carWash in sorted) {
        final lat =
            double.tryParse(carWash['latitude']?.toString() ?? '0') ?? 0;
        final lng =
            double.tryParse(carWash['longitude']?.toString() ?? '0') ?? 0;
        if (lat != 0 && lng != 0) {
          carWash['distance'] = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );
        }
      }

      sorted.sort((a, b) {
        final distA = a['distance'] as double? ?? double.infinity;
        final distB = b['distance'] as double? ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return sorted;
  }

  Future<void> _selectCarAndProceed(Map<String, dynamic> carWash) async {
    if (widget.userCars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة سيارة أولاً')),
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
        title: const Text('اختر سيارتك'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.userCars.length,
              itemBuilder: (context, index) {
                final car = widget.userCars[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading:
                        const Icon(Icons.directions_car, color: Colors.blue),
                    title: Text('${car.selectedMake} ${car.selectedModel}'),
                    subtitle: Text('${car.selectedYear}'),
                    onTap: () => Navigator.pop(context, car),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedCarWashes = _getSortedCarWashes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة المغاسل'),
        backgroundColor: AppColors.background,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(24.7136, 46.6753),
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app',
              ),
              if (_routePoints.isNotEmpty && _selectedMarkerIndex != null)
                AnimatedBuilder(
                  animation: _routeAnimation,
                  builder: (context, child) {
                    final pointsToShow =
                        (_routePoints.length * _routeAnimation.value).round();
                    final animatedPoints = _routePoints
                        .take(pointsToShow.clamp(2, _routePoints.length))
                        .toList();

                    if (animatedPoints.length < 2) {
                      return const SizedBox.shrink();
                    }

                    final glowValue =
                        (1 + math.sin(_routeAnimation.value * 6.28)) / 2;

                    return Stack(
                      children: [
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: animatedPoints,
                              strokeWidth: 18,
                              color: AppColors.primary
                                  .withOpacity(0.1 + (glowValue * 0.15)),
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: animatedPoints,
                              strokeWidth: 14,
                              color: AppColors.primary
                                  .withOpacity(0.2 + (glowValue * 0.2)),
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: animatedPoints,
                              strokeWidth: 10,
                              color: AppColors.primary
                                  .withOpacity(0.1 + (glowValue * 0.25)),
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: animatedPoints,
                              strokeWidth: 7,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: animatedPoints,
                              strokeWidth: 5,
                              gradientColors: [
                                Colors.blue.shade600,
                                AppColors.primary,
                                Colors.blue.shade400,
                              ],
                            ),
                          ],
                        ),
                        if (_routeAnimation.value == 1.0)
                          ...List.generate(5, (i) {
                            final progress = ((glowValue + (i * 0.2)) % 1.0);
                            final pointIndex =
                                (animatedPoints.length * progress).floor();
                            if (pointIndex >= animatedPoints.length)
                              return const SizedBox.shrink();

                            return MarkerLayer(
                              markers: [
                                Marker(
                                  point: animatedPoints[pointIndex],
                                  width: 12,
                                  height: 12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                      ],
                    );
                  },
                ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      width: 80,
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'أنت هنا',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.my_location,
                              color: Colors.blue, size: 32),
                        ],
                      ),
                    ),
                  ...sortedCarWashes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final carWash = entry.value;
                    final lat = double.tryParse(
                            carWash['latitude']?.toString() ?? '0') ??
                        0;
                    final lng = double.tryParse(
                            carWash['longitude']?.toString() ?? '0') ??
                        0;

                    if (lat == 0 || lng == 0) return null;

                    final isSelected = _selectedMarkerIndex == index;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: isSelected ? 200 : 50,
                      height: isSelected ? 120 : 50,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(index, lat, lng),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Flexible(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 80),
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        carWash['name'] ?? 'مغسلة',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (carWash['distance'] != null)
                                        Text(
                                          '${(carWash['distance'] as double).toStringAsFixed(1)} كم',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              padding: EdgeInsets.all(isSelected ? 12 : 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_car_wash,
                                color: Colors.white,
                                size: isSelected ? 24 : 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>(),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: MediaQuery.of(context).size.width * _sidebarWidth,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.9),
                            Colors.blue.shade800.withOpacity(0.9)
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المغاسل القريبة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22, // من 20 إلى 22
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${sortedCarWashes.length} مغسلة متاحة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15, // من 14 إلى 15
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: sortedCarWashes.length,
                        itemBuilder: (context, index) {
                          final carWash = sortedCarWashes[index];
                          final distance = carWash['distance'] as double?;
                          final isSelected = _selectedMarkerIndex == index;
                          final openTime =
                              carWash['open_time']?.toString() ?? '';
                          final closeTime =
                              carWash['close_time']?.toString() ?? '';
                          final location =
                              carWash['location']?.toString() ?? 'لا يوجد موقع';
                          final profileImage =
                              carWash['profile_image']?.toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: isSelected ? 6 : 3,
                            color: isSelected
                                ? Colors.blue.shade50.withOpacity(0.80)
                                : Colors.white.withOpacity(0.40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: isSelected
                                  ? BorderSide(
                                      color: AppColors.primary, width: 2.5)
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              onTap: () {
                                final lat = double.tryParse(
                                        carWash['latitude']?.toString() ??
                                            '0') ??
                                    0;
                                final lng = double.tryParse(
                                        carWash['longitude']?.toString() ??
                                            '0') ??
                                    0;
                                if (lat != 0 && lng != 0) {
                                  _onMarkerTap(index, lat, lng);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (profileImage != null &&
                                      profileImage.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        profileImage,
                                        width: double.infinity,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 80,
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
                                              size: 36,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          carWash['name'] ?? 'مغسلة',
                                          style: TextStyle(
                                            fontSize:
                                                _sidebarWidth > 0.5 ? 18 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (distance != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.near_me,
                                                  size: 13,
                                                  color: Colors.blue.shade700),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  '${distance.toStringAsFixed(1)} كم',
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (_sidebarWidth > 0.5) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.location_on,
                                                  size: 13,
                                                  color: Colors.grey.shade700),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  location,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade900,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          if (openTime.isNotEmpty &&
                                              closeTime.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.access_time,
                                                    size: 13,
                                                    color:
                                                        Colors.grey.shade700),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    'من $openTime - $closeTime',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade900,
                                                      fontSize: 12,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _showSidebar
                ? (MediaQuery.of(context).size.width * _sidebarWidth) - 20
                : 0,
            top: MediaQuery.of(context).size.height / 2 - 40,
            child: GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                width: 40,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.4),
                  borderRadius: BorderRadius.only(
                    topRight:
                        _showSidebar ? Radius.zero : const Radius.circular(12),
                    bottomRight:
                        _showSidebar ? Radius.zero : const Radius.circular(12),
                    topLeft:
                        _showSidebar ? const Radius.circular(12) : Radius.zero,
                    bottomLeft:
                        _showSidebar ? const Radius.circular(12) : Radius.zero,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _showSidebar
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          if (_selectedMarkerIndex != null && !_isLoadingRoute)
            Positioned(
              bottom: 20,
              left: _showSidebar
                  ? (MediaQuery.of(context).size.width * _sidebarWidth) + 20
                  : 20,
              right: 20,
              child: SafeArea(
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 70,
                      minHeight: 60,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          Colors.blue.shade600,
                          Colors.blue.shade700
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final selectedCarWash =
                              _getSortedCarWashes()[_selectedMarkerIndex!];
                          _selectCarAndProceed(selectedCarWash);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_available,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'احجز هذه المغسلة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedMarkerIndex != null)
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _resetSelection,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: AppColors.primary, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'إلغاء',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
