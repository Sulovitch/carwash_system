// lib/utils/date_formatter.dart
// دوال مساعدة لتنسيق التاريخ بالعربي بدون الحاجة لـ intl

import 'package:flutter/material.dart';

class DateFormatter {
  static const List<String> arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد'
  ];

  static const List<String> arabicDaysShort = [
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
    'أحد'
  ];

  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];

  // تنسيق التاريخ الكامل: الإثنين، 7 أكتوبر 2025
  static String formatFullDate(DateTime date) {
    final dayOfWeek = arabicDays[(date.weekday - 1) % 7];
    final month = arabicMonths[date.month - 1];
    return '$dayOfWeek، ${date.day} $month ${date.year}';
  }

  // تنسيق اسم اليوم فقط: إثنين
  static String formatDayName(DateTime date) {
    return arabicDaysShort[(date.weekday - 1) % 7];
  }

  // تنسيق اسم اليوم الكامل: الإثنين
  static String formatFullDayName(DateTime date) {
    return arabicDays[(date.weekday - 1) % 7];
  }

  // تنسيق التاريخ الرقمي: 2025-10-07
  static String formatDateNumeric(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // تنسيق التاريخ المختصر: 7 أكتوبر
  static String formatShortDate(DateTime date) {
    final month = arabicMonths[date.month - 1];
    return '${date.day} $month';
  }

  // تنسيق التاريخ مع السنة: 7 أكتوبر 2025
  static String formatDateWithYear(DateTime date) {
    final month = arabicMonths[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  // تنسيق الوقت: 14:30
  static String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // تنسيق التاريخ والوقت: 7 أكتوبر 2025، 14:30
  static String formatDateTime(DateTime date) {
    return '${formatDateWithYear(date)}، ${formatTime(date)}';
  }

  // تنسيق التاريخ بصيغة قصيرة: 07/10/2025
  static String formatShortNumeric(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/$year';
  }

  // تنسيق الشهر والسنة: أكتوبر 2025
  static String formatMonthYear(DateTime date) {
    final month = arabicMonths[date.month - 1];
    return '$month ${date.year}';
  }

  // الحصول على اسم اليوم من رقم اليوم (1-7)
  static String getDayName(int weekday) {
    return arabicDays[(weekday - 1) % 7];
  }

  // الحصول على اسم الشهر من رقم الشهر (1-12)
  static String getMonthName(int month) {
    if (month < 1 || month > 12) return '';
    return arabicMonths[month - 1];
  }

  // تحويل TimeOfDay إلى String
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // معرفة إذا كان التاريخ اليوم
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // معرفة إذا كان التاريخ غداً
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  // معرفة إذا كان التاريخ أمس
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // تنسيق نسبي: اليوم، أمس، غداً، أو التاريخ
  static String formatRelative(DateTime date) {
    if (isToday(date)) {
      return 'اليوم';
    } else if (isTomorrow(date)) {
      return 'غداً';
    } else if (isYesterday(date)) {
      return 'أمس';
    } else {
      return formatDateWithYear(date);
    }
  }

  // حساب الفرق بالأيام
  static int daysDifference(DateTime date1, DateTime date2) {
    final difference = date1.difference(date2);
    return difference.inDays.abs();
  }

  // تنسيق المدة: منذ 3 أيام
  static String formatDuration(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks أسبوع';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'منذ $months شهر';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'منذ $years سنة';
    }
  }
}
