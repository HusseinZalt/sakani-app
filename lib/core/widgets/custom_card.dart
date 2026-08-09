import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// بطاقة موحّدة (Container مصمم كبطاقة) تُستخدم كأساس لعرض عناصر القوائم
/// (السكنات، الخدمات، الشكاوى...) بمظهر متسق عبر التطبيق.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.backgroundColor,
    this.borderRadius = 18,
    this.showBorder = true,
    this.elevation = 0,
  });

  /// محتوى البطاقة.
  final Widget child;

  /// دالة تُنفذ عند الضغط على البطاقة، تُضيف تلقائياً تأثير الضغط (InkWell).
  final VoidCallback? onTap;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double borderRadius;

  /// إظهار حدود خفيفة حول البطاقة.
  final bool showBorder;

  /// ظل البطاقة (0 = بدون ظل، اعتماداً على الحدود فقط).
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: radius,
        border: showBorder ? Border.all(color: AppColors.border) : null,
        boxShadow:
            elevation > 0
                ? [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: elevation * 4,
                    offset: Offset(0, elevation),
                  ),
                ]
                : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
