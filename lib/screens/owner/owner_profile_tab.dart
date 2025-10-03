import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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
  final _carWashService = CarWashService();
  final _profileService = ProfileService();

  bool _isEditingCarWash = false;
  bool _isEditingOwner = false;
  bool _isSaving = false;

  // Car Wash Controllers
  late TextEditingController _carWashNameController;
  late TextEditingController _carWashLocationController;
  late TextEditingController _carWashPhoneController;
  late TextEditingController _carWashOpenTimeController;
  late TextEditingController _carWashCloseTimeController;
  late TextEditingController _carWashDurationController;
  late TextEditingController _carWashCapacityController;

  // Owner Controllers
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerEmailController;
  late TextEditingController _ownerPhoneController;

  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Car Wash
    _carWashNameController = TextEditingController(
      text: widget.carWashInfo['name'] ?? '',
    );
    _carWashLocationController = TextEditingController(
      text: widget.carWashInfo['location'] ?? '',
    );
    _carWashPhoneController = TextEditingController(
      text: widget.carWashInfo['phone'] ?? '',
    );
    _carWashOpenTimeController = TextEditingController(
      text: widget.carWashInfo['open_time'] ?? '',
    );
    _carWashCloseTimeController = TextEditingController(
      text: widget.carWashInfo['close_time'] ?? '',
    );
    _carWashDurationController = TextEditingController(
      text: widget.carWashInfo['duration']?.toString() ?? '',
    );
    _carWashCapacityController = TextEditingController(
      text: widget.carWashInfo['capacity']?.toString() ?? '',
    );

    // Owner
    final ownerProfile =
        widget.carWashInfo['ownerProfile'] as Map<String, dynamic>?;
    _ownerNameController = TextEditingController(
      text: ownerProfile?['name']?.toString() ?? '',
    );
    _ownerEmailController = TextEditingController(
      text: ownerProfile?['email']?.toString() ?? '',
    );
    _ownerPhoneController = TextEditingController(
      text: ownerProfile?['phone']?.toString() ?? '',
    );
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveCarWashInfo() async {
    setState(() => _isSaving = true);

    try {
      final carWashId = widget.carWashInfo['carWashId']?.toString() ?? '';
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

      if (response.success) {
        setState(() {
          _isEditingCarWash = false;
          _isSaving = false;
        });

        final updatedInfo = {
          'name': _carWashNameController.text.trim(),
          'location': _carWashLocationController.text.trim(),
          'phone': _carWashPhoneController.text.trim(),
          'open_time': _carWashOpenTimeController.text.trim(),
          'close_time': _carWashCloseTimeController.text.trim(),
          'duration': _carWashDurationController.text.trim(),
          'capacity': _carWashCapacityController.text.trim(),
        };

        widget.onCarWashUpdated(updatedInfo);
        ErrorHandler.showSuccessSnackBar(context, 'تم تحديث بيانات المغسلة');
      } else {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _saveOwnerInfo() async {
    setState(() => _isSaving = true);

    try {
      final ownerId = widget.carWashInfo['ownerId']?.toString() ?? '';
      final response = await _profileService.updateOwnerProfile(
        ownerId: ownerId,
        name: _ownerNameController.text.trim(),
        email: _ownerEmailController.text.trim(),
        phone: _ownerPhoneController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _isEditingOwner = false;
          _isSaving = false;
        });

        widget.onOwnerUpdated({
          'name': _ownerNameController.text.trim(),
          'email': _ownerEmailController.text.trim(),
          'phone': _ownerPhoneController.text.trim(),
        });

        ErrorHandler.showSuccessSnackBar(context, 'تم تحديث بيانات المالك');
      } else {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المغسلة والمالك
          _buildProfileHeader(),
          const SizedBox(height: AppSpacing.large),

          // بطاقة بيانات المغسلة
          _buildCarWashInfoCard(),
          const SizedBox(height: AppSpacing.large),

          // بطاقة بيانات المالك
          _buildOwnerInfoCard(),
          const SizedBox(height: AppSpacing.large),

          // الاشتراك الشهري
          _buildSubscriptionCard(),
          const SizedBox(height: AppSpacing.large),

          // إحصائيات سريعة
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.local_car_wash,
                          size: 48, color: AppColors.primary)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.camera_alt,
                        size: 20, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.carWashInfo['name'] ?? 'مغسلة',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.carWashInfo['location'] ?? 'لا يوجد موقع',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarWashInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.store, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'بيانات المغسلة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isEditingCarWash ? Icons.close : Icons.edit,
                  color: _isEditingCarWash ? Colors.red : AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isEditingCarWash = !_isEditingCarWash;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isEditingCarWash) ...[
            _buildEditField(
                'اسم المغسلة', _carWashNameController, Icons.business),
            const SizedBox(height: 16),
            _buildEditField(
                'الموقع', _carWashLocationController, Icons.location_on),
            const SizedBox(height: 16),
            _buildEditField('رقم الجوال', _carWashPhoneController, Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEditField('وقت الافتتاح',
                      _carWashOpenTimeController, Icons.access_time),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditField('وقت الإغلاق',
                      _carWashCloseTimeController, Icons.access_time),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEditField(
                      'المدة (دقيقة)', _carWashDurationController, Icons.timer,
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditField(
                      'السعة', _carWashCapacityController, Icons.people,
                      keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCarWashInfo,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            _buildInfoRow('اسم المغسلة', widget.carWashInfo['name'] ?? '-',
                Icons.business),
            _buildInfoRow('الموقع', widget.carWashInfo['location'] ?? '-',
                Icons.location_on),
            _buildInfoRow(
                'رقم الجوال', widget.carWashInfo['phone'] ?? '-', Icons.phone),
            _buildInfoRow(
                'ساعات العمل',
                '${widget.carWashInfo['open_time']} - ${widget.carWashInfo['close_time']}',
                Icons.access_time),
            _buildInfoRow('مدة الخدمة',
                '${widget.carWashInfo['duration']} دقيقة', Icons.timer),
            _buildInfoRow('السعة اليومية',
                '${widget.carWashInfo['capacity']} سيارة', Icons.people),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    final ownerProfile =
        widget.carWashInfo['ownerProfile'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'بيانات المالك',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  _isEditingOwner ? Icons.close : Icons.edit,
                  color: _isEditingOwner ? Colors.red : AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _isEditingOwner = !_isEditingOwner;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isEditingOwner) ...[
            _buildEditField('الاسم', _ownerNameController, Icons.person),
            const SizedBox(height: 16),
            _buildEditField(
                'البريد الإلكتروني', _ownerEmailController, Icons.email,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildEditField('رقم الجوال', _ownerPhoneController, Icons.phone,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveOwnerInfo,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else ...[
            _buildInfoRow('الاسم', ownerProfile?['name']?.toString() ?? '-',
                Icons.person),
            _buildInfoRow('البريد الإلكتروني',
                ownerProfile?['email']?.toString() ?? '-', Icons.email),
            _buildInfoRow('رقم الجوال',
                ownerProfile?['phone']?.toString() ?? '-', Icons.phone),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'الاشتراك المميز',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'احصل على مزايا إضافية وتقارير متقدمة مع الاشتراك الشهري',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, OwnerSubscriptionScreen.routeName);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('اكتشف الباقات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'إحصائيات سريعة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child:
                    _buildStatItem('الخدمات', '12', Icons.build, Colors.blue),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade200),
              Expanded(
                child:
                    _buildStatItem('الموظفين', '5', Icons.people, Colors.green),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade200),
              Expanded(
                child:
                    _buildStatItem('التقييم', '4.8', Icons.star, Colors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
