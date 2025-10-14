import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../data/services/carwash_service.dart';
import '../../core/utils/error_handler.dart';
import '../../core/constants/app_constants.dart';
import 'Owner_screen.dart';

class CarWashScreen extends StatefulWidget {
  static const String routeName = 'carWashScreen';

  final String ownerId;
  final Map<String, String> initialCarWashInfo;
  final List<String> initialImages;

  const CarWashScreen({
    Key? key,
    required this.ownerId,
    required this.initialCarWashInfo,
    required this.initialImages,
  }) : super(key: key);

  @override
  State<CarWashScreen> createState() => _CarWashScreenState();
}

class _CarWashScreenState extends State<CarWashScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carWashService = CarWashService();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _openTimeController;
  late TextEditingController _closeTimeController;
  late TextEditingController _durationController;
  late TextEditingController _capacityController;

  File? _profileImage;
  List<File> _carWashImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.initialCarWashInfo['name'],
    );
    _locationController = TextEditingController(
      text: widget.initialCarWashInfo['location'],
    );
    _phoneController = TextEditingController(
      text: widget.initialCarWashInfo['phone'],
    );
    _openTimeController = TextEditingController(
      text: widget.initialCarWashInfo['openTime'] ?? '08:00',
    );
    _closeTimeController = TextEditingController(
      text: widget.initialCarWashInfo['closeTime'] ?? '22:00',
    );
    _durationController = TextEditingController(
      text: widget.initialCarWashInfo['duration'] ?? '30',
    );
    _capacityController = TextEditingController(
      text: widget.initialCarWashInfo['capacity'] ?? '5',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _openTimeController.dispose();
    _closeTimeController.dispose();
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _pickCarWashImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _carWashImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _carWashImages.removeAt(index);
    });
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  Future<void> _submitCarWashInfo() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من الحقول المطلوبة
    final requiredFields = [
      _nameController.text,
      _locationController.text,
      _phoneController.text,
      _openTimeController.text,
      _closeTimeController.text,
      _durationController.text,
      _capacityController.text,
    ];

    if (requiredFields.any((field) => field.isEmpty)) {
      ErrorHandler.showErrorSnackBar(
          context, 'يرجى تعبئة جميع الحقول المطلوبة');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await _carWashService.saveCarWashInfo(
        ownerId: widget.ownerId,
        name: _nameController.text,
        location: _locationController.text,
        phone: _phoneController.text,
        openTime: _openTimeController.text,
        closeTime: _closeTimeController.text,
        duration: _durationController.text,
        capacity: _capacityController.text,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        ErrorHandler.showSuccessSnackBar(
            context, 'تم حفظ معلومات المغسلة بنجاح');

        // الانتقال إلى Owner Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerScreen(
              carWashInfo: {
                'ownerId': widget.ownerId,
                'carWashId': response.data!['carWashId'],
                'name': _nameController.text,
                'location': _locationController.text,
                'phone': _phoneController.text,
                'email': '',
                'profileImage': response.data!['profileImage'] ?? '',
                'images': response.data!['images'] ?? [],
                'open_time': _openTimeController.text,
                'close_time': _closeTimeController.text,
                'duration': _durationController.text,
                'capacity': _capacityController.text,
              },
            ),
          ),
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات المغسلة'),
        backgroundColor: AppColors.background,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة البروفايل
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xlarge),

              // اسم المغسلة
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المغسلة *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: AppValidators.required,
              ),
              const SizedBox(height: AppSpacing.medium),

              // الموقع
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: AppValidators.required,
              ),
              const SizedBox(height: AppSpacing.medium),

              // رقم الجوال
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: AppValidators.phone,
              ),
              const SizedBox(height: AppSpacing.medium),

              // أوقات العمل
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_openTimeController),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _openTimeController,
                          decoration: const InputDecoration(
                            labelText: 'وقت الافتتاح *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          validator: AppValidators.required,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(_closeTimeController),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _closeTimeController,
                          decoration: const InputDecoration(
                            labelText: 'وقت الإغلاق *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
                          ),
                          validator: AppValidators.required,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),

              // المدة والسعة
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'مدة الخدمة (دقيقة) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: AppValidators.required,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(
                        labelText: 'السعة *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.car_rental),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: AppValidators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),

              // صور المغسلة
              const Text(
                'صور المغسلة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.small),

              GestureDetector(
                onTap: _pickCarWashImages,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  child: _carWashImages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('اضغط لإضافة صور'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: _carWashImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _carWashImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    onPressed: () => _removeImage(index),
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xlarge),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCarWashInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadius),
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
                      : const Text(
                          'حفظ المعلومات',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
