import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routing/app_router.dart';
import 'notification_preferences.dart';

/// معالج الإشعارات الواردة والتطبيق مغلق تماماً أو بالخلفية — يجب أن يكون
/// دالة top-level (وليس تابعاً لصنف) حسب متطلبات حزمة firebase_messaging،
/// ومُعلَّمة بـ `@pragma('vm:entry-point')` حتى لا يزيلها الـ tree-shaking
/// عند البناء لأنها تُستدعى من كود أصلي (native) وليس من Dart مباشرة.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// خدمة الإشعارات الفورية (Firebase Cloud Messaging) — مسؤولة عن: طلب
/// إذن الإشعارات، جلب رمز الجهاز (FCM Token)، عرض إشعار محلي عند وصول
/// رسالة والتطبيق مفتوح (FCM لا يعرضها تلقائياً بهذه الحالة على أندرويد)،
/// والتنقّل للشاشة المناسبة عند الضغط على الإشعار.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** [fcmToken] يُرسَل ضمن جسم طلب تسجيل
/// الدخول/التسجيل (`auth_remote_data_source.dart`) — المصدر الوحيد
/// لتسجيله لدى الباك إند (لا توجد نقطة تسجيل جهاز منفصلة، راجع
/// `Gateway_Guide.md`). يعني هذا أن تغيّر الرمز (نادر) بينما المستخدم
/// لا يزال بجلسة سابقة دون إعادة تسجيل دخول لن يُبلَّغ للباك إند — قيد
/// معروف بتصميم الباك إند الحالي، وليس نقصاً بالتطبيق.
/// ==================================================================
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _defaultChannel = AndroidNotificationChannel(
    'sakani_default_channel',
    'إشعارات سكني',
    description: 'إشعارات عامة من تطبيق سكني',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _initLocalNotifications();

    _fcmToken = await FirebaseMessaging.instance.getToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _fcmToken = token;
    });

    // التطبيق مفتوح حالياً (foreground): FCM لا يعرض الإشعار تلقائياً على
    // أندرويد بهذه الحالة، فنعرضه يدوياً عبر flutter_local_notifications.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // التطبيق كان بالخلفية وفُتح بالضغط على الإشعار.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigateFromData(message.data),
    );

    // التطبيق كان مغلقاً تماماً وفُتح بالضغط على الإشعار.
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _navigateFromData(initialMessage.data);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateFromData(data);
        } catch (_) {
          // تجاهل حمولة غير صالحة بدل تعطّل التطبيق.
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_defaultChannel);
  }

  /// ⚠️ يمنع فقط عرض الإشعار المحلي عندما يكون التطبيق مفتوحاً (foreground).
  /// إشعارات النظام يوم يكون التطبيق بالخلفية أو مغلقاً تماماً يعرضها
  /// أندرويد تلقائياً من حمولة FCM نفسها قبل ما يشتغل أي كود Dart هون —
  /// كتمها فعلياً بهاي الحالة يحتاج تعاون من الباك إند (يتحقق من تفضيلات
  /// الجهاز المسجَّلة قبل الإرسال، أو يبعت حمولة بيانات فقط بدون `notification`).
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    final enabled = await NotificationPreferences.isEnabledForType(type);
    if (!enabled) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _defaultChannel.id,
          _defaultChannel.name,
          channelDescription: _defaultChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// يوجّه المستخدم للشاشة المناسبة حسب حمولة الإشعار (`type`/`relatedId`)،
  /// بنفس منطق التنقّل المستخدم أصلاً بقائمة الإشعارات داخل التطبيق
  /// (`notifications_screen.dart`) حتى يتصرف إشعار الدفع الحقيقي بنفس
  /// طريقة الإشعار المحلي بالضبط.
  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final relatedId = data['relatedId'] as String?;
    final router = AppRouter.router;

    switch (type) {
      case 'housing':
        router.goNamed(AppRoutes.housingRequest);
      case 'group':
        router.goNamed(AppRoutes.groups);
      case 'profile':
        router.goNamed(AppRoutes.profile);
      case 'maintenance':
        router.pushNamed(AppRoutes.maintenanceList);
      case 'complaint':
        if (relatedId != null) {
          router.pushNamed(
            AppRoutes.complaintDetails,
            pathParameters: {'id': relatedId},
          );
        } else {
          router.pushNamed(AppRoutes.complaints);
        }
      case 'ad':
        if (relatedId != null) {
          router.pushNamed(
            AppRoutes.adDetails,
            pathParameters: {'id': relatedId},
          );
        }
      default:
        if (kDebugMode) {
          debugPrint('إشعار بدون نوع تنقّل معروف: $data');
        }
    }
  }
}
