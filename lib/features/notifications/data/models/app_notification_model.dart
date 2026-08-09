import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.timeLabel,
    required super.colorKey,
    required super.isUnread,
    super.type,
    super.relatedId,
  });
}
