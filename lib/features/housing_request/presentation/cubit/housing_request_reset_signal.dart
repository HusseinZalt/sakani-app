/// إشارة لمرة واحدة تطلب من شاشة طلب السكن عرض نموذج تقديم فارغ فور
/// فتحها، حتى لو ما زال آخر طلب معروف عندها مرفوضاً.
///
/// [HousingRequestCubit] تبويب مستقل يبقى حيّاً بالذاكرة طوال الجلسة
/// (`StatefulShellRoute.indexedStack`)، وما إله وصول مباشر من نافذة
/// "طلبك انرفض" (تُعرض من الرئيسية أو من معالج إشعار حي، راجع
/// `home_screen.dart`/`push_notification_service.dart`) — فنستخدم هذه
/// الإشارة البسيطة بدل تمرير الحالة عبر أكثر من فرع تنقّل منفصل.
class HousingRequestResetSignal {
  const HousingRequestResetSignal._();

  static bool _pending = false;

  /// يُستدعى عند اختيار "إرسال طلب جديد" بنافذة الرفض.
  static void request() => _pending = true;

  /// يُستدعى مرة واحدة عند فتح شاشة طلب السكن؛ يُعيد true ويستهلك
  /// الإشارة إن كانت مطلوبة.
  static bool consume() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }
}
