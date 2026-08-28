import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/app_refresh_bus.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsInitial()) {
    // يجلب فوراً عند وصول إشعار حي والمستخدم أصلاً واقف على هذا التبويب
    // (راجع توثيق [AppRefreshBus]) — بدون هذا، إشعار وصل والمستخدم على
    // نفس شاشة الإشعارات لن يظهر إلا بسحب يدوي للتحديث.
    _refreshSubscription = AppRefreshBus.stream
        .where((topic) => topic == RefreshTopic.notifications)
        .listen((_) => fetchNotifications());
  }

  final NotificationsRepository _repository;
  StreamSubscription<RefreshTopic>? _refreshSubscription;

  /// عند استدعاء متكرر (تحديث حي أو سحب للتحديث) وسبق أن ظهرت بيانات
  /// ناجحة، لا نُظهر شاشة تحميل كاملة من جديد — نُبقي المحتوى الحالي
  /// ونستبدله بهدوء فقط عند وصول النتيجة الجديدة.
  Future<void> fetchNotifications() async {
    if (state is! NotificationsSuccess) emit(const NotificationsLoading());

    final result = await _repository.fetchNotifications();

    switch (result) {
      case ApiSuccess<List<AppNotification>>(:final data):
        emit(NotificationsSuccess(data));
      case ApiFailureResult<List<AppNotification>>(:final failure):
        emit(NotificationsFailure(failure));
    }
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
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
