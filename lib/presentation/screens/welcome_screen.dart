import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'SignIn_screen.dart';
import 'SignUp_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const String routeName = 'welcomeScreen';

  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo والترحيب
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'images/logoo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xlarge),

                    // عنوان التطبيق
                    Text(
                      'مرحباً بك',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),

                    // وصف التطبيق
                    Text(
                      'احجز موعدك في أقرب مغسلة\nبسهولة وسرعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // الأزرار
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, SigninScreen.routeName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.secondary,
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // زر إنشاء حساب
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, SignupScreen.routeName);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                        ),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),

                    // نص إضافي (اختياري)
                    Text(
                      'الإصدار 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
