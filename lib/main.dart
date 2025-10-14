import 'package:app/presentation/screens/Owner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/welcome_screen.dart';
import 'presentation/screens/SignIn_screen.dart';
import 'presentation/screens/SignUp_screen.dart';
import 'presentation/screens/Reservation_screen.dart';
import 'presentation/screens/CarInput_screen.dart';
import 'presentation/screens/owner/monthly_subscription_screen.dart';
import 'core/constants/app_constants.dart';
import 'data/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // طلب أذونات الإشعارات (Android 13+)
  await NotificationService.requestPermissions();

  // تهيئة الإشعارات
  await NotificationService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // سنضيف المزيد من Providers هنا
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة المغسلة',
      debugShowCheckedModeBanner: false,

      // Ø§Ù„Ø«ÙŠÙ… Ø§Ù„Ù…ÙˆØ­Ø¯
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
        cardTheme: CardThemeData(
          elevation: AppSizes.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
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

      initialRoute: WelcomeScreen.routeName,

      routes: {
        WelcomeScreen.routeName: (context) => const WelcomeScreen(),
        SigninScreen.routeName: (context) => const SigninScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        ReservationScreen.screenRoute: (context) => const ReservationScreen(),
        CarInputScreen.routeName: (context) => CarInputScreen(userId: ''),
        OwnerScreen.routeName: (context) => OwnerScreen(carWashInfo: const {}),
        OwnerSubscriptionScreen.routeName: (context) =>
            const OwnerSubscriptionScreen(),
      },
    );
  }
}
