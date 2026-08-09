import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';

/// يتحكم بوضع الثيم الحالي (فاتح / داكن / حسب النظام) ويحفظ اختيار
/// المستخدم محلياً (SharedPreferences) ليبقى نفس الاختيار عند إعادة فتح
/// التطبيق، إلى أن يغيّره المستخدم بنفسه.
///
/// [ChangeNotifier] بسيط بدل Cubit لأن هذه حالة عرض بحتة (UI-only) لا علاقة
/// لها بمنطق عمل أو بيانات من الخادم.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode) {
    AppColors.brightness = _resolveBrightness(_mode);
  }

  static const _prefsKey = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// يُنشئ المتحكم مع تحميل الاختيار المحفوظ سابقاً (إن وجد)، افتراضياً
  /// "حسب النظام" لأول تشغيل.
  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeController._(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    AppColors.brightness = _resolveBrightness(mode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  /// يُستدعى عند تغيّر سطوع نظام التشغيل بينما وضع التطبيق "حسب النظام"،
  /// لتحديث [AppColors.brightness] وإعادة رسم الشجرة بالألوان الصحيحة.
  void syncWithPlatformBrightness(Brightness platformBrightness) {
    if (_mode != ThemeMode.system) return;
    final resolved =
        platformBrightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light;
    if (AppColors.brightness == resolved) return;
    AppColors.brightness = resolved;
    notifyListeners();
  }

  Brightness _resolveBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness;
    }
  }
}
