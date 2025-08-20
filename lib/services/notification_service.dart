import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 初始化时区数据
    tz.initializeTimeZones();
    // 设置本地时区
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 请求通知权限
    await _requestPermissions();

    // 设置默认的每日提醒
    await _setDefaultReminder();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // 处理通知点击事件
  }

  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        // iOS平台使用flutter_local_notifications请求权限
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } else {
        // Android平台使用permission_handler
        final status = await Permission.notification.request();

        // 如果权限被拒绝，提示用户
        if (status.isDenied || status.isPermanentlyDenied) {
          // 通知权限被拒绝，请在设置中手动开启
        }
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  static Future<void> _setDefaultReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetReminder = prefs.getBool('has_set_reminder') ?? false;

    if (!hasSetReminder) {
      // 设置默认提醒时间为晚上7点
      await saveReminderSettings(enabled: true, hour: 19, minute: 0);
      await prefs.setBool('has_set_reminder', true);
    }
  }

  // 显示即时通知
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'check_in_channel',
          '打卡提醒',
          channelDescription: '每日练习打卡提醒',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // 安排定时通知
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'check_in_channel',
          '打卡提醒',
          channelDescription: '每日练习打卡提醒',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // 安排每日重复通知
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_check_in_channel',
          '每日打卡提醒',
          channelDescription: '每日定时打卡提醒',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = '🎯 练习提醒',
    String body = '小朋友，该练习了！坚持每天练习，养成好习惯！🌟',
  }) async {
    // 先取消之前的提醒
    await cancelNotification(1);

    await _notifications.zonedSchedule(
      1, // 通知ID
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '每日提醒',
          channelDescription: '每日练习提醒',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // 计算下一个指定时间
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 取消通知
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // 取消所有通知
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 保存提醒设置
  static Future<void> saveReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);

    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelNotification(1);
    }
  }

  // 获取提醒设置
  static Future<Map<String, dynamic>> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool('reminder_enabled') ?? true,
      'hour': prefs.getInt('reminder_hour') ?? 19,
      'minute': prefs.getInt('reminder_minute') ?? 0,
    };
  }

  // 检查通知权限状态
  static Future<bool> checkNotificationPermission() async {
    try {
      if (Platform.isIOS) {
        // iOS平台先检查当前权限状态
        final iosPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iosPlugin != null) {
          // 检查当前权限状态
          await _notifications.pendingNotificationRequests();

          // 尝试请求权限
          final bool? result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          return result ?? false;
        }
      } else {
        // Android平台使用permission_handler
        final status = await Permission.notification.status;

        // 如果权限状态不明确，尝试请求权限
        if (status.isDenied) {
          final newStatus = await Permission.notification.request();
          return newStatus.isGranted;
        }

        return status.isGranted;
      }

      // 降级处理：尝试发送测试通知来检测权限
      try {
        await _notifications.show(
          99999,
          '权限测试',
          '测试通知权限',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_channel',
              '测试频道',
              importance: Importance.low,
              priority: Priority.low,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
        // 如果能发送成功，说明有权限
        await Future.delayed(const Duration(milliseconds: 500));
        await _notifications.cancel(99999);

        return true;
      } catch (testError) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 打开应用设置页面
  static Future<void> openAppSettings() async {
    await Permission.notification.request();
  }
}
