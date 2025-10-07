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

class _UserProfileTabState extends State<UserProfileTab>
    with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
    return Container(
      color: Colors.grey[50],
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // بطاقة البروفايل الرئيسية
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      Colors.blue.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // نمط زخرفي
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // صورة البروفايل
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // الاسم
                          Text(
                            widget.userProfile['name'] ?? 'المستخدم',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // الشارة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.verified_user,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'عضو مميز',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // معلومات الحساب
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'معلومات الحساب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey[200]),

                    // البريد الإلكتروني
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'البريد الإلكتروني',
                      value: widget.userProfile['email'] ?? 'غير محدد',
                      color: Colors.blue,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey[200]),

                    // رقم الجوال
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'رقم الجوال',
                      value: widget.userProfile['phone'] ?? 'غير محدد',
                      color: Colors.green,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey[200]),

                    // معرف المستخدم
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'معرف المستخدم',
                      value: widget.userProfile['userId']?.substring(
                              0,
                              widget.userProfile['userId']!.length > 8
                                  ? 8
                                  : widget.userProfile['userId']!.length) ??
                          'غير محدد',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // إحصائيات سريعة
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.event_available,
                      label: 'حجوزاتي',
                      value: '0',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.directions_car,
                      label: 'سياراتي',
                      value: '0',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // الإعدادات والخيارات
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      icon: Icons.edit_outlined,
                      title: 'تعديل الملف الشخصي',
                      subtitle: 'تحديث بياناتك الشخصية',
                      color: AppColors.primary,
                      onTap: _navigateToEditProfile,
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey[200]),
                    _buildActionTile(
                      icon: Icons.security_outlined,
                      title: 'الخصوصية والأمان',
                      subtitle: 'إدارة إعدادات الخصوصية',
                      color: Colors.green,
                      onTap: () {
                        // TODO: فتح إعدادات الخصوصية
                        ErrorHandler.showInfoSnackBar(context, 'ميزة قريباً');
                      },
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey[200]),
                    _buildActionTile(
                      icon: Icons.notifications_outlined,
                      title: 'الإشعارات',
                      subtitle: 'تفعيل أو إيقاف الإشعارات',
                      color: Colors.orange,
                      onTap: () {
                        // TODO: فتح إعدادات الإشعارات
                        ErrorHandler.showInfoSnackBar(context, 'ميزة قريباً');
                      },
                    ),
                    Divider(height: 1, indent: 68, color: Colors.grey[200]),
                    _buildActionTile(
                      icon: Icons.help_outline,
                      title: 'المساعدة والدعم',
                      subtitle: 'احصل على المساعدة',
                      color: Colors.blue,
                      onTap: () {
                        // TODO: فتح صفحة المساعدة
                        ErrorHandler.showInfoSnackBar(context, 'ميزة قريباً');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // زر تسجيل الخروج
              Container(
                width: double.infinity,
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: const [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 12),
                              Text('تسجيل الخروج'),
                            ],
                          ),
                          content: const Text(
                            'هل أنت متأكد من تسجيل الخروج من حسابك؟',
                            style: TextStyle(fontSize: 15),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  'welcome_screen',
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('تسجيل الخروج'),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: AppColors.error, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // معلومات النسخة
              Text(
                'الإصدار 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
