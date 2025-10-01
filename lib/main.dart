import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/SignIn_screen.dart';
import 'screens/SignUp_screen.dart';
import 'screens/Reservation_screen.dart'; // أضف هذا السطر
import 'config/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // قفل التطبيق على الوضع العمودي فقط
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق حجز المغاسل',
      debugShowCheckedModeBanner: false,

      // الثيم الموحد
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          elevation: 1,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            minimumSize: Size(double.infinity, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            elevation: 2,
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.medium,
          ),
        ),

        // Card Theme
        cardTheme: CardTheme(
          elevation: AppSizes.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          ),
        ),

        // SnackBar Theme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
      ),

      // الشاشة الابتدائية
      initialRoute: WelcomeScreen.routeName,

      // جميع الـ routes
      routes: {
        WelcomeScreen.routeName: (context) => const WelcomeScreen(),
        SigninScreen.routeName: (context) => const SigninScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        ReservationScreen.screenRoute: (context) =>
            const ReservationScreen(), // أضف هذا السطر
      },

      // معالج أفضل للـ routes التي تحتاج arguments
      onGenerateRoute: (settings) {
        // معالجة ReservationScreen مع arguments
        if (settings.name == ReservationScreen.screenRoute) {
          return MaterialPageRoute(
            builder: (context) => const ReservationScreen(),
            settings: settings, // مهم لتمرير arguments
          );
        }

        // إذا لم يكن المسار معرّف، يعود null ليستخدم onUnknownRoute
        return null;
      },

      // معالج للـ routes الغير موجودة
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('خطأ'),
              backgroundColor: AppColors.background,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 80, color: AppColors.error),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    'الصفحة غير موجودة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'المسار المطلوب: ${settings.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xlarge),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      WelcomeScreen.routeName,
                      (route) => false,
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text('العودة للرئيسية'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
