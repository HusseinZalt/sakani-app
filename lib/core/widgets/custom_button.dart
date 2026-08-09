import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// أنواع أزرار [CustomButton] الموحدة عبر التطبيق.
enum CustomButtonType {
  /// زر معبأ بلون أساسي (Primary).
  filled,

  /// زر بحدود فقط بدون تعبئة.
  outlined,

  /// زر نصي بدون خلفية أو حدود.
  text,
}

/// زر موحّد قابل لإعادة الاستخدام في كامل التطبيق، يدعم حالة التحميل
/// والتعطيل والأيقونات، مع الالتزام بثيم التطبيق تلقائياً.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = CustomButtonType.filled,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// نص الزر.
  final String label;

  /// دالة تُنفذ عند الضغط. تمرير null يعطّل الزر تلقائياً.
  final VoidCallback? onPressed;

  /// نوع الزر (معبأ / محدد / نصي).
  final CustomButtonType type;

  /// إظهار مؤشر تحميل بدل النص، مع تعطيل الضغط تلقائياً.
  final bool isLoading;

  /// أيقونة اختيارية تظهر قبل النص.
  final IconData? icon;

  /// عرض الزر، افتراضياً يمتد لكامل العرض المتاح.
  final double? width;

  /// ارتفاع الزر.
  final double height;

  /// لون خلفية مخصص (يتجاوز لون الثيم الافتراضي) - يُستخدم مع النوع filled فقط.
  final Color? backgroundColor;

  /// لون نص/أيقونة مخصص.
  final Color? foregroundColor;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final child =
        isLoading
            ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _loadingColor(context),
                ),
              ),
            )
            : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            );

    final Widget button = switch (type) {
      CustomButtonType.filled => ElevatedButton(
        onPressed: _isDisabled ? null : onPressed,
        style:
            backgroundColor != null || foregroundColor != null
                ? ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor ?? AppColors.primary,
                  foregroundColor: foregroundColor ?? AppColors.onPrimary,
                )
                : null,
        child: child,
      ),
      CustomButtonType.outlined => OutlinedButton(
        onPressed: _isDisabled ? null : onPressed,
        style:
            foregroundColor != null
                ? OutlinedButton.styleFrom(
                  foregroundColor: foregroundColor,
                  side: BorderSide(color: foregroundColor!, width: 1.4),
                )
                : null,
        child: child,
      ),
      CustomButtonType.text => TextButton(
        onPressed: _isDisabled ? null : onPressed,
        style:
            foregroundColor != null
                ? TextButton.styleFrom(foregroundColor: foregroundColor)
                : null,
        child: child,
      ),
    };

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: button,
    );
  }

  Color _loadingColor(BuildContext context) {
    if (foregroundColor != null) return foregroundColor!;
    return switch (type) {
      CustomButtonType.filled => AppColors.onPrimary,
      CustomButtonType.outlined => AppColors.primary,
      CustomButtonType.text => AppColors.primary,
    };
  }
}
