import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/utils/avatar_image.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../notifications/data/datasources/notifications_remote_data_source.dart';

/// شاشة الملف الشخصي للطالب (تبويب "الملف") — مطابقة للشاشة 8 من التصميم
/// المعتمد.
///
/// تقرأ بيانات المستخدم من [UserSessionCubit] — المصدر الوحيد لبيانات
/// المستخدم الحالي عبر التطبيق — بدل بيانات وهمية منفصلة خاصة بهذه
/// الشاشة، بحيث تنعكس أي تعديلات (من شاشة "تعديل البيانات") هنا فوراً.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserSessionCubit>().state;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(title: 'الملف الشخصي'),
          Expanded(
            child:
                user == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        CustomCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 42,
                                      backgroundColor: AppColors.primarySubtle,
                                      backgroundImage:
                                          user.avatarUrl != null
                                              ? avatarImageProvider(
                                                user.avatarUrl!,
                                              )
                                              : null,
                                      child:
                                          user.avatarUrl == null
                                              ? const Icon(
                                                Icons.person_outline_rounded,
                                                color: AppColors.primaryDark,
                                                size: 34,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      user.fullName,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (user.studentId != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'الرقم الجامعي: ${user.studentId}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              _ProfileInfoRow(
                                icon: Icons.email_outlined,
                                label: 'البريد الإلكتروني',
                                value: user.email,
                              ),
                              const Divider(height: 1),
                              _ProfileInfoRow(
                                icon: Icons.phone_outlined,
                                label: 'رقم الجوال',
                                value: user.phone,
                              ),
                              if (user.college != null) ...[
                                const Divider(height: 1),
                                _ProfileInfoRow(
                                  icon: Icons.school_outlined,
                                  label: 'الكلية',
                                  value: user.college!,
                                  isLtr: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _ProfileMenuTile(
                                icon: Icons.edit_outlined,
                                title: 'تعديل البيانات',
                                onTap:
                                    () => context.pushNamed(
                                      AppRoutes.editProfile,
                                    ),
                              ),
                              const Divider(height: 1),
                              _ProfileMenuTile(
                                icon: Icons.description_outlined,
                                title: 'المستندات',
                                onTap:
                                    () =>
                                        context.pushNamed(AppRoutes.documents),
                              ),
                              const Divider(height: 1),
                              _ProfileMenuTile(
                                icon: Icons.settings_outlined,
                                title: 'الإعدادات',
                                onTap:
                                    () => context.pushNamed(AppRoutes.settings),
                              ),
                              const Divider(height: 1),
                              _ProfileMenuTile(
                                icon: Icons.logout,
                                title: 'تسجيل الخروج',
                                titleColor: AppColors.error,
                                onTap: () async {
                                  final confirmed = await confirmAction(
                                    context,
                                    title: 'تسجيل الخروج',
                                    message:
                                        'هل أنت متأكد أنك تريد تسجيل الخروج؟',
                                    confirmLabel: 'تسجيل الخروج',
                                  );
                                  if (!confirmed || !context.mounted) return;

                                  final fcmToken =
                                      PushNotificationService.instance.fcmToken;
                                  if (fcmToken != null) {
                                    NotificationsRemoteDataSource()
                                        .unregisterDeviceToken(fcmToken);
                                  }
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
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLtr = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLtr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Directionality(
            textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
            child: Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.background,
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
          titleColor == null
              ? Icon(Icons.chevron_left, color: AppColors.textHint)
              : null,
    );
  }
}
