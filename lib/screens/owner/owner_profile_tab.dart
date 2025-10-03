import 'package:flutter/material.dart';
import '../../config/app_constants.dart';
import '../../services/carwash_service.dart';
import '../../services/profile_service.dart';
import '../../utils/error_handler.dart';
import 'monthly_subscription_screen.dart';

class OwnerProfileTab extends StatefulWidget {
  final Map<String, dynamic> carWashInfo;
  final void Function(Map<String, dynamic> updatedInfo) onCarWashUpdated;
  final void Function(Map<String, dynamic> updatedOwner) onOwnerUpdated;

  const OwnerProfileTab({
    Key? key,
    required this.carWashInfo,
    required this.onCarWashUpdated,
    required this.onOwnerUpdated,
  }) : super(key: key);

  @override
  State<OwnerProfileTab> createState() => _OwnerProfileTabState();
}

class _OwnerProfileTabState extends State<OwnerProfileTab> {
  final _carWashFormKey = GlobalKey<FormState>();
  final _ownerFormKey = GlobalKey<FormState>();

  final _carWashService = CarWashService();
  final _profileService = ProfileService();

  late final TextEditingController _carWashNameController;
  late final TextEditingController _carWashLocationController;
  late final TextEditingController _carWashPhoneController;
  late final TextEditingController _carWashOpenTimeController;
  late final TextEditingController _carWashCloseTimeController;
  late final TextEditingController _carWashDurationController;
  late final TextEditingController _carWashCapacityController;

  late final TextEditingController _ownerNameController;
  late final TextEditingController _ownerEmailController;
  late final TextEditingController _ownerPhoneController;

  bool _isSavingCarWash = false;
  bool _isSavingOwner = false;

