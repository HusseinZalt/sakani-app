import 'dart:convert';

import '../../../../core/utils/relative_time.dart';
import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.timeLabel,
    required super.colorKey,
    required super.isUnread,
    super.body,
    super.type,
    super.relatedId,
  });

  /// يحوّل عنصر `NotificationInboxItemDto` من خدمة الإشعارات الحقيقية
  /// (ASP.NET Core، راجع `/swagger`) إلى نموذج التطبيق.
  ///
  /// **مهم:** الحقل المستخدم كمعرّف هنا هو `notificationId` وليس
  /// `recipientId` — مؤكَّد بالاختبار الفعلي (2026-08-18) أن نقطة
  /// `POST /api/Notifications/{id}/read` تتوقّع `notificationId` (نفس
  /// فضاء المعرّفات المستخدم بكل نقاط `/api/Notifications/{id}` الأخرى)،
  /// وتحدّد "أي مستلم" عبر توكن الدخول تلقائياً، وليس عبر معرّف السجل
  /// الخاص بالمستلم.
  ///
  /// حقل `type`/`relatedId` (للتنقّل عند الضغط على الإشعار) غير موجودَين
  /// كحقلَين مستقلَّين بالـ DTO — يُفكَّان من حقل `data` النصي (JSON) الذي
  /// يُفترض أن يحمل نفس اصطلاح `{"type": "...", "relatedId": "..."}`
  /// المستخدم أصلاً في حمولة إشعارات Firebase (راجع
  /// `push_notification_service.dart`)، طالما التزم به مُصدرو الإشعارات
  /// (الخدمات الأخرى التي تستدعي `/api/Notifications/broadcast`).
  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? data;
    final rawData = json['data'] as String?;
    if (rawData != null && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        // حمولة data غير صالحة كـ JSON — تجاهلها، يبقى الإشعار قابلاً
        // للعرض بدون تنقّل خاص عند الضغط عليه.
      }
    }

    final type = data?['type'] as String?;
    final createdAt = DateTime.parse(json['createdAt'] as String);

    return AppNotificationModel(
      id: json['notificationId'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      createdAt: createdAt,
      timeLabel: formatRelativeTime(createdAt),
      colorKey: _colorKeyForType(type),
      isUnread: !(json['isRead'] as bool? ?? false),
      type: type,
      relatedId: data?['relatedId'] as String?,
    );
  }

  static String _colorKeyForType(String? type) {
    switch (type) {
      case 'housing':
        return 'success';
      case 'complaint':
        return 'accent';
      case 'group':
        return 'info';
      case 'maintenance':
        return 'warning';
      default:
        return 'neutral';
    }
  }
}
