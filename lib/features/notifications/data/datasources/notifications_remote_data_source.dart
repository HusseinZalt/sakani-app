import '../models/app_notification_model.dart';

/// مصدر بيانات الإشعارات.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات
/// مشتركة (static) في الذاكرة + محاكاة زمن استجابة الشبكة). عند الربط
/// الحقيقي، يكفي استبدال محتوى هذا الملف بطلبات HTTP فعلية (مثال:
/// `GET /api/notifications`, `POST /api/notifications/:id/read`) دون أي
/// تعديل على الـ Repository أو الـ Cubit أو الشاشة.
/// ==================================================================
class NotificationsRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 600);

  static final List<AppNotificationModel> _notifications = _buildInitial();

  static List<AppNotificationModel> _buildInitial() {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'ntf_1',
        title: 'تم قبول طلب السكن الخاص بك',
        createdAt: now.subtract(const Duration(hours: 2)),
        timeLabel: 'منذ ساعتين',
        colorKey: 'success',
        isUnread: true,
        type: 'housing',
      ),
      AppNotificationModel(
        id: 'ntf_2',
        title: 'رد الإدارة على اقتراحك',
        createdAt: now.subtract(const Duration(hours: 4)),
        timeLabel: 'منذ 4 ساعات',
        colorKey: 'accent',
        isUnread: true,
        type: 'complaint',
        relatedId: 'cmp_6001',
      ),
      AppNotificationModel(
        id: 'ntf_3',
        title: 'انضممت إلى غروب الوحدة أ',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        timeLabel: 'أمس، 6:40 م',
        colorKey: 'info',
        isUnread: false,
        type: 'group',
      ),
      AppNotificationModel(
        id: 'ntf_4',
        title: 'تحديث حالة طلب الخدمة',
        createdAt: now.subtract(const Duration(days: 1, hours: 7)),
        timeLabel: 'أمس، 2:15 م',
        colorKey: 'warning',
        isUnread: false,
        type: 'maintenance',
        relatedId: 'mnt_5001',
      ),
      AppNotificationModel(
        id: 'ntf_5',
        title: 'تم تحديث بيانات حسابك',
        createdAt: now.subtract(const Duration(days: 6)),
        timeLabel: 'منذ 6 أيام',
        colorKey: 'neutral',
        isUnread: false,
        type: 'profile',
      ),
    ];
  }

  Future<List<AppNotificationModel>> fetchNotifications() async {
    await Future.delayed(_networkDelay);
    return List.of(_notifications);
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(_networkDelay);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = AppNotificationModel(
      id: _notifications[index].id,
      title: _notifications[index].title,
      createdAt: _notifications[index].createdAt,
      timeLabel: _notifications[index].timeLabel,
      colorKey: _notifications[index].colorKey,
      isUnread: false,
      type: _notifications[index].type,
      relatedId: _notifications[index].relatedId,
    );
  }
}
