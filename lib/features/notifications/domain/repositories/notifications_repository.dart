import '../../../../core/network/api_result.dart';
import '../entities/app_notification.dart';

/// عقد (Interface) طبقة الإشعارات، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API حقيقي مستقبلاً).
abstract class NotificationsRepository {
  /// جلب جميع إشعارات المستخدم الحالي، الأحدث أولاً.
  Future<ApiResult<List<AppNotification>>> fetchNotifications();

  /// تعليم إشعار واحد كمقروء.
  Future<ApiResult<void>> markAsRead(String id);
}
