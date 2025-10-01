import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../utils/error_handler.dart';
import '../../config/app_constants.dart';
import '../ProfileEdit_screen.dart';

class UserProfileTab extends StatefulWidget {
  final Map<String, String> userProfile;
  final Function(Map<String, String>) onProfileUpdated;

  const UserProfileTab({
    Key? key,
    required this.userProfile,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  final _profileService = ProfileService();
  bool _isLoading = false;

  Future<void> _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          profile: widget.userProfile,
          isOwner: false,
        ),
      ),
    );

    if (updatedProfile != null && mounted) {
      await _updateProfile(updatedProfile);
    }
  }

  Future<void> _updateProfile(Map<String, String> updatedProfile) async {
    setState(() => _isLoading = true);

    try {
      final response = await _profileService.updateUserProfile(
        userId: updatedProfile['userId']!,
        name: updatedProfile['name']!,
        email: updatedProfile['email']!,
        phone: updatedProfile['phone']!,
      );

      if (!mounted) return;

      if (response.success) {
        widget.onProfileUpdated(updatedProfile);
        ErrorHandler.showSuccessSnackBar(
            context, 'تم تحديث الملف الشخصي بنجاح');
      } else {
        ErrorHandler.showErrorSnackBar(context, response.message);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Center(
        child: Card(
          elevation: AppSizes.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // صورة الملف الشخصي
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // العنوان
                const Text(
                  'الملف الشخصي',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                const Divider(),
                const SizedBox(height: AppSpacing.medium),

                // الاسم
                _buildProfileRow(
                  Icons.person,
                  'الاسم',
                  widget.userProfile['name'] ?? 'غير محدد',
                ),
                const SizedBox(height: AppSpacing.medium),

                // البريد الإلكتروني
                _buildProfileRow(
                  Icons.email,
                  'البريد الإلكتروني',
                  widget.userProfile['email'] ?? 'غير محدد',
                ),
                const SizedBox(height: AppSpacing.medium),

                // رقم الجوال
                _buildProfileRow(
                  Icons.phone,
                  'رقم الجوال',
                  widget.userProfile['phone'] ?? 'غير محدد',
                ),
                const SizedBox(height: AppSpacing.xlarge),

                // زر التعديل
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _navigateToEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      minimumSize: Size(double.infinity, AppSizes.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.edit),
                    label: Text(
                      _isLoading ? 'جاري الحفظ...' : 'تعديل الملف الشخصي',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
