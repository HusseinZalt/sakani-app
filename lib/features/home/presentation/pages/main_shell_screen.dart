import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/notifications_badge_cubit.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/profile_avatar.dart';

/// الحاوية الرئيسية (Shell) التي تضم شريط التنقل السفلي وتستضيف التبويبات
/// الخمسة المعتمدة (الملف، الإشعارات، الغروبات، طلب السكن، الرئيسية) عبر
/// [StatefulShellRoute] في GoRouter.
///
/// ترتيب التبويبات هنا يطابق ترتيبها في التصميم المعتمد (مجلد `UI/`)، بحيث
/// تنعكس بصرياً بفعل اتجاه RTL لتصبح "الرئيسية" في أقصى اليسار كما في
/// التصميم.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// فهرس تبويب "الرئيسية" ضمن [_destinations]/فروع الـ Shell — نقطة
  /// الرجوع الافتراضية عند الضغط على زر الرجوع من أي تبويب آخر.
  static const _homeBranchIndex = 4;

  /// فهرس تبويب "الإشعارات" — لمعرفة أين تُوضع شارة العدد غير المقروء.
  static const _notificationsBranchIndex = 1;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBadgeCubit>().refresh();
  }

  List<NavigationDestination> _destinations(int unreadCount) {
    final avatarUrl = context.watch<UserSessionCubit>().state?.avatarUrl;

    return [
      NavigationDestination(
        icon: _ProfileTabIcon(avatarUrl: avatarUrl, isSelected: false),
        selectedIcon: _ProfileTabIcon(avatarUrl: avatarUrl, isSelected: true),
        label: 'الملف',
      ),
      NavigationDestination(
        icon: _NotificationsIcon(
          unreadCount: unreadCount,
          icon: Icons.notifications_outlined,
        ),
        selectedIcon: _NotificationsIcon(
          unreadCount: unreadCount,
          icon: Icons.notifications_rounded,
        ),
        label: 'الإشعارات',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded),
        label: 'الغروبات',
      ),
      const NavigationDestination(
        icon: Icon(Icons.apartment_outlined),
        selectedIcon: Icon(Icons.apartment_rounded),
        label: 'طلب السكن',
      ),
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'الرئيسية',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isOnHomeBranch =
        widget.navigationShell.currentIndex == MainShellScreen._homeBranchIndex;

    // بدون هذا الاعتراض، ضغط زر الرجوع (نظام أندرويد) من أي تبويب غير
    // "الرئيسية" يُغلق التطبيق بالكامل مباشرة: كل تبويب هو جذر مستقل ضمن
    // StatefulShellRoute (IndexedStack) وليس فيه شيء يُنقض (pop) داخلياً،
    // فيصل الضغط لنظام التشغيل الذي يعتبره خروجاً من التطبيق. نعيد توجيهه
    // بدل ذلك للتبويب الرئيسي أولاً، ولا نسمح بالخروج الفعلي إلا منه.
    return PopScope(
      canPop: isOnHomeBranch,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.navigationShell.goBranch(MainShellScreen._homeBranchIndex);
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: BlocBuilder<NotificationsBadgeCubit, int>(
            builder: (context, unreadCount) {
              return NavigationBar(
                selectedIndex: widget.navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  if (index == MainShellScreen._notificationsBranchIndex) {
                    context.read<NotificationsBadgeCubit>().refresh();
                  }
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  );
                },
                destinations: _destinations(unreadCount),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// أيقونة تبويب "الملف" — تعرض صورة البروفايل الفعلية إن وُجدت بدل أيقونة
/// شخص عامة، مطابقةً لنفس التغيير بهيدر الرئيسية.
class _ProfileTabIcon extends StatelessWidget {
  const _ProfileTabIcon({required this.avatarUrl, required this.isSelected});

  final String? avatarUrl;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null) {
      return Icon(
        isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
      );
    }
    return ProfileAvatar(avatarUrl: avatarUrl, radius: 12);
  }
}

class _NotificationsIcon extends StatelessWidget {
  const _NotificationsIcon({required this.unreadCount, required this.icon});

  final int unreadCount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) return Icon(icon);
    return Badge(
      label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
      backgroundColor: AppColors.error,
      child: Icon(icon),
    );
  }
}
