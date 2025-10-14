import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/services/service_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/Service.dart';

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
  File? _selectedImage;
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
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showAddEditDialog([int? index]) {
    if (index != null) {
      final service = _services[index];
      _editingIndex = index;
      _nameController.text = service.name;
      _descriptionController.text = service.description;
      _priceController.text = service.price.toString();
      _selectedImage = null;
    } else {
      _editingIndex = null;
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _editingIndex != null ? Icons.edit : Icons.add,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _editingIndex != null
                            ? 'تعديل الخدمة'
                            : 'إضافة خدمة جديدة',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم الخدمة
                          _buildInputField(
                            controller: _nameController,
                            label: 'اسم الخدمة',
                            hint: 'مثال: غسيل خارجي',
                            icon: Icons.label,
                            validator: AppValidators.required,
                          ),
                          const SizedBox(height: 16),

                          // الوصف
                          _buildInputField(
                            controller: _descriptionController,
                            label: 'الوصف',
                            hint: 'وصف تفصيلي للخدمة',
                            icon: Icons.description,
                            maxLines: 3,
                            validator: AppValidators.required,
                          ),
                          const SizedBox(height: 16),

                          // السعر
                          _buildInputField(
                            controller: _priceController,
                            label: 'السعر (ريال)',
                            hint: '0.00',
                            icon: Icons.attach_money,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
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
                          const SizedBox(height: 20),

                          // اختيار الصورة
                          const Text(
                            'صورة الخدمة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              await _pickImage();
                              setModalState(() {});
                            },
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedImage != null
                                      ? AppColors.primary
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  color: Colors.white),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedImage = null;
                                                });
                                                setModalState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'اضغط لاختيار صورة',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              minimumSize: const Size(0, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    await _saveService();
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              minimumSize: const Size(0, 54),
                              elevation: 0,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _editingIndex != null
                                            ? Icons.save
                                            : Icons.add,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _editingIndex != null ? 'حفظ' : 'إضافة',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      _clearForm();
    });
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null && _editingIndex == null) {
      ErrorHandler.showErrorSnackBar(context, 'يرجى اختيار صورة للخدمة');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;

      if (_editingIndex != null) {
        final service = _services[_editingIndex!];
        final response = await _serviceService.updateService(
          serviceId: service.id!,
          name: name,
          description: description,
          price: price,
          imagePath: _selectedImage?.path,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          setState(() {
            _services[_editingIndex!] = response.data!;
          });
          ErrorHandler.showSuccessSnackBar(context, 'تم تحديث الخدمة بنجاح');
        } else {
          ErrorHandler.showErrorSnackBar(context, response.message);
        }
      } else {
        final response = await _serviceService.addService(
          carWashId: widget.carWashId,
          name: name,
          description: description,
          price: price,
          imagePath: _selectedImage!.path,
        );

        if (!mounted) return;

        if (response.success && response.data != null) {
          setState(() {
            _services.add(response.data!);
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

  Future<void> _deleteService(int index) async {
    final service = _services[index];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'حذف الخدمة',
      content: 'هل أنت متأكد من حذف خدمة "${service.name}"؟',
      confirmText: 'نعم، احذف',
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
    _selectedImage = null;
    _editingIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.build_circle,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الخدمات',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_services.length} خدمة متاحة',
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'إضافة خدمة جديدة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة الخدمات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(_services[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build_circle_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد خدمات',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ بإضافة خدماتك الأولى\nلتتمكن من استقبال الحجوزات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // صورة الخدمة
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                ? Image.network(
                    service.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, trace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),

          // معلومات الخدمة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 4),
                          Text(
                            '${service.price.toStringAsFixed(2)} ريال',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showAddEditDialog(index),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[700],
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteService(index),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                      ),
                      icon: const Icon(Icons.delete_outline, size: 20),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[100]!],
        ),
      ),
      child: Icon(
        Icons.build_circle,
        size: 64,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
