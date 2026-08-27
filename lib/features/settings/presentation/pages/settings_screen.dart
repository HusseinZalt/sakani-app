import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

/// شاشة إعدادات التطبيق — مطابقة للشاشة 12 من التصميم المعتمد.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _housingNotifications = true;
  bool _complaintsNotifications = true;
  bool _generalNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final housing = await NotificationPreferences.getHousingEnabled();
    final complaints = await NotificationPreferences.getComplaintsEnabled();
    final general = await NotificationPreferences.getGeneralEnabled();
    if (!mounted) return;
    setState(() {
      _housingNotifications = housing;
      _complaintsNotifications = complaints;
      _generalNotifications = general;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(title: 'الإعدادات', onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'المظهر',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _ThemeModeSelector(),
                  const SizedBox(height: 22),
                  Text(
                    'الإشعارات',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _housingNotifications,
                          onChanged: (value) {
                            setState(() => _housingNotifications = value);
                            NotificationPreferences.setHousingEnabled(value);
                          },
                          title: const Text('إشعارات طلبات السكن'),
                          subtitle: const Text('تحديثات حالة الطلب والدفع'),
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _complaintsNotifications,
                          onChanged: (value) {
                            setState(() => _complaintsNotifications = value);
                            NotificationPreferences.setComplaintsEnabled(value);
                          },
                          title: const Text('إشعارات الشكاوى والاقتراحات'),
                          subtitle: const Text('ردود الإدارة'),
                          activeColor: AppColors.primary,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: _generalNotifications,
                          onChanged: (value) {
                            setState(() => _generalNotifications = value);
                            NotificationPreferences.setGeneralEnabled(value);
                          },
                          title: const Text('إشعارات عامة'),
                          subtitle: const Text(
                            'إعلانات وتنبيهات المدينة الجامعية',
                          ),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'الخصوصية والأمان',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsMenuTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'تغيير كلمة المرور',
                          onTap:
                              () => context.pushNamed(AppRoutes.changePassword),
                        ),
                        const Divider(height: 1),
                        _SettingsMenuTile(
                          icon: Icons.shield_outlined,
                          title: 'سياسة الخصوصية',
                          onTap:
                              () => context.pushNamed(AppRoutes.privacyPolicy),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'المساعدة',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsMenuTile(
                          icon: Icons.support_agent_outlined,
                          title: 'الدعم الفني',
                          onTap: () => context.pushNamed(AppRoutes.support),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'الملف الشخصي',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsMenuTile(
                          icon: Icons.person_outline_rounded,
                          title: 'عرض/تعديل البروفايل',
                          onTap: () => context.pushNamed(AppRoutes.editProfile),
                        ),
                        const Divider(height: 1),
                        _SettingsMenuTile(
                          icon: Icons.logout,
                          title: 'تسجيل الخروج',
                          titleColor: AppColors.error,
                          onTap: () async {
                            final confirmed = await confirmAction(
                              context,
                              title: 'تسجيل الخروج',
                              message: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                              confirmLabel: 'تسجيل الخروج',
                            );
                            if (!confirmed || !context.mounted) return;

                            AuthRepositoryImpl().logout();
                            context.read<UserSessionCubit>().clear();
                            if (!context.mounted) return;
                            context.goNamed(AppRoutes.login);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDestructive = titleColor != null;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color:
              isDestructive ? AppColors.errorBackground : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: titleColor ?? AppColors.textSecondary,
          size: 18,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: titleColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing:
          !isDestructive
              ? Icon(Icons.chevron_left, color: AppColors.textHint)
              : null,
    );
  }
}

/// مُحدِّد وضع المظهر (فاتح / داكن / حسب النظام) — يقرأ ويبدّل [ThemeController]
/// المزوَّد في جذر التطبيق، ويُخزَّن الاختيار محلياً تلقائياً عبر المتحكم نفسه.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  static const _options = [
    (mode: ThemeMode.light, label: 'فاتح', icon: Icons.light_mode_rounded),
    (mode: ThemeMode.dark, label: 'داكن', icon: Icons.dark_mode_rounded),
    (
      mode: ThemeMode.system,
      label: 'حسب النظام',
      icon: Icons.brightness_auto_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    return CustomCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          for (final option in _options)
            Expanded(
              child: _ThemeOptionButton(
                label: option.label,
                icon: option.icon,
                selected: controller.mode == option.mode,
                onTap:
                    () => context.read<ThemeController>().setMode(option.mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  const _ThemeOptionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
