import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

/// إعدادات الثيم الموحدة للتطبيق — بوضعيها الفاتح والداكن — مع دعم كامل
/// للغة العربية واتجاه الكتابة من اليمين إلى اليسار (RTL).
///
/// كلا الثيمين يُبنيان بنفس المُنشئ [_buildTheme] باستخدام قيم [AppColors]
/// الصريحة (`xxxFor(brightness)`) بدل الاعتماد على السطوع الحالي العام،
/// حتى لا يتأثر بناء أحدهما بالآخر عند تمريرهما معاً لـ `MaterialApp`.
class AppTheme {
  const AppTheme._();

  /// اسم عائلة الخط العربي المستخدم في كامل التطبيق (كلا الوضعين).
  static String get fontFamily => GoogleFonts.cairo().fontFamily!;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base =
        isDark
            ? Typography.material2021(platform: TargetPlatform.android).white
            : Typography.material2021(platform: TargetPlatform.android).black;
    final textTheme = _buildTextTheme(base, brightness);

    final surface = AppColors.surfaceFor(brightness);
    final textPrimary = AppColors.textPrimaryFor(brightness);
    final textSecondary = AppColors.textSecondaryFor(brightness);
    final textHint = AppColors.textHintFor(brightness);
    final textDisabled = AppColors.textDisabledFor(brightness);
    final border = AppColors.borderFor(brightness);
    final borderSubtle = AppColors.borderSubtleFor(brightness);
    final divider = AppColors.dividerFor(brightness);
    final disabled = AppColors.disabledFor(brightness);
    final secondaryLight = AppColors.secondaryLightFor(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.scaffoldBackgroundFor(brightness),
      primaryColor: AppColors.primary,
      fontFamily: fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: secondaryLight,
        error: AppColors.error,
        onError: AppColors.white,
        surface: surface,
        onSurface: textPrimary,
        outline: border,
      ),

      // ==================== AppBar ====================
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      // ==================== Bottom Navigation ====================
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textHint,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),

      // ==================== NavigationBar (Material3) ====================
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : textHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : textHint,
          );
        }),
      ),

      // ==================== الأزرار ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size.fromHeight(52),
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textSecondary,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
      ),

      // ==================== حقول الإدخال ====================
      // القيمة المعتمدة: خلفية بيضاء (وليست رمادية معبأة) مع حدود ظاهرة
      // دائماً (border-default) تتحول لونها للأزرق الأساسي عند التركيز،
      // مطابقةً لـ .input-wrap في التصميم المعتمد.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: borderSubtle, width: 1.5),
        ),
      ),

      // ==================== البطاقات ====================
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: borderSubtle, width: 1),
        ),
      ),

      // ==================== أخرى ====================
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
      // ملاحظة: Flutter لا يبدّل لون نص الشريحة تلقائياً بين الحالتين
      // المحددة وغير المحددة عبر الثيم وحده؛ لذا يجب تحديد لون النص صراحةً
      // في كل استخدام لـ ChoiceChip بحسب `selected` (أبيض عند التحديد،
      // ونص ثانوي عند عدمه) لمطابقة تصميم .chip / .chip.selected المعتمد.
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primary,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        side: BorderSide(color: border, width: 1.5),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.gray900 : AppColors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: textSecondary,
        ),
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }

  /// بناء TextTheme باستخدام خط Cairo العربي مع تباين واضح للعناوين والنصوص،
  /// بألوان مطابقة لسطوع [brightness] المطلوب (وليس السطوع الحالي للتطبيق).
  static TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
    final textPrimary = AppColors.textPrimaryFor(brightness);
    final textSecondary = AppColors.textSecondaryFor(brightness);

    return GoogleFonts.cairoTextTheme(base).copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.cairo(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelSmall: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    );
  }
}
