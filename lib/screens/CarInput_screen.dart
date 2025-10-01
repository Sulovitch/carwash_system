import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../utils/error_handler.dart';
import '../config/app_constants.dart';

class CarInputScreen extends StatefulWidget {
  static const String routeName = 'carInputScreen';
  final String userId;

  const CarInputScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CarInputScreen> createState() => _CarInputScreenState();
}

class _CarInputScreenState extends State<CarInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carService = CarService();

  final List<String> _carMakes = [
    'تويوتا',
    'هوندا',
    'فورد',
    'شيفروليه',
    'نيسان'
  ];
  final Map<String, List<String>> _carModels = {
    'تويوتا': ['كامري', 'كورولا', 'بريوس', 'راف 4'],
    'هوندا': ['أكورد', 'سيفيك', 'CR-V', 'بايلوت'],
    'فورد': ['فوكس', 'موستنج', 'إسكيب', 'إكسبلورر'],
    'شيفروليه': ['ماليبو', 'إمبالا', 'إكوينوكس', 'تاهو'],
    'نيسان': ['ألتيما', 'سنترا', 'ماكسيما', 'روج'],
  };

  final List<String> _carYears =
      List.generate(25, (index) => (2024 - index).toString());

  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;

  // الأرقام والحروف العربية واللاتينية
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

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من اللوحة
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
      appBar: AppBar(
        title: const Text('إضافة سيارة'),
        backgroundColor: AppColors.background,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            // الصانع
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'الصانع',
                border: OutlineInputBorder(),
              ),
              value: _selectedMake,
              items: _carMakes.map((make) {
                return DropdownMenuItem(value: make, child: Text(make));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMake = value;
                  _selectedModel = null;
                });
              },
              validator: (value) => value == null ? 'يرجى اختيار الصانع' : null,
            ),
            const SizedBox(height: AppSpacing.medium),

            // الموديل
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'الموديل',
                border: OutlineInputBorder(),
              ),
              value: _selectedModel,
              items: _selectedMake == null
                  ? []
                  : _carModels[_selectedMake!]!.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
              onChanged: (value) {
                setState(() => _selectedModel = value);
              },
              validator: (value) =>
                  value == null ? 'يرجى اختيار الموديل' : null,
            ),
            const SizedBox(height: AppSpacing.medium),

            // السنة
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'السنة',
                border: OutlineInputBorder(),
              ),
              value: _selectedYear,
              items: _carYears.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedYear = value);
              },
              validator: (value) => value == null ? 'يرجى اختيار السنة' : null,
            ),
            const SizedBox(height: AppSpacing.large),

            // ملاحظة
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Text(
                'ملاحظة: إذا كان رقم اللوحة أقل من 4 أرقام، اترك الجانب الأيسر 0 (مثال: 0003 تعني 3)',
                style: TextStyle(fontSize: 14, color: Colors.blue[900]),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            // لوحة الأرقام
            const Text(
              'رقم اللوحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.medium),

            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Column(
                children: [
                  // الأرقام العربية
                  _buildNumberRow(_arabicNumbers, _selectedArabicNumbers, true),
                  const Divider(height: AppSpacing.large),

                  // الحروف العربية
                  _buildLetterRow(_arabicLetters, _selectedArabicLetters, true),
                  const SizedBox(height: AppSpacing.small),

                  // صورة السعودية
                  Image.asset('images/KSA.png', width: 40, height: 40),
                  const SizedBox(height: AppSpacing.small),

                  // الحروف اللاتينية
                  _buildLetterRow(_latinLetters, _selectedLatinLetters, false),
                  const Divider(height: AppSpacing.large),

                  // الأرقام اللاتينية
                  _buildNumberRow(_latinNumbers, _selectedLatinNumbers, false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xlarge),

            // زر الحفظ
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'حفظ السيارة',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
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
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: selected[index],
              hint: Text(isArabic ? '٠' : '0'),
              items: options.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Center(
                      child: Text(value, style: const TextStyle(fontSize: 18))),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selected[index] = value);
                _syncNumbers(index, value, isArabic);
              },
              validator: (value) => value == null ? '!' : null,
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
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: selected[index],
              hint: Text(isArabic ? 'ص' : 'X'),
              items: options.map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Center(
                      child: Text(value, style: const TextStyle(fontSize: 18))),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selected[index] = value);
                _syncLetters(index, value, isArabic);
              },
              validator: (value) => value == null ? '!' : null,
            ),
          ),
        );
      }),
    );
  }
}
