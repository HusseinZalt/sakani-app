import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

/// الحاوية الرئيسية (Shell) التي تضم شريط التنقل السفلي وتستضيف التبويبات
/// الخمسة المعتمدة (الملف، الإشعارات، الغروبات، طلب السكن، الرئيسية) عبر
/// [StatefulShellRoute] في GoRouter.
///
/// ترتيب التبويبات هنا يطابق ترتيبها في التصميم المعتمد (مجلد `UI/`)، بحيث
/// تنعكس بصرياً بفعل اتجاه RTL لتصبح "الرئيسية" في أقصى اليسار كما في
/// التصميم.
class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'الملف',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications_rounded),
      label: 'الإشعارات',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'الغروبات',
    ),
    NavigationDestination(
      icon: Icon(Icons.apartment_outlined),
      selectedIcon: Icon(Icons.apartment_rounded),
      label: 'طلب السكن',
    ),
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'الرئيسية',
    ),
  ];

  /// فهرس تبويب "الرئيسية" ضمن [_destinations]/فروع الـ Shell — نقطة
  /// الرجوع الافتراضية عند الضغط على زر الرجوع من أي تبويب آخر.
  static const _homeBranchIndex = 4;

  @override
  Widget build(BuildContext context) {
    final isOnHomeBranch = navigationShell.currentIndex == _homeBranchIndex;

    // بدون هذا الاعتراض، ضغط زر الرجوع (نظام أندرويد) من أي تبويب غير
    // "الرئيسية" يُغلق التطبيق بالكامل مباشرة: كل تبويب هو جذر مستقل ضمن
    // StatefulShellRoute (IndexedStack) وليس فيه شيء يُنقض (pop) داخلياً،
    // فيصل الضغط لنظام التشغيل الذي يعتبره خروجاً من التطبيق. نعيد توجيهه
    // بدل ذلك للتبويب الرئيسي أولاً، ولا نسمح بالخروج الفعلي إلا منه.
    return PopScope(
      canPop: isOnHomeBranch,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(_homeBranchIndex);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected:
                (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}
