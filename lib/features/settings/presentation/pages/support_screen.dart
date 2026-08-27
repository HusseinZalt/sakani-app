import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';

/// شاشة الدعم الفني — معلومات تواصل ثابتة (بلا نموذج إرسال، لعدم وجود
/// نقطة نهاية بالباك إند لاستقبال طلبات الدعم حالياً).
///
/// ⚠️ القيم أدناه بيانات مؤقتة (placeholder) لحد ما تُستبدل ببيانات
/// التواصل الحقيقية لفريق الدعم.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _phoneNumber = '+963000000000';
  static const _whatsappNumber = '+963000000000';
  static const _email = 'support@example.com';
  static const _workingHours = 'الأحد – الخميس، 9 صباحاً – 4 عصراً';

  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذّر فتح التطبيق المطلوب.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: 'الدعم الفني',
              subtitle: 'تواصل معنا لأي استفسار أو مشكلة تقنية',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  CustomCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ContactTile(
                          icon: Icons.call_outlined,
                          title: 'اتصل بنا',
                          subtitle: _phoneNumber,
                          iconColor: AppColors.primary,
                          iconBackground: AppColors.primarySubtle,
                          onTap:
                              () => _launch(
                                context,
                                Uri(scheme: 'tel', path: _phoneNumber),
                              ),
                        ),
                        const Divider(height: 1),
                        _ContactTile(
                          icon: Icons.chat_outlined,
                          title: 'واتساب',
                          subtitle: _whatsappNumber,
                          iconColor: AppColors.success,
                          iconBackground: AppColors.successBackground,
                          onTap:
                              () => _launch(
                                context,
                                Uri.parse(
                                  'https://wa.me/${_whatsappNumber.replaceAll('+', '')}',
                                ),
                              ),
                        ),
                        const Divider(height: 1),
                        _ContactTile(
                          icon: Icons.email_outlined,
                          title: 'البريد الإلكتروني',
                          subtitle: _email,
                          iconColor: AppColors.secondaryDark,
                          iconBackground: AppColors.accentSubtle,
                          onTap:
                              () => _launch(
                                context,
                                Uri(scheme: 'mailto', path: _email),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'أوقات العمل',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _workingHours,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 16,
        color: AppColors.textHint,
      ),
    );
  }
}
