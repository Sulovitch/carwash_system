import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

class ProfileEditScreen extends StatefulWidget {
  static const String routeName = 'ProfileEdit_screen';
  final Map<String, String> profile;
  final bool isOwner;

  const ProfileEditScreen({
    Key? key,
    required this.profile,
    required this.isOwner,
  }) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['name']);
    _emailController = TextEditingController(text: widget.profile['email']);
    _phoneController = TextEditingController(text: widget.profile['phone']);

    // إضافة مستمعين للتحقق من التغييرات
    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);

    // إعداد الأنيميشن
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != widget.profile['name'] ||
        _emailController.text != widget.profile['email'] ||
        _phoneController.text != widget.profile['phone'];

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileId =
        widget.isOwner ? widget.profile['ownerId'] : widget.profile['userId'];

    if (profileId == null || profileId.isEmpty) {
      _showSnackBar('خطأ: معرف المستخدم مفقود', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // محاكاة استدعاء API
      await Future.delayed(const Duration(seconds: 2));

      final updatedProfile = {
        widget.isOwner ? 'ownerId' : 'userId': profileId,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (!mounted) return;

      _showSnackBar('تم تحديث الملف الشخصي بنجاح', isError: false);

      // الانتظار قليلاً لعرض رسالة النجاح
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('حدث خطأ أثناء التحديث', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('تنبيه'),
          ],
        ),
        content: const Text(
          'لديك تغييرات غير محفوظة. هل تريد الخروج بدون حفظ؟',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('البقاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('الخروج'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title:
              Text(widget.isOwner ? 'تعديل ملف المالك' : 'تعديل الملف الشخصي'),
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 14, color: Colors.orange[900]),
                        const SizedBox(width: 4),
                        Text(
                          'تم التعديل',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة الترحيب
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            Colors.blue.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.profile['name'] ?? 'المستخدم',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.isOwner ? 'صاحب مغسلة' : 'مستخدم',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // عنوان القسم
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'المعلومات الشخصية',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // حقل الاسم
                    _buildInputCard(
                      label: 'الاسم الكامل',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      hint: 'أدخل اسمك الكامل',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        if (value.trim().length < 3) {
                          return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // حقل البريد الإلكتروني
                    _buildInputCard(
                      label: 'البريد الإلكتروني',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      hint: 'example@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'البريد الإلكتروني مطلوب';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'البريد الإلكتروني غير صحيح';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // حقل الجوال
                    _buildInputCard(
                      label: 'رقم الجوال',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      hint: '05xxxxxxxx',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'رقم الجوال مطلوب';
                        }
                        if (!RegExp(r'^05\d{8}$').hasMatch(value)) {
                          return 'رقم الجوال يجب أن يبدأ بـ 05 ويتكون من 10 أرقام';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // معلومات إضافية
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'تأكد من صحة المعلومات قبل الحفظ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // أزرار الحفظ والإلغاء
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_hasChanges) {
                                      _onWillPop().then((shouldPop) {
                                        if (shouldPop) Navigator.pop(context);
                                      });
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              minimumSize: const Size(0, 56),
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
                            onPressed: _isLoading || !_hasChanges
                                ? null
                                : _submitProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              minimumSize: const Size(0, 56),
                              elevation: _hasChanges ? 4 : 0,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
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
                                    children: const [
                                      Icon(Icons.save, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'حفظ التغييرات',
                                        style: TextStyle(
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

                    const SizedBox(height: 16),

                    // ملاحظة أمان
                    Center(
                      child: Text(
                        '🔒 معلوماتك محمية ومشفرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
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
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              errorStyle: const TextStyle(
                fontSize: 12,
                height: 0.8,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
