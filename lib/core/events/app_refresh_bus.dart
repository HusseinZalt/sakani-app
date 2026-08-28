import 'dart:async';

/// المواضيع التي يمكن طلب تحديثها فوراً عبر [AppRefreshBus] — كل قيمة
/// تقابل تبويباً/شاشة له Cubit طويل العمر يمكنه الاستماع لها.
enum RefreshTopic { notifications, groups, housingRequest, maintenance, complaints }

/// ناقل أحداث بسيط لطلب "تحديث فوري" عبر التطبيق، دون أي اعتماد بين
/// الطبقات (لا [PushNotificationService] يعرف شيئاً عن أي Cubit تحديداً،
/// ولا الـ Cubits تعرف شيئاً عن الإشعارات).
///
/// المشكلة التي يحلّها: كل تبويبات `StatefulShellRoute.indexedStack`
/// تبقى حيّة بالذاكرة طوال الجلسة (راجع `refresh_on_tab_visible.dart`)،
/// وهذا يحل مشكلة "الرجوع لتبويب قديم البيانات" فقط — لا يحل مشكلة وصول
/// إشعار حي (Push) بينما المستخدم أصلاً واقف على نفس الشاشة المعنية:
/// فلا تبديل تبويب يحصل لإطلاق `RefreshOnTabVisible`، فتبقى الشاشة
/// تعرض بيانات قديمة حتى يسحب المستخدم للتحديث يدوياً بنفسه.
///
/// [PushNotificationService] يُصدر الموضوع المناسب عند وصول إشعار حي
/// والتطبيق مفتوح (`onMessage`)، وكل Cubit معني يستمع لموضوعه فقط
/// ويعيد الجلب بهدوء (دون مؤشر تحميل كامل يُخفي المحتوى الحالي).
class AppRefreshBus {
  const AppRefreshBus._();

  static final _controller = StreamController<RefreshTopic>.broadcast();

  static Stream<RefreshTopic> get stream => _controller.stream;

  static void emit(RefreshTopic topic) => _controller.add(topic);
}
