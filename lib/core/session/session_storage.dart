import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/entities/auth_user.dart';

/// تخزين محلي بسيط (SharedPreferences) لجلسة المستخدم الحالية وحالة
/// التفعيل المعلّقة (حساب أنشئ ولم يُؤكَّد بعد عبر OTP)، بحيث لا تضيع
/// عند تحديث صفحة الويب أو إغلاق التطبيق وإعادة فتحه.
///
/// نقطة الربط مع الباك إند: عند توفر توكن حقيقي، يُخزَّن هنا أيضاً بنفس
/// الطريقة دون تغيير طريقة استخدام هذا الصف من بقية طبقات التطبيق.
class SessionStorage {
  const SessionStorage._();

  static const _userKey = 'session_user';
  static const _pendingVerificationKey = 'pending_verification_identifier';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userKey,
      jsonEncode({
        'id': user.id,
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'avatarUrl': user.avatarUrl,
        'university': user.university,
        'studentId': user.studentId,
        'college': user.college,
        'city': user.city,
        'nationalId': user.nationalId,
        'isVerified': user.isVerified,
      }),
    );
  }

  static Future<AuthUser?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        university: json['university'] as String?,
        studentId: json['studentId'] as String?,
        college: json['college'] as String?,
        city: json['city'] as String?,
        nationalId: json['nationalId'] as String?,
        isVerified: json['isVerified'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// حفظ معرّف (بريد/جوال) حساب أُنشئ ولم يُكمل صاحبه تأكيده عبر OTP بعد،
  /// لتوجيهه مباشرة لشاشة التأكيد عند إعادة فتح التطبيق.
  static Future<void> savePendingVerification(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingVerificationKey, identifier);
  }

  static Future<String?> loadPendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingVerificationKey);
  }

  static Future<void> clearPendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingVerificationKey);
  }

  /// حفظ زوج رمزَي الدخول (Access/Refresh Token) بعد تسجيل الدخول الناجح،
  /// يُستخدمان لاحقاً لإرفاق الطلبات المصادَق عليها وتجديد الجلسة تلقائياً.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> loadRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
