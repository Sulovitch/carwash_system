import 'package:flutter/material.dart';
import 'dart:async';

/// إعدادات الأداء للتطبيق
class PerformanceConfig {
  // منع الإنشاء
  PerformanceConfig._();

  /// حجم الكاش للصور (عدد الصور)
  static const int imageCacheSize = 50;

  /// حجم الكاش للبيانات (عدد الاستعلامات)
  static const int dataCacheSize = 20;

  /// مدة صلاحية الكاش الافتراضية
  static const Duration defaultCacheDuration = Duration(minutes: 5);

  /// مدة الـ timeout للطلبات
  static const Duration requestTimeout = Duration(seconds: 10);

  /// عدد المحاولات عند فشل الطلب
  static const int maxRetries = 3;

  /// تأخير إعادة المحاولة
  static const Duration retryDelay = Duration(seconds: 2);

  /// حجم الصفحة للتحميل التدريجي
  static const int pageSize = 20;

  /// عدد العناصر لتفعيل التحميل التدريجي
  static const int lazyLoadThreshold = 10;

  /// إعدادات الصور
  static const ImageCacheConfig imageCache = ImageCacheConfig(
    maxWidth: 800,
    maxHeight: 800,
    quality: 85,
  );

  /// إعدادات الانتقالات
  static const Duration transitionDuration = Duration(milliseconds: 300);

  /// Debounce للبحث
  static const Duration searchDebounce = Duration(milliseconds: 500);
}

/// تكوين كاش الصور
class ImageCacheConfig {
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const ImageCacheConfig({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

/// مساعد للـ Debouncing
class Debouncer {
  final Duration delay;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// مساعد للـ Throttling
class Throttler {
  final Duration duration;
  bool _isRunning = false;

  Throttler({this.duration = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    if (_isRunning) return;

    _isRunning = true;
    action();

    Timer(duration, () {
      _isRunning = false;
    });
  }
}
