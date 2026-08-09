import 'package:flutter/material.dart';

/// لوحة الألوان الموحدة لتطبيق "سكني" (Sakani) — بوابة السكن الجامعي.
///
/// القيم مطابقة تماماً لنظام التصميم المعتمد (design tokens) الموجود في
/// ملفات المرجع بمجلد `UI/` بجذر المشروع. جميع الألوان المستخدمة في
/// التطبيق يجب أن تُستمد من هذا الملف لضمان اتساق الهوية البصرية.
///
/// دعم الوضع الليلي: الرموز (tokens) التي يختلف شكلها بين الوضعين (خلفيات،
/// نصوص، حدود...) مُعرَّفة كـ getters تقرأ [brightness] الحالية، بينما تبقى
/// ألوان الهوية (Primary/Secondary/Accent) وألوان الحالة الأساسية ثابتة لأنها
/// مقروءة بوضوح في الوضعين. [brightness] يُحدَّث بواسطة `ThemeController`
/// عند كل تبديل للثيم، ما يجعل هذه الـ getters تُعيد القيم الصحيحة عند إعادة
/// البناء التي يفرضها `MaterialApp.themeMode`.
class AppColors {
  const AppColors._();

  /// السطوع الحالي للتطبيق. تُحدَّثه `ThemeController` فقط.
  static Brightness brightness = Brightness.light;

  static bool _isDarkFor(Brightness b) => b == Brightness.dark;

  // ==================== Blue (اللون الأساسي) ====================
  static const Color blue50 = Color(0xFFF0F9FF);
  static const Color blue100 = Color(0xFFE0F2FE);
  static const Color blue400 = Color(0xFF38BDF8);
  static const Color blue500 = Color(0xFF0EA5E9);
  static const Color blue600 = Color(0xFF0284C7);
  static const Color blue700 = Color(0xFF0369A1);

