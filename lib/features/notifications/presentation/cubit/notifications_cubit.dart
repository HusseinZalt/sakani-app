import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsInitial());

  final NotificationsRepository _repository;

  Future<void> fetchNotifications() async {
    emit(const NotificationsLoading());

    final result = await _repository.fetchNotifications();

    switch (result) {
      case ApiSuccess<List<AppNotification>>(:final data):
        emit(NotificationsSuccess(data));
      case ApiFailureResult<List<AppNotification>>(:final failure):
        emit(NotificationsFailure(failure));
    }
  }

  /// تعليم إشعار كمقروء (تحديث تفاؤلي فوري للحالة المحلية، دون انتظار
  /// استجابة الخادم، لأن هذه عملية غير حرجة ولا تحتاج مؤشر تحميل).
  /// إذا فشل الطلب في الخادم، نعود إلى الحالة السابقة فوراً حتى لا تبقى
  /// واجهة المستخدم غير متزامنة مع الواقع.
  Future<void> markAsRead(String id) async {
    final current = state;
    if (current is! NotificationsSuccess) return;
    if (!current.notifications.any((n) => n.id == id && n.isUnread)) return;

    final original = current.notifications;
    emit(
      NotificationsSuccess([
        for (final notification in current.notifications)
          if (notification.id == id)
            notification.copyWith(isUnread: false)
          else
            notification,
      ]),
    );

    final result = await _repository.markAsRead(id);
    if (result.isFailure) {
      emit(NotificationsSuccess(original));
    }
  }
}
