import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/service_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../../models/Service.dart';

class OwnerServicesTab extends StatefulWidget {
  final String carWashId;

  const OwnerServicesTab({
    Key? key,
    required this.carWashId,
  }) : super(key: key);

  @override
  State<OwnerServicesTab> createState() => _OwnerServicesTabState();
}

class _OwnerServicesTabState extends State<OwnerServicesTab> {
  final _serviceService = ServiceService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  List<Service> _services = [];
  String? _imagePath;
  int? _editingIndex;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);

    try {
      final response = await _serviceService.fetchServices(widget.carWashId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _services = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagePath == null && _editingIndex == null) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى اختيار صورة للخدمة');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (_editingIndex != null) {
        // تحديث خدمة موجودة
        final service = _services[_editingIndex!];
        final response = await _serviceService.updateService(
          serviceId: service.id!,
          name: name,
          description: description,
          price: price,
          imagePath: _imagePath,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          setState(() {
            _services[_editingIndex!] = response.data!;
            _clearForm();
          });
          ErrorHandler.showSuccessSnackBar(context, 'تم تحديث الخدمة بنجاح');
        } else {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      } else {
        // إضافة خدمة جديدة
        final response = await _serviceService.addService(
          carWashId: widget.carWashId,
          name: name,
          description: description,
          price: price,
          imagePath: _imagePath!,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          setState(() {
            _services.add(response.data!);
            _clearForm();
          });
          ErrorHandler.showSuccessSnackBar(context, 'تم إضافة الخدمة بنجاح');
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

  void _editService(int index) {
    final service = _services[index];
    setState(() {
      _editingIndex = index;
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _imagePath = null;
    });
  }

  Future<void> _deleteService(int index) async {
    final service = _services[index];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'حذف الخدمة',
      content: 'هل أنت متأكد من حذف خدمة "${service.name}"؟',
      confirmText: 'نعم، حذف',
      cancelText: 'إلغاء',
    );

    if (!confirm) return;

    try {
      final response = await _serviceService.deleteService(service.id!);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _services.removeAt(index);
        });
        ErrorHandler.showSuccessSnackBar(context, 'تم حذف الخدمة بنجاح');
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _imagePath = null;
      _editingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // قائمة الخدمات
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.build_circle,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'لا توجد خدمات',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'أضف خدمتك الأولى باستخدام النموذج أدناه',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadServices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final isEditing = _editingIndex == index;

                          return Card(
                            elevation: isEditing ? 4 : 2,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.medium,
                            ),
                            color: isEditing ? Colors.blue[50] : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardBorderRadius,
                              ),
                              side: isEditing
                                  ? BorderSide(color: Colors.blue, width: 2)
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.medium),
                              child: Row(
                                children: [
                                  // صورة الخدمة
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: service.imageUrl != null
                                        ? Image.network(
                                            service.imageUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, trace) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.image,
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: AppSpacing.medium),

                                  // معلومات الخدمة
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          service.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${service.price.toStringAsFixed(2)} ريال',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
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
                                        icon: Icon(
                                          isEditing ? Icons.check : Icons.edit,
                                          color: isEditing
                                              ? AppColors.success
                                              : AppColors.info,
                                        ),
                                        onPressed: () => _editService(index),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => _deleteService(index),
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

        // نموذج الإضافة/التعديل
        Container(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingIndex != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // اسم الخدمة
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة',
                      border: OutlineInputBorder(),
                    ),
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // الوصف
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // السعر
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'السعر (ريال)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.requiredField;
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال سعر صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),

                  // زر اختيار الصورة
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(
                          _imagePath == null ? 'اختر صورة' : 'تغيير الصورة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // عرض الصورة المختارة
                  if (_imagePath != null) ...[
                    const SizedBox(height: AppSpacing.small),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.medium),

                  // أزرار الحفظ والإلغاء
                  Row(
                    children: [
                      if (_editingIndex != null) ...[
                        // زر الإلغاء
                        Expanded(
                          child: SizedBox(
                            height: AppSizes.buttonHeight,
                            child: OutlinedButton(
                              onPressed: _clearForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('إلغاء'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                      ],
                      // زر الحفظ
                      Expanded(
                        child: SizedBox(
                          height: AppSizes.buttonHeight,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveService,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _editingIndex != null
                                        ? 'حفظ التعديلات'
                                        : 'إضافة الخدمة',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