  @override
  void initState() {
    super.initState();
    _carWashNameController =
        TextEditingController(text: widget.carWashInfo['name'] ?? '');
    _carWashLocationController =
        TextEditingController(text: widget.carWashInfo['location'] ?? '');
    _carWashPhoneController =
        TextEditingController(text: widget.carWashInfo['phone'] ?? '');
    _carWashOpenTimeController =
        TextEditingController(text: widget.carWashInfo['open_time'] ?? '');
    _carWashCloseTimeController =
        TextEditingController(text: widget.carWashInfo['close_time'] ?? '');
    _carWashDurationController = TextEditingController(
        text: widget.carWashInfo['duration']?.toString() ?? '');
    _carWashCapacityController = TextEditingController(
        text: widget.carWashInfo['capacity']?.toString() ?? '');

    final ownerProfile = widget.carWashInfo['ownerProfile'] as Map<String, dynamic>?;
    _ownerNameController =
        TextEditingController(text: ownerProfile?['name']?.toString() ?? '');
    _ownerEmailController =
        TextEditingController(text: ownerProfile?['email']?.toString() ?? '');
    _ownerPhoneController =
        TextEditingController(text: ownerProfile?['phone']?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant OwnerProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carWashInfo != widget.carWashInfo) {
      _carWashNameController.text = widget.carWashInfo['name'] ?? '';
      _carWashLocationController.text = widget.carWashInfo['location'] ?? '';
      _carWashPhoneController.text = widget.carWashInfo['phone'] ?? '';
      _carWashOpenTimeController.text = widget.carWashInfo['open_time'] ?? '';
      _carWashCloseTimeController.text = widget.carWashInfo['close_time'] ?? '';
      _carWashDurationController.text =
          widget.carWashInfo['duration']?.toString() ?? '';
      _carWashCapacityController.text =
          widget.carWashInfo['capacity']?.toString() ?? '';
    }

    final oldOwner = oldWidget.carWashInfo['ownerProfile'];
    final newOwner = widget.carWashInfo['ownerProfile'];
    if (oldOwner != newOwner && newOwner is Map<String, dynamic>) {
      _ownerNameController.text = newOwner['name']?.toString() ?? '';
      _ownerEmailController.text = newOwner['email']?.toString() ?? '';
      _ownerPhoneController.text = newOwner['phone']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _carWashNameController.dispose();
    _carWashLocationController.dispose();
    _carWashPhoneController.dispose();
    _carWashOpenTimeController.dispose();
    _carWashCloseTimeController.dispose();
    _carWashDurationController.dispose();
    _carWashCapacityController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveCarWashInfo() async {
    if (!_carWashFormKey.currentState!.validate()) return;

    final carWashId = widget.carWashInfo['carWashId']?.toString();
    if (carWashId == null || carWashId.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'معرف المغسلة غير متوفر');
      return;
    }

    setState(() => _isSavingCarWash = true);

    try {
      final response = await _carWashService.updateCarWashInfo(
        carWashId: carWashId,
        name: _carWashNameController.text.trim(),
        location: _carWashLocationController.text.trim(),
        phone: _carWashPhoneController.text.trim(),
        openTime: _carWashOpenTimeController.text.trim(),
        closeTime: _carWashCloseTimeController.text.trim(),
        duration: _carWashDurationController.text.trim(),
        capacity: _carWashCapacityController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isSavingCarWash = false);

      if (response.success) {
        final updatedInfo = Map<String, dynamic>.from(widget.carWashInfo)
          ..['name'] = _carWashNameController.text.trim()
          ..['location'] = _carWashLocationController.text.trim()
          ..['phone'] = _carWashPhoneController.text.trim()
          ..['open_time'] = _carWashOpenTimeController.text.trim()
          ..['close_time'] = _carWashCloseTimeController.text.trim()
          ..['duration'] = _carWashDurationController.text.trim()
          ..['capacity'] = _carWashCapacityController.text.trim();

        widget.onCarWashUpdated(updatedInfo);
        ErrorHandler.showSuccessSnackBar(
          context,
          response.message ?? 'تم تحديث بيانات المغسلة بنجاح',
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingCarWash = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<void> _saveOwnerInfo() async {
    if (!_ownerFormKey.currentState!.validate()) return;

    final ownerProfile = widget.carWashInfo['ownerProfile'];
    final ownerId = ownerProfile is Map<String, dynamic>
        ? ownerProfile['id']?.toString() ?? ownerProfile['ownerId']?.toString()
        : widget.carWashInfo['ownerId']?.toString();

    if (ownerId == null || ownerId.isEmpty) {
      ErrorHandler.showErrorSnackBar(context, 'معرف صاحب المغسلة غير متوفر');
      return;
    }

    setState(() => _isSavingOwner = true);

    try {
      final response = await _profileService.updateOwnerProfile(
        ownerId: ownerId,
        name: _ownerNameController.text.trim(),
        email: _ownerEmailController.text.trim(),
        phone: _ownerPhoneController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isSavingOwner = false);

      if (response.success) {
        final updatedOwner = <String, dynamic>{
          'id': ownerId,
          'name': _ownerNameController.text.trim(),
          'email': _ownerEmailController.text.trim(),
          'phone': _ownerPhoneController.text.trim(),
        };

        widget.onOwnerUpdated(updatedOwner);
        ErrorHandler.showSuccessSnackBar(
          context,
          response.message ?? 'تم تحديث بيانات المالك بنجاح',
        );
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingOwner = false);
      ErrorHandler.showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'بيانات المغسلة',
            subtitle: 'قم بتحديث معلومات المغسلة الخاصة بك',
          ),
          const SizedBox(height: AppSpacing.small),
          _buildCard(
            child: Form(
              key: _carWashFormKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _carWashNameController,
                    label: 'اسم المغسلة',
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildTextField(
                    controller: _carWashLocationController,
                    label: 'الموقع',
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildTextField(
                    controller: _carWashPhoneController,
                    label: 'رقم التواصل',
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.phone,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _carWashOpenTimeController,
                          label: 'وقت الافتتاح',
                          validator: AppValidators.required,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: _buildTextField(
                          controller: _carWashCloseTimeController,
                          label: 'وقت الإغلاق',
                          validator: AppValidators.required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _carWashDurationController,
                          label: 'مدة الخدمة (بالدقائق)',
                          keyboardType: TextInputType.number,
                          validator: AppValidators.required,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: _buildTextField(
                          controller: _carWashCapacityController,
                          label: 'السعة اليومية',
                          keyboardType: TextInputType.number,
                          validator: AppValidators.required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingCarWash ? null : _saveCarWashInfo,
                      icon: _isSavingCarWash
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        _isSavingCarWash ? 'جاري الحفظ...' : 'حفظ بيانات المغسلة',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xlarge),
          _buildSectionHeader(
            title: 'بيانات صاحب المغسلة',
            subtitle: 'قم بتحديث بيانات التواصل الخاصة بالمالك',
          ),
          const SizedBox(height: AppSpacing.small),
          _buildCard(
            child: Form(
              key: _ownerFormKey,
              child: Column(
                children: [
                  _buildTextField(
                    controller: _ownerNameController,
                    label: 'اسم المالك',
                    validator: AppValidators.required,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildTextField(
                    controller: _ownerEmailController,
                    label: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: AppValidators.email,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _buildTextField(
                    controller: _ownerPhoneController,
                    label: 'رقم الجوال',
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.phone,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSavingOwner ? null : _saveOwnerInfo,
                      icon: _isSavingOwner
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person),
                      label: Text(
                        _isSavingOwner ? 'جاري الحفظ...' : 'حفظ بيانات المالك',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xlarge),
          _buildCard(
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الاشتراك الشهري',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                const Text(
                  'استفد من مزايا إضافية لإدارة المغسلة من خلال خطط الاشتراك المرنة.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.medium),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        OwnerSubscriptionScreen.routeName,
                      );
                    },
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('عرض خطط الاشتراك'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Widget child,
    Color? color,
  }) {
    return Card(
      color: color,
      elevation: color == null ? AppSizes.cardElevation : 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
