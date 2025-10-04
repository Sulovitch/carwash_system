import 'package:flutter/foundation.dart';

/// نظام تسجيل محسّن للأخطاء والأحداث
class AppLogger {
  static const String _prefix = '🚗 CarWash';

  /// تسجيل معلومات
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      print('$_prefix ℹ️ ${tag != null ? "[$tag]" : ""} $message');
    }
  }

  /// تسجيل خطأ
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix ❌ ERROR: $message');
      if (error != null) print('   Error: $error');
      if (stackTrace != null) print('   Stack: $stackTrace');
    }
  }

  /// تسجيل تحذير
  static void warning(String message) {
    if (kDebugMode) {
      print('$_prefix ⚠️ WARNING: $message');
    }
  }

  /// تسجيل نجاح
  static void success(String message) {
    if (kDebugMode) {
      print('$_prefix ✅ $message');
    }
  }

  /// تسجيل طلب شبكة
  static void network(String method, String url, {int? statusCode}) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      print('$_prefix 🌐 $method $url$status');
    }
  }
}
