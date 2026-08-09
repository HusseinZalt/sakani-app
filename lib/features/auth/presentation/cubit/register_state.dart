import '../../../../core/network/api_result.dart';

/// حالات شاشة إنشاء الحساب.
///
/// استخدام sealed class يجبر واجهة المستخدم على معالجة كل الحالات
/// الممكنة (Loading/Success/Failure) عبر switch شامل دون إغفال أي حالة.
sealed class RegisterState {
  const RegisterState();
}

/// الحالة الابتدائية قبل أي محاولة تسجيل.
final class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

/// جارٍ إرسال بيانات التسجيل وطلب رمز التحقق.
final class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

/// تم إنشاء الحساب بنجاح وإرسال رمز الـ OTP إلى [identifier].
final class RegisterOtpSent extends RegisterState {
  const RegisterOtpSent(this.identifier);

  final String identifier;
}

/// فشل إنشاء الحساب مع تفاصيل الخطأ.
final class RegisterFailureState extends RegisterState {
  const RegisterFailureState(this.failure);

  final ApiFailure failure;
}
