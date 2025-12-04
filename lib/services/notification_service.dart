// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    try {
      // 1. Request permission dulu (Android 13+)
      await _requestPermission();

      // 2. Initialize plugin
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initialized = await _plugin.initialize(
        const InitializationSettings(android: android, iOS: iOS),
      );

      _isInitialized = initialized ?? false;
      print('✅ Notification initialized: $_isInitialized');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  static Future<void> _requestPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      print('📱 Notification permission: $status');
    }
  }

  /// Format waktu untuk berbagai timezone
  static String _formatMultipleTimezones() {
    final now = DateTime.now();

    // WIB (UTC+7)
    final wib = now.toUtc().add(const Duration(hours: 7));
    final wibStr = DateFormat('HH:mm').format(wib);

    // WITA (UTC+8)
    final wita = now.toUtc().add(const Duration(hours: 8));
    final witaStr = DateFormat('HH:mm').format(wita);

    // WIT (UTC+9)
    final wit = now.toUtc().add(const Duration(hours: 9));
    final witStr = DateFormat('HH:mm').format(wit);

    // London (UTC+0 atau UTC+1 tergantung DST)
    // Untuk sederhana, kita gunakan UTC+0
    final london = now.toUtc();
    final londonStr = DateFormat('HH:mm').format(london);

    return 'WIB $wibStr | WITA $witaStr | WIT $witStr | London $londonStr';
  }

  /// Tampilkan notifikasi dengan AQI dan waktu multi-timezone
  static Future<void> showNotification({
    required String title,
    required String body,
    int? aqi,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Notification service not initialized, re-initializing...');
      await init();

      if (!_isInitialized) {
        print('❌ Still not initialized, aborting notification');
        return;
      }
    }

    try {
      // Buat body dengan waktu
      final timeInfo = _formatMultipleTimezones();
      final fullBody = aqi != null
          ? '$body\n\n🕐 $timeInfo'
          : '$body\n$timeInfo';

      const androidDetails = AndroidNotificationDetails(
        'paruguard_channel',
        'ParuGuard Alerts',
        channelDescription: 'Peringatan kualitas udara ParuGuard',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        styleInformation: BigTextStyleInformation(''), // Agar text panjang muat
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        fullBody,
        const NotificationDetails(android: androidDetails, iOS: iOSDetails),
      );

      print('✅ Notification shown: $title');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }
}
