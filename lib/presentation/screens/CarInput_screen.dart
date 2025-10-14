import 'package:app/models/Car.dart';
import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../utils/error_handler.dart';
import '../config/app_constants.dart';

class CarInputScreen extends StatefulWidget {
  static const String routeName = 'carInputScreen';
  final String userId;
  final Car? existingCar; // للتعديل

  const CarInputScreen({
    Key? key,
    required this.userId,
    this.existingCar,
  }) : super(key: key);

  @override
  State<CarInputScreen> createState() => _CarInputScreenState();
}

class _CarInputScreenState extends State<CarInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carService = CarService();
  final PageController _pageController = PageController();

  int _currentStep = 0;

  // قوائم البيانات
  final List<String> _carMakes = [
    'تويوتا',
    'هوندا',
    'فورد',
    'شيفروليه',
    'نيسان',
    'هيونداي',
    'كيا',
    'مازدا',
    'جيب',
    'لكزس',
    'مرسيدس',
    'BMW',
    'أودي'
  ];

  final Map<String, List<String>> _carModels = {
    'تويوتا': [
      'كامري',
      'كورولا',
      'بريوس',
      'راف 4',
      'هايلكس',
      'لاند كروزر',
      'يارس',
      'افالون'
    ],
    'هوندا': ['أكورد', 'سيفيك', 'CR-V', 'بايلوت', 'HR-V', 'أوديسي'],
    'فورد': ['فوكس', 'موستنج', 'إسكيب', 'إكسبلورر', 'F-150', 'إيدج'],
    'شيفروليه': ['ماليبو', 'إمبالا', 'إكوينوكس', 'تاهو', 'سيلفرادو', 'كامارو'],
    'نيسان': ['ألتيما', 'سنترا', 'ماكسيما', 'روج', 'باترول', 'اكستريل'],
    'هيونداي': ['النترا', 'سوناتا', 'توسان', 'سانتافي', 'كونا', 'أزيرا'],
    'كيا': ['اوبتيما', 'سيراتو', 'سبورتاج', 'سورينتو', 'كادينزا', 'سيلتوس'],
    'مازدا': ['مازدا 3', 'مازدا 6', 'CX-5', 'CX-9', 'CX-3'],
    'جيب': ['رانجلر', 'جراند شيروكي', 'شيروكي', 'كومباس', 'رينيجيد'],
    'لكزس': ['ES', 'IS', 'RX', 'LX', 'NX', 'GX'],
    'مرسيدس': ['C-Class', 'E-Class', 'S-Class', 'GLA', 'GLC', 'GLE'],
    'BMW': ['سلسلة 3', 'سلسلة 5', 'سلسلة 7', 'X3', 'X5', 'X7'],
    'أودي': ['A3', 'A4', 'A6', 'Q3', 'Q5', 'Q7'],
  };

  final List<String> _carYears =
      List.generate(30, (index) => (2024 - index).toString());

  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;

  final List<String> _arabicNumbers = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩'
  ];
  final List<String> _latinNumbers = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9'
  ];
  final List<String> _arabicLetters = [
    'ا',
    'ب',
    'ح',
    'د',
    'ر',
    'س',
    'ص',
    'ط',
    'ع',
    'ق',
    'ك',
    'ل',
    'م',
    'ن',
    'هـ',
    'و',
    'ى'
  ];
  final List<String> _latinLetters = [
    'A',
    'B',
    'J',
    'D',
    'R',
    'S',
    'X',
    'T',
    'E',
    'G',
    'K',
    'L',
    'Z',
    'N',
    'H',
    'U',
    'V'
  ];

  List<String?> _selectedArabicNumbers = List.filled(4, null);
  List<String?> _selectedLatinNumbers = List.filled(4, null);
  List<String?> _selectedArabicLetters = List.filled(3, null);
  List<String?> _selectedLatinLetters = List.filled(3, null);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCarData();
  }

  void _loadExistingCarData() {
    if (widget.existingCar != null) {
      final car = widget.existingCar!;

      setState(() {
        // تحميل معلومات السيارة
        _selectedMake = car.selectedMake;
        _selectedModel = car.selectedModel;
        _selectedYear = car.selectedYear;

        // تحميل الأرقام
        _selectedArabicNumbers = List.from(car.selectedArabicNumbers);
        _selectedLatinNumbers = List.from(car.selectedLatinNumbers);

        // تحميل الحروف
        _selectedArabicLetters = List.from(car.selectedArabicLetters);
        _selectedLatinLetters = List.from(car.selectedLatinLetters);

        // التأكد من أن القوائم بالحجم الصحيح
        while (_selectedArabicNumbers.length < 4)
          _selectedArabicNumbers.add(null);
        while (_selectedLatinNumbers.length < 4)
          _selectedLatinNumbers.add(null);
        while (_selectedArabicLetters.length < 3)
          _selectedArabicLetters.add(null);
        while (_selectedLatinLetters.length < 3)
          _selectedLatinLetters.add(null);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_selectedMake == null ||
          _selectedModel == null ||
          _selectedYear == null) {
        ErrorHandler.showErrorSnackBar(
            context, 'يرجى اختيار جميع معلومات السيارة');
        return;
      }
    }

    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _saveCar();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveCar() async {
    final plateNumbers = (_selectedArabicNumbers + _selectedLatinNumbers)
        .whereType<String>()
        .join();
    final plateLetters = (_selectedArabicLetters + _selectedLatinLetters)
        .whereType<String>()
        .join();

    if (plateNumbers.length != 8 || plateLetters.length != 6) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى إكمال رقم اللوحة بالكامل');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // تحديد ما إذا كنا نعدل أو نضيف سيارة جديدة
      final isEditing = widget.existingCar != null;

      if (isEditing) {
        // استدعاء API التعديل
        final response = await _carService.updateCar(
          carId: widget.existingCar!.carId,
          make: _selectedMake!,
          model: _selectedModel!,
          year: _selectedYear!,
          plateNumbers: plateNumbers,
          plateLetters: plateLetters,
        );

        if (!mounted) return;

        if (response.success) {
          ErrorHandler.showSuccessSnackBar(context, 'تم تحديث السيارة بنجاح');

          Navigator.pop(context, {
            'car_id': widget.existingCar!.carId,
            'make': _selectedMake,
            'model': _selectedModel,
            'year': _selectedYear,
            'plateNumbers': _selectedArabicNumbers + _selectedLatinNumbers,
            'plateLetters': _selectedArabicLetters + _selectedLatinLetters,
            'updated': true,
          });
        } else {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      } else {
        // إضافة سيارة جديدة
        final response = await _carService.addCar(
          userId: widget.userId,
          make: _selectedMake!,
          model: _selectedModel!,
          year: _selectedYear!,
          plateNumbers: plateNumbers,
          plateLetters: plateLetters,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          ErrorHandler.showSuccessSnackBar(context, 'تم إضافة السيارة بنجاح');

          Navigator.pop(context, {
            'car_id': response.data,
            'make': _selectedMake,
            'model': _selectedModel,
            'year': _selectedYear,
            'plateNumbers': _selectedArabicNumbers + _selectedLatinNumbers,
            'plateLetters': _selectedArabicLetters + _selectedLatinLetters,
          });
        } else {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _syncNumbers(int index, String? value, bool isArabic) {
    if (value == null) return;

    if (isArabic) {
      final latinIndex = _arabicNumbers.indexOf(value);
      if (latinIndex != -1) {
        setState(() {
          _selectedLatinNumbers[index] = _latinNumbers[latinIndex];
        });
      }
    } else {
      final arabicIndex = _latinNumbers.indexOf(value);
      if (arabicIndex != -1) {
        setState(() {
          _selectedArabicNumbers[index] = _arabicNumbers[arabicIndex];
        });
      }
    }
  }

  void _syncLetters(int index, String? value, bool isArabic) {
    if (value == null) return;

    if (isArabic) {
      final latinIndex = _arabicLetters.indexOf(value);
      if (latinIndex != -1) {
        setState(() {
          _selectedLatinLetters[index] = _latinLetters[latinIndex];
        });
      }
    } else {
      final arabicIndex = _latinLetters.indexOf(value);
      if (arabicIndex != -1) {
        setState(() {
          _selectedArabicLetters[index] = _arabicLetters[arabicIndex];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
            widget.existingCar != null ? 'تعديل السيارة' : 'إضافة سيارة جديدة'),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildProgressIndicator(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCarInfoStep(),
                  _buildPlateNumberStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepIndicator(0, 'معلومات السيارة', Icons.directions_car),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > 0 ? AppColors.primary : Colors.grey[300],
            ),
          ),
          _buildStepIndicator(1, 'رقم اللوحة', Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCarInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خطوة 1 من 2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'أدخل معلومات سيارتك',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // الصانع
          _buildSectionTitle('الصانع'),
          const SizedBox(height: 12),
          _buildDropdownCard(
            value: _selectedMake,
            hint: 'اختر الصانع',
            icon: Icons.business,
            items: _carMakes,
            onChanged: (value) {
              setState(() {
                _selectedMake = value;
                _selectedModel = null;
              });
            },
          ),
          const SizedBox(height: 20),

          // الموديل
          _buildSectionTitle('الموديل'),
          const SizedBox(height: 12),
          _buildDropdownCard(
            value: _selectedModel,
            hint: _selectedMake == null ? 'اختر الصانع أولاً' : 'اختر الموديل',
            icon: Icons.car_repair,
            items: _selectedMake == null ? [] : _carModels[_selectedMake!]!,
            onChanged: _selectedMake == null
                ? null
                : (value) {
                    setState(() => _selectedModel = value);
                  },
          ),
          const SizedBox(height: 20),

          // السنة
          _buildSectionTitle('سنة الصنع'),
          const SizedBox(height: 12),
          _buildDropdownCard(
            value: _selectedYear,
            hint: 'اختر السنة',
            icon: Icons.calendar_today,
            items: _carYears,
            onChanged: (value) {
              setState(() => _selectedYear = value);
            },
          ),

          const SizedBox(height: 32),

          // معاينة البيانات المدخلة
          if (_selectedMake != null &&
              _selectedModel != null &&
              _selectedYear != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
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
                      Icon(Icons.preview, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'معاينة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_car,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_selectedMake $_selectedModel',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'سنة الصنع: $_selectedYear',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
  }

  Widget _buildPlateNumberStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.1), Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.credit_card,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خطوة 2 من 2',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'أدخل رقم اللوحة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ملاحظة مهمة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.amber[800], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'إذا كان رقم اللوحة أقل من 4 أرقام، اترك الأرقام الأولى كصفر (مثال: 0003 تعني 3)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // لوحة الأرقام السعودية
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // الأرقام العربية
                _buildNumberRow(_arabicNumbers, _selectedArabicNumbers, true),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 16),

                // الحروف العربية
                _buildLetterRow(_arabicLetters, _selectedArabicLetters, true),
                const SizedBox(height: 12),

                // شعار السعودية
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Image.asset(
                    'images/KSA.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.flag, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // الحروف اللاتينية
                _buildLetterRow(_latinLetters, _selectedLatinLetters, false),
                const SizedBox(height: 16),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 16),

                // الأرقام اللاتينية
                _buildNumberRow(_latinNumbers, _selectedLatinNumbers, false),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // معاينة اللوحة
          if (_isPlateComplete())
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.teal[50]!],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'اللوحة مكتملة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getPlatePreview(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDropdownCard({
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        value: value,
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'يرجى الاختيار' : null,
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      ),
    );
  }

  Widget _buildNumberRow(
      List<String> options, List<String?> selected, bool isArabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color:
                    selected[index] != null ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected[index] != null
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: selected[index] != null ? 2 : 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected[index],
                  hint: Center(
                    child: Text(
                      isArabic ? '٠' : '0',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  isExpanded: true,
                  items: options.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Center(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selected[index] = value);
                    _syncNumbers(index, value, isArabic);
                  },
                  icon: const SizedBox.shrink(),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLetterRow(
      List<String> options, List<String?> selected, bool isArabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color:
                    selected[index] != null ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected[index] != null
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: selected[index] != null ? 2 : 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected[index],
                  hint: Center(
                    child: Text(
                      isArabic ? 'ص' : 'X',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  isExpanded: true,
                  items: options.map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Center(
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selected[index] = value);
                    _syncLetters(index, value, isArabic);
                  },
                  icon: const SizedBox.shrink(),
                  dropdownColor: Colors.white,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_back, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'السابق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 1
                                ? (widget.existingCar != null
                                    ? 'تحديث السيارة'
                                    : 'حفظ السيارة')
                                : 'التالي',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 1
                                ? Icons.check
                                : Icons.arrow_forward,
                            size: 20,
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

  bool _isPlateComplete() {
    final numbersComplete = _selectedArabicNumbers.every((n) => n != null) &&
        _selectedLatinNumbers.every((n) => n != null);
    final lettersComplete = _selectedArabicLetters.every((l) => l != null) &&
        _selectedLatinLetters.every((l) => l != null);
    return numbersComplete && lettersComplete;
  }

  String _getPlatePreview() {
    final arabicNumbers = _selectedArabicNumbers.join('');
    final latinNumbers = _selectedLatinNumbers.join('');
    final arabicLetters = _selectedArabicLetters.join(' ');
    final latinLetters = _selectedLatinLetters.join('');

    return '$arabicNumbers $latinNumbers | $arabicLetters $latinLetters';
  }
}
