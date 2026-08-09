import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_notification.dart';

sealed class NotificationsState {
  const NotificationsState();
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

final class NotificationsSuccess extends NotificationsState {
  const NotificationsSuccess(this.notifications);

  final List<AppNotification> notifications;
}

final class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.failure);

  final ApiFailure failure;
}
