import '../../../../core/network/api_result.dart';
import '../entities/auth_user.dart';
import '../entities/register_data.dart';

/// عقد (Interface) طبقة المصادقة، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (خدمة مصادقة حقيقية عبر Vercel).
///
/// أي تغيير مستقبلي على [AuthRemoteDataSource] (مثال: تغيير رابط الخدمة)
/// لن يتطلب أي تعديل على الشاشات أو الـ Cubits المعتمدة على هذا العقد.
abstract class AuthRepository {
  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور. عند النجاح تُعاد بيانات
  /// المستخدم مباشرة (لا يوجد رمز تحقق (OTP) لكل عملية دخول روتينية —
  /// الـ OTP مطلوب فقط عند إنشاء الحساب أو إعادة تعيين كلمة المرور).
  ///
  /// قد تفشل العملية بحساب "غير مؤكَّد بعد" (النوع
  /// [ApiErrorType.unverifiedAccount])، عندها يجب توجيه المستخدم لتأكيد
  /// بريده أولاً عبر [verifyEmail].
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  });

  /// إنشاء حساب جديد ببيانات [RegisterData] المجمّعة من خطوتي التسجيل.
  /// عند النجاح يُرسَل رمز تحقق (OTP) إلى البريد الإلكتروني المُدخل.
  Future<ApiResult<void>> register(RegisterData data);

  /// تأكيد البريد الإلكتروني عبر رمز الـ OTP المكوَّن من 5 أرقام.
  Future<ApiResult<void>> verifyEmail({
    required String email,
    required String code,
  });

  /// إعادة إرسال رمز تأكيد البريد الإلكتروني.
  Future<ApiResult<void>> resendVerification({required String email});

  /// طلب رمز إعادة تعيين كلمة المرور عبر البريد الإلكتروني.
  Future<ApiResult<void>> forgotPassword({required String email});

  /// إعادة تعيين كلمة المرور عبر رمز الـ OTP وكلمة مرور جديدة.
  Future<ApiResult<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// تسجيل الخروج من الجهاز الحالي فقط: يُبطِل رمز التحديث (Refresh Token)
  /// المحفوظ محلياً على الخادم، بحيث لا يبقى صالحاً للاستخدام بعد مسح
  /// الجلسة محلياً.
  Future<ApiResult<void>> logout();
}
