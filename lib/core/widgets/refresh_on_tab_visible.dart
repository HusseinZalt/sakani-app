import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// يستدعي [onVisible] في كل مرة يصبح فيها هذا الفرع هو التبويب الظاهر
/// فعلياً على الشاشة ضمن `StatefulShellRoute`.
///
/// كل فروع `StatefulShellRoute.indexedStack` تبقى حيّة بالذاكرة دائماً
/// (IndexedStack)، أي أن الشاشة وحالتها (BlocProvider) تُنشأ مرة واحدة
/// فقط عند أول زيارة للتبويب ولا تُعاد أبداً عند التنقّل بينه وبين
/// تبويبات أخرى — فأي بيانات جلبتها الشاشة تبقى كما هي حتى لو تغيّرت
/// فعلياً على الخادم (مثال مؤكَّد: حالة طلب سكن تُقبل بينما المستخدم على
/// تبويب آخر، فتبقى الشاشة تعرض "قيد المراجعة" حتى بعد العودة إليها).
/// GoRouter يُفعّل/يعطّل [TickerMode] تلقائياً لكل فرع حسب ظهوره
/// (`Offstage` + `TickerMode(enabled: isActive)`) — نعتمد على هذه
/// الإشارة الجاهزة بدل بناء آلية مخصّصة.
class RefreshOnTabVisible extends StatefulWidget {
  const RefreshOnTabVisible({
    super.key,
    required this.onVisible,
    required this.child,
  });

  final VoidCallback onVisible;
  final Widget child;

  @override
  State<RefreshOnTabVisible> createState() => _RefreshOnTabVisibleState();
}

class _RefreshOnTabVisibleState extends State<RefreshOnTabVisible> {
  ValueListenable<bool>? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = TickerMode.getNotifier(context);
    if (!identical(next, _notifier)) {
      _notifier?.removeListener(_handleChange);
      _notifier = next..addListener(_handleChange);
    }
  }

  void _handleChange() {
    if (_notifier?.value ?? false) widget.onVisible();
  }

  @override
  void dispose() {
    _notifier?.removeListener(_handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
