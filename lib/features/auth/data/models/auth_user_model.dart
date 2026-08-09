import '../../domain/entities/auth_user.dart';

/// نموذج بيانات المستخدم (Model) في طبقة الـ Data، مسؤول عن تحويل استجابة
/// خدمة المصادقة الحقيقية (auth service على Vercel) إلى كيان [AuthUser]
/// الذي تتعامل معه بقية طبقات التطبيق.
///
/// ملاحظة: خدمة المصادقة لا تُرجع (عبر `/login` أو `/me`) حقول الملف
/// الأكاديمي الإضافية (الجامعة، الرقم الجامعي، السكن...) رغم إرسالها
/// عند التسجيل — على الأغلب لأنها ستُدار عبر خدمة "ملف شخصي" منفصلة
/// لاحقاً. تبقى هذه الحقول `null` بعد تسجيل الدخول العادي حتى تتوفر تلك
/// الخدمة.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    super.avatarUrl,
    super.university,
    super.studentId,
    super.college,
    super.city,
    super.nationalId,
    super.isVerified,
    super.role,
    super.verificationStatus,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '';
    final secondName = json['secondName'] as String? ?? '';

    return AuthUserModel(
      id: (json['_id'] ?? json['id']) as String,
      fullName: [
        firstName,
        secondName,
      ].where((part) => part.isNotEmpty).join(' '),
      email: json['email'] as String,
      phone: json['phoneNumber'] as String? ?? '',
      avatarUrl: json['personalPhoto'] as String?,
      university: json['university']?.toString(),
      studentId: json['studentNumber'] as String?,
      nationalId: json['nationalId'] as String?,
      city: json['residence'] as String?,
      isVerified: json['isEmailVerified'] as bool? ?? true,
      role: json['role'] as String?,
      verificationStatus: json['verificationStatus'] as String?,
    );
  }
}
