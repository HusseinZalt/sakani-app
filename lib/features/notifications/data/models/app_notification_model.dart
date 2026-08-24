import 'dart:convert';

import '../../../../core/utils/parse_utc_date_time.dart';
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
  /// كحقلَين مستقلَّين بالـ DTO — يُفكَّان من حقل `data` النصي (JSON).
  /// معظم الخدمات تلتزم باصطلاح `{"type": "...", "relatedId": "..."}`
  /// المستخدم أصلاً في حمولة إشعارات Firebase (راجع
  /// `push_notification_service.dart`)، **لكن خدمة الإعلانات تخالفه** —
  /// مؤكَّد بالاستجابة الفعلية (2026-08-20): `data` عندها
  /// `{"adId": "..."}` فقط، بلا حقل `type` إطلاقاً. لهذا نستنتج `type:
  /// 'ad'` ضمنياً عند وجود `adId` (بدل الاعتماد فقط على `data['type']`
  /// الصريح)، وإلا كانت كل إشعارات الإعلانات تصل بدون أي تنقّل عند
  /// الضغط عليها.
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

    final adId = data?['adId'] as String?;
    final type = (data?['type'] as String?) ?? (adId != null ? 'ad' : null);
    final relatedId = (data?['relatedId'] as String?) ?? adId;
    final createdAt = parseUtcDateTime(json['createdAt'] as String);
    final title = json['title'] as String? ?? '';

    return AppNotificationModel(
      id: json['notificationId'].toString(),
      title: title,
      body: json['body'] as String?,
      createdAt: createdAt,
      timeLabel: formatRelativeTime(createdAt),
      colorKey: _colorKeyForType(type, title),
      isUnread: !(json['isRead'] as bool? ?? false),
      type: type,
      relatedId: relatedId,
    );
  }

  /// خدمة السكن ترسل كل إشعاراتها بنفس `type: "housing"` بغض النظر عن
  /// كون القرار قبولاً أو رفضاً — نميّز بينهما من نص العنوان نفسه
  /// (مؤكَّد بالاختبار الفعلي: "تم قبول طلب التسكين" / "تم رفض طلب
  /// التسكين") بدل تلوين الرفض بنفس أخضر النجاح.
  static String _colorKeyForType(String? type, String title) {
    if (type == 'housing') {
      if (title.contains('رفض')) return 'error';
      if (title.contains('قبول')) return 'celebration';
      return 'success';
    }
    switch (type) {
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
