import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// شاشة الإشعارات، مجمّعة حسب اليوم (اليوم/أمس/الأسبوع الماضي/أقدم) —
/// مطابقة للشاشة 7 من التصميم المعتمد.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              NotificationsCubit(NotificationsRepositoryImpl())
                ..fetchNotifications(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  // يمنع فتح شاشتين متتاليتين عند الضغط المزدوج على نفس الإشعار أثناء
  // التنقل (خاصة إشعارات الشكاوى التي تنتظر جلب البيانات أولاً).
  bool _isNavigating = false;

  Future<void> _handleTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (_isNavigating) return;
    _isNavigating = true;

    context.read<NotificationsCubit>().markAsRead(notification.id);

    switch (notification.type) {
      case 'housing':
        context.goNamed(AppRoutes.housingRequest);
      case 'group':
        context.goNamed(AppRoutes.groups);
      case 'profile':
        context.goNamed(AppRoutes.profile);
      case 'maintenance':
        await context.pushNamed(AppRoutes.maintenanceList);
      case 'complaint':
        final id = notification.relatedId;
        if (id != null) {
          await context.pushNamed(
            AppRoutes.complaintDetails,
            pathParameters: {'id': id},
          );
        } else {
          await context.pushNamed(AppRoutes.complaints);
        }
      case 'ad':
        final id = notification.relatedId;
        if (id != null) {
          await context.pushNamed(
            AppRoutes.adDetails,
            pathParameters: {'id': id},
          );
        }
      default:
        break;
    }

    _isNavigating = false;
  }

  static Map<String, Color> get _colors => {
    'success': AppColors.success,
    'accent': AppColors.accent,
    'info': AppColors.primary,
    'warning': AppColors.secondaryDark,
    'neutral': AppColors.textHint,
  };

  static Map<String, Color> get _backgrounds => {
    'success': AppColors.successBackground,
    'accent': AppColors.accentSubtle,
    'info': AppColors.primarySubtle,
    'warning': AppColors.warningBackground,
    'neutral': AppColors.surfaceVariant,
  };

  static const _icons = {
    'success': Icons.check_circle_outline_rounded,
    'accent': Icons.outlined_flag_rounded,
    'info': Icons.people_outline_rounded,
    'warning': Icons.build_outlined,
    'neutral': Icons.person_outline_rounded,
  };

  Map<String, List<AppNotification>> _groupByDay(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final weekAgo = today.subtract(const Duration(days: 7));
    final groups = <String, List<AppNotification>>{
      'اليوم': [],
      'أمس': [],
      'الأسبوع الماضي': [],
      'أقدم': [],
    };

    for (final notification in notifications) {
      final date = notification.createdAt.toLocal();
      final day = DateTime(date.year, date.month, date.day);
      if (day == today) {
        groups['اليوم']!.add(notification);
      } else if (day == yesterday) {
        groups['أمس']!.add(notification);
      } else if (day.isAfter(weekAgo)) {
        groups['الأسبوع الماضي']!.add(notification);
      } else {
        groups['أقدم']!.add(notification);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(
            title: 'الإشعارات',
            subtitle: 'آخر التحديثات الخاصة بك',
          ),
          Expanded(
            child: BlocBuilder<NotificationsCubit, NotificationsState>(
              builder: (context, state) {
                return switch (state) {
                  NotificationsInitial() || NotificationsLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  NotificationsFailure(:final failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(failure.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed:
                                () =>
                                    context
                                        .read<NotificationsCubit>()
                                        .fetchNotifications(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  NotificationsSuccess(:final notifications) =>
                    notifications.isEmpty
                        ? Center(
                          child: Text(
                            'لا توجد إشعارات حتى الآن',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh:
                              () =>
                                  context
                                      .read<NotificationsCubit>()
                                      .fetchNotifications(),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                            children: [
                              for (final entry
                                  in _groupByDay(notifications).entries) ...[
                                Text(
                                  entry.key,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelLarge?.copyWith(
                                    color: AppColors.textHint,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CustomCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < entry.value.length;
                                        i++
                                      ) ...[
                                        if (i > 0) const Divider(height: 1),
                                        _NotificationRow(
                                          notification: entry.value[i],
                                          iconColor:
                                              _colors[entry
                                                  .value[i]
                                                  .colorKey] ??
                                              AppColors.textHint,
                                          iconBackground:
                                              _backgrounds[entry
                                                  .value[i]
                                                  .colorKey] ??
                                              AppColors.surfaceVariant,
                                          icon:
                                              _icons[entry.value[i].colorKey] ??
                                              Icons.notifications_outlined,
                                          onTap:
                                              () => _handleTap(
                                                context,
                                                entry.value[i],
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ],
                          ),
                        ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.iconColor,
    required this.iconBackground,
    required this.icon,
    required this.onTap,
  });

  final AppNotification notification;
  final Color iconColor;
  final Color iconBackground;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.timeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
