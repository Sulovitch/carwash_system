import 'package:app/screens/Owner_screen.dart';

import 'screens/Receptionist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/SignIn_screen.dart';
import 'screens/SignUp_screen.dart';
import 'screens/Reservation_screen.dart';
import 'screens/CarInput_screen.dart';
import 'screens/owner/monthly_subscription_screen.dart';
import 'config/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ù‚ÙÙ„ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ø¹Ù„Ù‰ Ø§Ù„ÙˆØ¶Ø¹ Ø§Ù„Ø¹Ù…ÙˆØ¯ÙŠ ÙÙ‚Ø·
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

      // Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø§Ø¨ØªØ¯Ø§Ø¦ÙŠØ©
      initialRoute: WelcomeScreen.routeName,

      // Ø¬Ù…ÙŠØ¹ Ø§Ù„Ù€ routes
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

      // Ù…Ø¹Ø§Ù„Ø¬ Ø£ÙØ¶Ù„ Ù„Ù„Ù€ routes Ø§Ù„ØªÙŠ ØªØ­ØªØ§Ø¬ arguments
      onGenerateRoute: (settings) {
        // Ù…Ø¹Ø§Ù„Ø¬Ø© ReservationScreen Ù…Ø¹ arguments
        if (settings.name == ReservationScreen.screenRoute) {
          return MaterialPageRoute(
            builder: (context) => const ReservationScreen(),
            settings: settings, // Ù…Ù‡Ù… Ù„ØªÙ…Ø±ÙŠØ± arguments
          );
        }

        // Ø¥Ø°Ø§ Ù„Ù… ÙŠÙƒÙ† Ø§Ù„Ù…Ø³Ø§Ø± Ù…Ø¹Ø±Ù‘ÙØŒ ÙŠØ¹ÙˆØ¯ null Ù„ÙŠØ³ØªØ®Ø¯Ù… onUnknownRoute
        return null;
      },

      // Ù…Ø¹Ø§Ù„Ø¬ Ù„Ù„Ù€ routes Ø§Ù„ØºÙŠØ± Ù…ÙˆØ¬ÙˆØ¯Ø©
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Ø®Ø·Ø£'),
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
                    'Ø§Ù„ØµÙØ­Ø© ØºÙŠØ± Ù…ÙˆØ¬ÙˆØ¯Ø©',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Ø§Ù„Ù…Ø³Ø§Ø± Ø§Ù„Ù…Ø·Ù„ÙˆØ¨: ${settings.name}',
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
                    label: const Text('Ø§Ù„Ø¹ÙˆØ¯Ø© Ù„Ù„Ø±Ø¦ÙŠØ³ÙŠØ©'),
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
