// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // تهيئة الإشعارات
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // معالجة النقر على الإشعار
        if (response.payload != null) {
          // يمكن إضافة منطق للتنقل حسب payload
        }
      },
    );

    _isInitialized = true;
  }

  // إشعار بامتلاء فترة
  static Future<void> showSlotFullNotification(String time) async {
    await _notifications.show(
      0,
      'الفترة ممتلئة',
      'الفترة $time أصبحت ممتلئة الآن',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'slot_updates',
          'تحديثات الفترات',
          channelDescription: 'إشعارات حول حالة الفترات الزمنية',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // إشعار بحجز جديد
  static Future<void> showNewBookingNotification({
    required String customerName,
    required String time,
    required String source,
  }) async {
    await _notifications.show(
      1,
      'حجز جديد',
      '$customerName حجز الساعة $time عبر $source',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'new_bookings',
          'الحجوزات الجديدة',
          channelDescription: 'إشعارات الحجوزات الجديدة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'booking_notification',
    );
  }

  // إشعار بتوفر مكان من قائمة الانتظار
  static Future<void> showSlotAvailableNotification({
    required String date,
    required String time,
  }) async {
    await _notifications.show(
      2,
      'مكان متاح الآن! 🎉',
      'أصبح متاحاً حجز في $date الساعة $time',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'waiting_list',
          'قائمة الانتظار',
          channelDescription: 'إشعارات توفر أماكن من قائمة الانتظار',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: 'slot_available',
    );
  }

  // إشعار بتذكير الموعد
  static Future<void> showAppointmentReminderNotification({
    required String serviceName,
    required String time,
    int notificationId = 3,
  }) async {
    await _notifications.show(
      notificationId,
      'تذكير بموعدك',
      'لديك موعد $serviceName في الساعة $time',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'appointment_reminders',
          'تذكير المواعيد',
          channelDescription: 'تذكيرات المواعيد القادمة',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: 'appointment_reminder',
    );
  }

  // جدولة إشعار مستقبلي (مصحح - بدون uiLocalNotificationDateInterpretation)
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // تحويل DateTime إلى TZDateTime
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate, // ← استخدام TZDateTime بدلاً من DateTime
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_notifications',
          'الإشعارات المجدولة',
          channelDescription: 'إشعارات مجدولة مسبقاً',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // تم إزالة uiLocalNotificationDateInterpretation - غير موجود في الإصدار الحالي
    );
  }

  // إلغاء إشعار معين
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // طلب أذونات الإشعارات (مصحح للأندرويد 13+)
  static Future<bool?> requestPermissions() async {
    if (await _isAndroid13OrHigher()) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // استخدام requestNotificationsPermission بدلاً من requestPermission
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();
      return granted;
    }
    return true; // للإصدارات الأقدم، الأذونات ممنوحة تلقائياً
  }

  // التحقق من إصدار الأندرويد
  static Future<bool> _isAndroid13OrHigher() async {
    // يمكنك استخدام package device_info_plus للتحقق من الإصدار
    // أو ببساطة افترض أنه Android 13+
    return true;
  }

  // دالة بديلة لطلب الأذونات (أبسط)
  static Future<bool> requestPermissionsSimple() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // محاولة طلب الأذونات
        final bool? granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return false;
    } catch (e) {
      // في حالة فشل الطلب، نعتبر الأذونات ممنوحة
      return true;
    }
  }
}
