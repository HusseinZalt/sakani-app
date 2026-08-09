import '../../../../core/session/mock_current_user.dart';
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
  static const _placeholderUserId = 'usr_1001';
  static const _placeholderUserName = 'أحمد محمد';

  static String? _currentUserId;
  static bool _seedPatched = false;

  static final List<AppNotificationModel> _notifications = _buildInitial();

  static List<AppNotificationModel> _buildInitial() {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'ntf_1',
        userId: _placeholderUserId,
        title: 'تم قبول طلب السكن الخاص بك',
        createdAt: now.subtract(const Duration(hours: 2)),
        timeLabel: 'منذ ساعتين',
        colorKey: 'success',
        isUnread: true,
        type: 'housing',
      ),
      AppNotificationModel(
        id: 'ntf_2',
        userId: _placeholderUserId,
        title: 'رد الإدارة على اقتراحك',
        createdAt: now.subtract(const Duration(hours: 4)),
        timeLabel: 'منذ 4 ساعات',
        colorKey: 'accent',
        isUnread: true,
        type: 'complaint',
        relatedId: 'cmp_6002',
      ),
      AppNotificationModel(
        id: 'ntf_3',
        userId: _placeholderUserId,
        title: 'انضممت إلى غروب الوحدة أ',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        timeLabel: 'أمس، 6:40 م',
        colorKey: 'info',
        isUnread: false,
        type: 'group',
      ),
      AppNotificationModel(
        id: 'ntf_4',
        userId: _placeholderUserId,
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
        userId: _placeholderUserId,
        title: 'تم تحديث بيانات حسابك',
        createdAt: now.subtract(const Duration(days: 6)),
        timeLabel: 'منذ 6 أيام',
        colorKey: 'neutral',
        isUnread: false,
        type: 'profile',
      ),
    ];
  }

  Future<void> _ensureCurrentUser() async {
    if (_currentUserId != null) return;

    final resolved = await MockCurrentUser.resolve(
      placeholderId: _placeholderUserId,
      placeholderName: _placeholderUserName,
    );
    _currentUserId = resolved.id;

    if (_seedPatched || resolved.id == _placeholderUserId) return;
    _seedPatched = true;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId != _placeholderUserId) continue;
      _notifications[i] = AppNotificationModel(
        id: _notifications[i].id,
        userId: resolved.id,
        title: _notifications[i].title,
        createdAt: _notifications[i].createdAt,
        timeLabel: _notifications[i].timeLabel,
        colorKey: _notifications[i].colorKey,
        isUnread: _notifications[i].isUnread,
        type: _notifications[i].type,
        relatedId: _notifications[i].relatedId,
      );
    }
  }

  Future<List<AppNotificationModel>> fetchNotifications() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);
    return _notifications.where((n) => n.userId == _currentUserId).toList();
  }

  Future<void> markAsRead(String id) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);
    final index = _notifications.indexWhere(
      (n) => n.id == id && n.userId == _currentUserId,
    );
    if (index == -1) return;
    _notifications[index] = AppNotificationModel(
      id: _notifications[index].id,
      userId: _notifications[index].userId,
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
