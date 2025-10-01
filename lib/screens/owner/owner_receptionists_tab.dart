import 'package:flutter/material.dart';
import '../../services/receptionist_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../Receptionist_screen.dart';

class OwnerReceptionistsTab extends StatefulWidget {
  final String carWashId;
  final Map<String, dynamic> carWashInfo;

  const OwnerReceptionistsTab({
    Key? key,
    required this.carWashId,
    required this.carWashInfo,
  }) : super(key: key);

  @override
  State<OwnerReceptionistsTab> createState() => _OwnerReceptionistsTabState();
}

class _OwnerReceptionistsTabState extends State<OwnerReceptionistsTab> {
  final _receptionistService = ReceptionistService();
  List<Map<String, String>> _receptionists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceptionists();
  }

  Future<void> _loadReceptionists() async {
    setState(() => _isLoading = true);

    try {
      final response = await _receptionistService.fetchReceptionists(
        widget.carWashId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _receptionists = response.data!;
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

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة موظف'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: AppValidators.required,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: AppValidators.password,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _addReceptionist(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
      );
    }
  }

  Future<void> _addReceptionist({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _receptionistService.addReceptionist(
        name: name,
        email: email,
        phone: phone,
        password: password,
        carWashId: widget.carWashId,
      );

      if (!mounted) return;

      if (response.success) {
        ErrorHandler.showSuccessSnackBar(context, 'تم إضافة الموظف بنجاح');
        _loadReceptionists();
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _showEditDialog(int index) async {
    final receptionist = _receptionists[index];
    final nameController = TextEditingController(text: receptionist['Name']);
    final emailController = TextEditingController(text: receptionist['Email']);
    final phoneController = TextEditingController(text: receptionist['Phone']);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل معلومات الموظف'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                  validator: AppValidators.required,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: AppValidators.email,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.phone,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة مرور جديدة (اختياري)',
                    border: OutlineInputBorder(),
                    hintText: 'اتركه فارغاً للإبقاء على كلمة المرور الحالية',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _updateReceptionist(
        receptionistId: receptionist['ReceptionistID']!,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password:
            passwordController.text.isEmpty ? null : passwordController.text,
      );
    }
  }

  Future<void> _updateReceptionist({
    required String receptionistId,
    required String name,
    required String email,
    required String phone,
    String? password,
  }) async {
    try {
      final response = await _receptionistService.updateReceptionist(
        receptionistId: receptionistId,
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      if (response.success) {
        ErrorHandler.showSuccessSnackBar(context, 'تم تحديث معلومات الموظف');
        _loadReceptionists();
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _deleteReceptionist(int index) async {
    final receptionist = _receptionists[index];

    final confirm = await ErrorHandler.showConfirmDialog(
      context,
      title: 'حذف الموظف',
      content: 'هل أنت متأكد من حذف الموظف "${receptionist['Name']}"؟',
      confirmText: 'نعم، حذف',
      cancelText: 'إلغاء',
    );

    if (!confirm) return;

    try {
      final response = await _receptionistService.deleteReceptionist(
        receptionist['ReceptionistID']!,
      );

      if (!mounted) return;

      if (response.success) {
        ErrorHandler.showSuccessSnackBar(context, 'تم حذف الموظف بنجاح');
        _loadReceptionists();
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  void _navigateToReceptionistScreen(Map<String, String> receptionist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceptionistScreen(
          receptionist: receptionist,
          carWashInfo: widget.carWashInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // زر إضافة موظف
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: Size(double.infinity, AppSizes.buttonHeight),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة موظف جديد'),
            ),
          ),
        ),

        // قائمة الموظفين
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _receptionists.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'لا يوجد موظفين',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            'أضف موظفك الأول للمغسلة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReceptionists,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        itemCount: _receptionists.length,
                        itemBuilder: (context, index) {
                          final receptionist = _receptionists[index];

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
                            child: InkWell(
                              onTap: () =>
                                  _navigateToReceptionistScreen(receptionist),
                              borderRadius: BorderRadius.circular(
                                AppSizes.cardBorderRadius,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppSpacing.medium),
                                child: Row(
                                  children: [
                                    // أيقونة الموظف
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 32,
                                        color: AppColors.info,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.medium),

                                    // معلومات الموظف
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receptionist['Name'] ?? 'غير محدد',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.email,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  receptionist['Email'] ??
                                                      'غير محدد',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                receptionist['Phone'] ??
                                                    'غير محدد',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
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
                                          onPressed: () =>
                                              _showEditDialog(index),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: AppColors.error,
                                          ),
                                          onPressed: () =>
                                              _deleteReceptionist(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
