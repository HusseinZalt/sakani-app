import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../network/api_result.dart';

/// عدّاد الإشعارات غير المقروءة — مصدر واحد يُوفَّر بجذر التطبيق ليُقرأ
/// من أي مكان (تبويب الإشعارات بالشريط السفلي) دون فتح شاشة الإشعارات
/// نفسها. [refresh] يعيد جلب العدد الحقيقي، بينما [decrement]/[increment]
/// تحديث فوري متفائل (Optimistic) بلا نداء شبكة إضافي.
class NotificationsBadgeCubit extends Cubit<int> {
  NotificationsBadgeCubit() : super(0);

  Future<void> refresh() async {
    final result = await NotificationsRepositoryImpl().fetchNotifications();
    if (result case ApiSuccess<List<AppNotification>>(:final data)) {
      emit(data.where((n) => n.isUnread).length);
    }
  }

  void decrement() {
    if (state > 0) emit(state - 1);
  }

  void increment() => emit(state + 1);
}
