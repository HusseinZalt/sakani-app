import 'package:flutter/material.dart';

/// شعار التطبيق (سكني) بنسختيه الفاتحة والداكنة.
///
/// يعرض تلقائياً النسخة المناسبة حسب سطوع الثيم الحالي، أو يمكن فرض
/// نسخة معيّنة عبر [variant] (مفيد فوق خلفيات ملوّنة ثابتة كشاشة البداية).
enum AppLogoVariant { auto, light, dark }

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.variant = AppLogoVariant.auto,
  });

  final double size;
  final AppLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool useDark = switch (variant) {
      AppLogoVariant.light => false,
      AppLogoVariant.dark => true,
      AppLogoVariant.auto => Theme.of(context).brightness == Brightness.dark,
    };

    final String asset =
        useDark
            ? 'assets/images/logo_dark.png'
            : 'assets/images/logo_light.png';

    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}
