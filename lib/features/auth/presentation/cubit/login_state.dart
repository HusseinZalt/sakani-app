import '../../../../core/network/api_result.dart';
import '../../domain/entities/auth_user.dart';

/// حالات شاشة تسجيل الدخول.
///
/// استخدام sealed class يجبر واجهة المستخدم على معالجة كل الحالات
/// الممكنة (Loading/Success/Failure) عبر switch شامل دون إغفال أي حالة.
sealed class LoginState {
  const LoginState();
}

/// الحالة الابتدائية قبل أي محاولة تسجيل دخول.
final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// جارٍ التحقق من بيانات الدخول.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

/// نجح تسجيل الدخول مباشرة (لا يوجد رمز تحقق لكل عملية دخول روتينية —
/// الحساب مؤكَّد بالفعل من قبل).
final class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);

  final AuthUser user;
}

/// فشل تسجيل الدخول مع تفاصيل الخطأ (بيانات خاطئة، أو حساب غير مؤكَّد —
/// راجع `failure.type == ApiErrorType.unverifiedAccount`).
final class LoginFailureState extends LoginState {
  const LoginFailureState(this.failure);

  final ApiFailure failure;
}
