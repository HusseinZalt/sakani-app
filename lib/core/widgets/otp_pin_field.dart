import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

/// حقل إدخال رمز التحقق (OTP) المكوّن من عدة خانات منفصلة متصلة منطقياً،
/// مع انتقال تلقائي بين الخانات عند الكتابة أو الحذف، وإمكانية لصق الرمز
/// كاملاً دفعة واحدة.
class OtpPinField extends StatefulWidget {
  const OtpPinField({
    super.key,
    this.length = 5,
    required this.onCompleted,
    this.onChanged,
    this.autofocus = true,
    this.hasError = false,
  });

  /// عدد خانات الرمز.
  final int length;

  /// تُستدعى عند اكتمال إدخال جميع الخانات بالرمز الكامل.
  final ValueChanged<String> onCompleted;

  /// تُستدعى مع كل تغيير في قيمة الرمز الحالية (مكتملة أو غير مكتملة).
  final ValueChanged<String>? onChanged;

  final bool autofocus;

  /// إظهار مظهر الخطأ (حدود حمراء) لكل الخانات، يُستخدم بعد فشل التحقق.
  final bool hasError;

  @override
  State<OtpPinField> createState() => _OtpPinFieldState();
}

class _OtpPinFieldState extends State<OtpPinField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  // مفاتيح تركيز منفصلة لكل [KeyboardListener] (تعترض ضغطة "حذف" الخام)،
  // مُنشأة مرة واحدة هنا بدل داخل build() — إنشاء FocusNode جديد بكل
  // استدعاء build (كما كان سابقاً) يترك عقدة التركيز السابقة معلّقة بلا
  // dispose() في كل مرة تُعاد فيها بناء الودجت (مثال: تبديل hasError بعد
  // فشل التحقق)، ما يُسرّب عقدة تركيز جديدة مع كل محاولة تحقق فاشلة.
  late final List<FocusNode> _keyboardFocusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _keyboardFocusNodes = List.generate(
      widget.length,
      (_) => FocusNode(skipTraversal: true),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final node in _keyboardFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentCode => _controllers.map((c) => c.text).join();

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // دعم لصق الرمز كاملاً في أي خانة.
      final pasted = value.replaceAll(RegExp(r'\s'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < pasted.length ? pasted[i] : '';
      }
      final lastIndex = (pasted.length - 1).clamp(0, widget.length - 1);
      _focusNodes[lastIndex].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    widget.onChanged?.call(_currentCode);
    if (_currentCode.length == widget.length) {
      widget.onCompleted(_currentCode);
    }
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      widget.onChanged?.call(_currentCode);
    }
  }

  /// مسح كل الخانات، تُستخدم بعد فشل محاولة التحقق.
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // الأرقام تُقرأ وتُكتب دائماً من اليسار لليمين بغض النظر عن اتجاه
    // التطبيق (RTL)؛ بدون هذا الإجبار، يعكس الـ Row ترتيب الخانات بصرياً
    // (الخانة الأولى منطقياً تظهر في أقصى اليمين بدل اليسار)، فيدخل
    // المستخدم الرمز بترتيب معاكس تماماً لما يقرأه.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (index) {
          final isFilled = _controllers[index].text.isNotEmpty;
          final boxColor =
              widget.hasError
                  ? AppColors.error
                  : (isFilled ? AppColors.primary : AppColors.border);

          return SizedBox(
            width: 52,
            height: 60,
            child: KeyboardListener(
              focusNode: _keyboardFocusNodes[index],
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  _handleBackspace(index);
                }
              },
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                autofocus: widget.autofocus && index == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color:
                      isFilled && !widget.hasError
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: boxColor, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: boxColor, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(
                      color:
                          widget.hasError
                              ? AppColors.error
                              : AppColors.borderFocused,
                      width: 1.8,
                    ),
                  ),
                ),
                onChanged: (value) => _handleChanged(index, value),
              ),
            ),
          );
        }),
      ),
    );
  }
}
