import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/housing_request/data/repositories/housing_request_repository_impl.dart';
import '../../features/housing_request/domain/entities/housing_request.dart';
import '../../features/housing_request/presentation/cubit/housing_request_reset_signal.dart';
import '../events/app_refresh_bus.dart';
import '../network/api_result.dart';
import '../routing/app_router.dart';
import '../widgets/housing_rejected_dialog.dart';
import 'notification_preferences.dart';
import 'notifications_badge_cubit.dart';

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
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
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

    // يحدّث شارة العدد غير المقروء بتبويب الإشعارات فوراً — نفس الطريقة
    // المستخدمة أصلاً للتنقّل بـ[_navigateFromData] (`context` عبر مفتاح
    // الملّاح الجذري)، لأن هذه خدمة مفردة مستقلة عن شجرة الواجهات.
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.read<NotificationsBadgeCubit>().increment();
    }

    // يطلب من أي شاشة معنية حيّة بالذاكرة تحديث نفسها فوراً — راجع توثيق
    // [AppRefreshBus] لسبب الحاجة لهذا بالتحديد (وصول إشعار حي والمستخدم
    // أصلاً واقف على نفس الشاشة، حيث لا ينفع الاعتماد وحده على تحديث
    // العودة لتبويب). أي إشعار مهما كان نوعه يظهر أولاً كسجل بصندوق
    // الوارد، فتُحدَّث قائمة الإشعارات دائماً، إضافة لموضوع أكثر تحديداً
    // إن وُجد.
    AppRefreshBus.emit(RefreshTopic.notifications);
    switch (type) {
      case 'housing':
        AppRefreshBus.emit(RefreshTopic.housingRequest);
      case 'maintenance':
        AppRefreshBus.emit(RefreshTopic.maintenance);
      case 'complaint':
        AppRefreshBus.emit(RefreshTopic.complaints);
      default:
        // كل أنواع الغروب (`group`, `group_join_request`,
        // `group_member_removed`...) تبدأ بنفس البادئة — راجع
        // `app_notification_model.dart` لقائمة الأنواع المؤكَّدة فعلياً.
        if (type != null && type.startsWith('group')) {
          AppRefreshBus.emit(RefreshTopic.groups);
        }
    }

    // إشعارات "housing" عامة (قيد المراجعة/قرار...)، فنتحقق من الحالة
    // الفعلية لمعرفة إذا كانت رفضاً تحديداً — عندها تظهر نافذة "طلبك
    // انرفض" فوراً فوق أي شاشة مفتوحة، بنفس منطق نافذة الرئيسية عند فتح
    // التطبيق (راجع `home_screen.dart`) لكن أثناء استخدام فعلي للتطبيق.
    if (type == 'housing') {
      unawaited(_checkForRejectionAndAlert());
    }
  }

  Future<void> _checkForRejectionAndAlert() async {
    final result = await HousingRequestRepositoryImpl().fetchMyRequest();
    if (result is! ApiSuccess<HousingRequest?>) return;

    final request = result.data;
    if (request == null ||
        request.decision?.status != AdmissionDecisionStatus.rejected) {
      return;
    }

    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    await showHousingRejectedDialog(
      context,
      reason: request.decision?.decisionReason,
      onCancel: () {},
      onResubmit: () {
        HousingRequestResetSignal.request();
        AppRouter.router.goNamed(AppRoutes.housingRequest);
      },
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
