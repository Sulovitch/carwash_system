import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double xlarge = 32.0;
  static const double xxlarge = 48.0;
}

class AppSizes {
  static const double buttonHeight = 50.0;
  static const double buttonWidth = 200.0;
  static const double avatarRadius = 50.0;
  static const double iconSize = 24.0;
  static const double cardElevation = 8.0;
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
}

class AppColors {
  static const Color primary = Colors.black;
  static const Color secondary = Colors.white;
  static const Color error = Colors.red;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color background = Colors.white;
}

class AppStrings {
  // Common
  static const String appName = 'Car Wash App';
  static const String ok = 'موافق';
  static const String cancel = 'إلغاء';
  static const String save = 'حفظ';
  static const String delete = 'حذف';
  static const String edit = 'تعديل';
  static const String loading = 'جاري التحميل...';
  static const String error = 'حدث خطأ';
  static const String success = 'نجحت العملية';

  // Errors
  static const String networkError = 'لا يوجد اتصال بالإنترنت';
  static const String serverError = 'خطأ في السيرفر، حاول مرة أخرى';
  static const String unknownError = 'حدث خطأ غير متوقع';
  static const String fillAllFields = 'يرجى تعبئة جميع الحقول';

  // Validation
  static const String requiredField = 'هذا الحقل مطلوب';
  static const String invalidEmail = 'البريد الإلكتروني غير صحيح';
  static const String invalidPhone = 'رقم الجوال يجب أن يكون 10 أرقام';
  static const String passwordTooShort =
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
}

class AppValidators {
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length != 10) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }
}