  // ==================== Green (النجاح) ====================
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);

  // ==================== Amber (التحذير) ====================
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);

  // ==================== Red (الخطر) ====================
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red400 = Color(0xFFF87171);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);

  // ==================== Violet (التمييز) ====================
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color violet500 = Color(0xFF8B5CF6);
  static const Color violet600 = Color(0xFF7C3AED);

  // ==================== Gray ====================
  static const Color gray0 = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // ==================== الألوان الأساسية (Primary) ====================
  // ثابتة بين الوضعين: الأزرق الأساسي واضح ومقروء على خلفية فاتحة أو داكنة.
  static const Color primary = blue500;
  static const Color primaryDark = blue600;
  static const Color primaryDarker = blue700;
  static const Color primaryLight = blue400;
  static Color primarySubtleFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF0F2A3D) : blue50;
  static Color get primarySubtle => primarySubtleFor(brightness);
  static const Color onPrimary = gray0;

  // ==================== الألوان الثانوية (Secondary) ====================
  static const Color secondary = amber500;
  static const Color secondaryDark = amber600;
  static Color secondaryLightFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF2E2410) : amber50;
  static Color get secondaryLight => secondaryLightFor(brightness);
  static const Color onSecondary = gray900;

  // ==================== لون التمييز (Accent) ====================
  static const Color accent = violet500;
  static const Color accentDark = violet600;
  static Color accentSubtleFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF241C3D) : violet50;
  static Color get accentSubtle => accentSubtleFor(brightness);

  // ==================== ألوان الخلفيات والأسطح ====================
  static Color backgroundFor(Brightness b) => _isDarkFor(b) ? gray900 : gray50;
  static Color get background => backgroundFor(brightness);
  static Color surfaceFor(Brightness b) => _isDarkFor(b) ? gray800 : gray0;
  static Color get surface => surfaceFor(brightness);
  static Color surfaceVariantFor(Brightness b) =>
      _isDarkFor(b) ? gray700 : gray100;
  static Color get surfaceVariant => surfaceVariantFor(brightness);
  static Color scaffoldBackgroundFor(Brightness b) =>
      _isDarkFor(b) ? gray900 : gray50;
  static Color get scaffoldBackground => scaffoldBackgroundFor(brightness);

  // ==================== ألوان الحالة (Status) ====================
  static const Color success = green600;
  static Color successTextFor(Brightness b) =>
      _isDarkFor(b) ? green400 : green700;
  static Color get successText => successTextFor(brightness);
  static Color successBackgroundFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF14291D) : green50;
  static Color get successBackground => successBackgroundFor(brightness);
  static const Color warning = amber500;
  static Color warningTextFor(Brightness b) =>
      _isDarkFor(b) ? amber400 : amber700;
  static Color get warningText => warningTextFor(brightness);
  static Color warningBackgroundFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF2E2410) : amber50;
  static Color get warningBackground => warningBackgroundFor(brightness);
  static const Color error = red600;
  static Color errorTextFor(Brightness b) => _isDarkFor(b) ? red400 : red700;
  static Color get errorText => errorTextFor(brightness);
  static Color errorBackgroundFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF2E1618) : red50;
  static Color get errorBackground => errorBackgroundFor(brightness);
  static const Color info = blue500;
  static Color infoTextFor(Brightness b) => _isDarkFor(b) ? blue400 : blue600;
  static Color get infoText => infoTextFor(brightness);
  static Color infoBackgroundFor(Brightness b) =>
      _isDarkFor(b) ? const Color(0xFF102A43) : blue50;
  static Color get infoBackground => infoBackgroundFor(brightness);

  // ==================== حالات الطلبات (سكن / خدمة / شكوى) ====================
  static const Color statusPending = amber500;
  static const Color statusInProgress = blue500;
  static const Color statusResolved = green600;
  static const Color statusRejected = red600;

  // ==================== ألوان النصوص ====================
  static Color textPrimaryFor(Brightness b) => _isDarkFor(b) ? gray50 : gray900;
  static Color get textPrimary => textPrimaryFor(brightness);
  static Color textSecondaryFor(Brightness b) =>
      _isDarkFor(b) ? gray400 : gray500;
  static Color get textSecondary => textSecondaryFor(brightness);
  static Color textHintFor(Brightness b) => _isDarkFor(b) ? gray500 : gray400;
  static Color get textHint => textHintFor(brightness);
  static Color textDisabledFor(Brightness b) =>
      _isDarkFor(b) ? gray400 : gray500;
  static Color get textDisabled => textDisabledFor(brightness);
  static const Color textOnPrimary = gray0;
  static const Color textOnSecondary = gray900;

  // ==================== ألوان الحدود والفواصل ====================
  static Color borderFor(Brightness b) => _isDarkFor(b) ? gray700 : gray200;
  static Color get border => borderFor(brightness);
  static Color borderSubtleFor(Brightness b) =>
      _isDarkFor(b) ? gray800 : gray100;
  static Color get borderSubtle => borderSubtleFor(brightness);
  static const Color borderFocused = blue500;
  static Color dividerFor(Brightness b) => _isDarkFor(b) ? gray800 : gray100;
  static Color get divider => dividerFor(brightness);

  // ==================== ألوان أخرى ====================
  static const Color shadow = Color(0x0D0F172A);
  static const Color overlay = Color(0x8C0F172A);
  static Color disabledFor(Brightness b) => _isDarkFor(b) ? gray700 : gray300;
  static Color get disabled => disabledFor(brightness);
  static const Color white = gray0;
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ==================== التقييم (Rating) ====================
  static const Color rating = amber500;

  // ==================== تدرجات لونية (Gradients) ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [blue500, blue600],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet500, blue600],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber500, red600],
  );

  /// إرجاع لون حالة الطلب المناسب (سكن/خدمة/شكوى) حسب النص الوارد من الباك إند.
  static Color statusColor(String status) {
    switch (status) {
      case 'pending':
        return statusPending;
      case 'inProgress':
        return statusInProgress;
      case 'resolved':
      case 'completed':
      case 'accepted':
        return statusResolved;
      case 'rejected':
        return statusRejected;
      default:
        return textSecondary;
    }
  }
}
