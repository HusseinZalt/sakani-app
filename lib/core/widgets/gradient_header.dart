import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// رأس متدرج (Gradient Header) موحّد، مطابق لـ `.m-header` في التصميم
/// المعتمد، يُستخدم بدل AppBar التقليدي في معظم شاشات التطبيق الرئيسية.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.bottomPadding = 26,
    this.titleStyle,
  });

  /// العنوان الرئيسي للشاشة.
  final String title;

  /// نص فرعي اختياري يظهر أسفل العنوان.
  final String? subtitle;

  /// دالة تُنفذ عند الضغط على زر الرجوع؛ تمرير null يخفي الزر.
  final VoidCallback? onBack;

  /// عنصر اختياري يظهر في نهاية الرأس (مثل أيقونة إشعارات).
  final Widget? trailing;

  final double bottomPadding;

  /// نمط نص مخصص للعنوان (تُستخدم في شاشة الرئيسية لعرض ترحيب بحجم أكبر).
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
          child: Row(
            children: [
              if (onBack != null) ...[
                _CircleIconButton(icon: Icons.arrow_forward, onTap: onBack!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          titleStyle ??
                          theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }
}
