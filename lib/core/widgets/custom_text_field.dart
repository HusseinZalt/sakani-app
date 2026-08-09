import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// حقل إدخال موحّد يدعم العنوان الخارجي، الأيقونات، إخفاء كلمة المرور،
/// رسائل التحقق، وجميع خصائص [TextFormField] الشائعة، مع الالتزام
/// الكامل باتجاه RTL وثيم التطبيق.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.focusNode,
    this.inputFormatters,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  /// وحدة التحكم بالنص.
  final TextEditingController? controller;

  /// عنوان الحقل الظاهر أعلى الحدود.
  final String? label;

  /// نص توضيحي داخل الحقل قبل الكتابة.
  final String? hint;

  /// رسالة خطأ يدوية (تُستخدم غالباً مع أخطاء الباك إند القادمة عبر ApiFailure).
  final String? errorText;

  /// نص مساعد يظهر أسفل الحقل بشكل دائم.
  final String? helperText;

  /// أيقونة تظهر في بداية الحقل (يمين الحقل في RTL).
  final IconData? prefixIcon;

  /// أيقونة تظهر في نهاية الحقل، مثل زر إظهار/إخفاء كلمة المرور.
  final IconData? suffixIcon;

  /// دالة تُستدعى عند الضغط على أيقونة النهاية.
  final VoidCallback? onSuffixIconTap;

  /// إخفاء النص المدخل (لحقول كلمات المرور).
  final bool obscureText;

  /// نوع لوحة المفاتيح.
  final TextInputType? keyboardType;

  /// إجراء زر الإدخال (التالي/تم/بحث...).
  final TextInputAction? textInputAction;

  final int maxLines;
  final int? minLines;
  final int? maxLength;

  /// تفعيل/تعطيل الحقل.
  final bool enabled;

  /// جعل الحقل للقراءة فقط.
  final bool readOnly;

  final bool autofocus;

  /// دالة التحقق من صحة القيمة، تُستخدم مع [Form].
  final String? Function(String? value)? validator;

  final void Function(String value)? onChanged;
  final void Function(String value)? onFieldSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  /// اتجاه النص داخل الحقل. اترك القيمة الافتراضية (RTL) للحقول ذات المحتوى
  /// العربي، واستخدم [TextDirection.ltr] للحقول ذات المحتوى اللاتيني بطبيعته
  /// (البريد الإلكتروني، رقم الجوال، كلمة المرور) لتفادي مشاكل ترتيب
  /// الأحرف (Bidi) عند خلط الاتجاهين.
  final TextDirection textDirection;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          inputFormatters: widget.inputFormatters,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            prefixIcon:
                widget.prefixIcon != null
                    ? Icon(
                      widget.prefixIcon,
                      color: AppColors.textHint,
                      size: 22,
                    )
                    : null,
            suffixIcon: _buildSuffixIcon(),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: 22,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(widget.suffixIcon, color: AppColors.textHint, size: 22),
        onPressed: widget.onSuffixIconTap,
      );
    }
    return null;
  }
}
