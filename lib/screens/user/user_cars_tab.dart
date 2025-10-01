import 'package:flutter/material.dart';
import '../../services/car_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../../models/Car.dart';
import '../CarInput_screen.dart';

class UserCarsTab extends StatefulWidget {
  final String userId;

  const UserCarsTab({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserCarsTab> createState() => _UserCarsTabState();
}

class _UserCarsTabState extends State<UserCarsTab> {
  final _carService = CarService();
  List<Car> _cars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() => _isLoading = true);

    try {
      final response = await _carService.fetchUserCars(widget.userId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _cars = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (response.message != null) {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _navigateToAddCar() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarInputScreen(userId: widget.userId),
      ),
    );

    if (result != null && mounted) {
      _loadCars();
    }
  }

  Future<void> _deleteCar(int index) async {
    final car = _cars[index];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'حذف السيارة',
      content:
          'هل أنت متأكد من حذف هذه السيارة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'نعم، حذف',
      cancelText: 'إلغاء',
    );

    if (!confirm) return;

    try {
      final response = await _carService.deleteCar(car.carId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _cars.removeAt(index);
        });
        ErrorHandler.showSuccessSnackBar(context, 'تم حذف السيارة بنجاح');
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  String _formatPlate(Car car) {
    final arabicLetters = car.selectedArabicLetters.join(' ');
    final latinLetters = car.selectedLatinLetters.join('');
    final arabicNumbers = car.selectedArabicNumbers.join('');
    final latinNumbers = car.selectedLatinNumbers.join('');

    return '$arabicLetters | $latinLetters | $arabicNumbers$latinNumbers';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // زر إضافة سيارة
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToAddCar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'إضافة سيارة جديدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        // قائمة السيارات
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cars.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'لا توجد سيارات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'أضف سيارتك الأولى للبدء',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCars,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        itemCount: _cars.length,
                        itemBuilder: (context, index) {
                          final car = _cars[index];

                          return Card(
                            elevation: AppSizes.cardElevation,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.medium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardBorderRadius,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.medium),
                              child: Row(
                                children: [
                                  // أيقونة السيارة
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.medium),

                                  // معلومات السيارة
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${car.selectedMake ?? 'غير محدد'} ${car.selectedModel ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'السنة: ${car.selectedYear ?? 'غير محدد'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'اللوحة: ${_formatPlate(car)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // أزرار التحكم
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: AppColors.info,
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CarInputScreen(
                                                userId: widget.userId,
                                                // يمكنك تمرير بيانات السيارة للتعديل
                                              ),
                                            ),
                                          );

                                          if (result != null && mounted) {
                                            _loadCars();
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => _deleteCar(index),
                                      ),
                                    ],
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
