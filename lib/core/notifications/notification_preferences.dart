import 'package:shared_preferences/shared_preferences.dart';

/// تفضيلات المستخدم لأنواع الإشعارات (شاشة الإعدادات) — تُخزَّن محلياً
/// عبر SharedPreferences لتبقى بين جلسات التطبيق.
class NotificationPreferences {
  const NotificationPreferences._();

  static const _housingKey = 'notif_pref_housing';
  static const _complaintsKey = 'notif_pref_complaints';
  static const _generalKey = 'notif_pref_general';

  static Future<bool> getHousingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_housingKey) ?? true;
  }

  static Future<void> setHousingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_housingKey, value);
  }

  static Future<bool> getComplaintsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_complaintsKey) ?? true;
  }

  static Future<void> setComplaintsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_complaintsKey, value);
  }

  static Future<bool> getGeneralEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_generalKey) ?? false;
  }

  static Future<void> setGeneralEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_generalKey, value);
  }

  /// يحدّد إن كانت إشعارات هذا النوع (`type` من حمولة الإشعار) مفعّلة حالياً،
  /// حسب نفس تصنيف الأنواع المستخدم أصلاً بألوان قائمة الإشعارات
  /// (راجع `_colorKeyForType` بـ `app_notification_model.dart`): `housing`
  /// له مفتاحه الخاص، `complaint` له مفتاحه الخاص، وأي نوع آخر (أو بدون
  /// نوع) يُعتبر إشعاراً عاماً.
  static Future<bool> isEnabledForType(String? type) async {
    switch (type) {
      case 'housing':
        return getHousingEnabled();
      case 'complaint':
        return getComplaintsEnabled();
      default:
        return getGeneralEnabled();
    }
  }
}
