import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import 'session_storage.dart';

/// المصدر الوحيد لبيانات "المستخدم الحالي" عبر التطبيق بأكمله (Single
/// Source of Truth). يُوفَّر مرة واحدة في جذر شجرة الواجهات (`main.dart`)
/// بحيث تقرأ كل الشاشات (الرئيسية، الملف الشخصي، تعديل البيانات...) من
/// نفس النسخة، بدل أن تمتلك كل شاشة بياناتها المنفصلة الخاصة بها.
///
/// تُملأ هذه الحالة عند نجاح التحقق من رمز الـ OTP (تسجيل الدخول أو إنشاء
/// حساب جديد)، وتُمسح عند تسجيل الخروج. كل تغيير يُخزَّن أيضاً محلياً عبر
/// [SessionStorage] كي لا تضيع الجلسة عند تحديث صفحة الويب أو إعادة فتح
/// التطبيق (راجع [restore]).
class UserSessionCubit extends Cubit<AuthUser?> {
  UserSessionCubit() : super(null);

  /// تعيين المستخدم الحالي، سواء عند تسجيل الدخول أو تحديث بيانات الملف
  /// الشخصي.
  void setUser(AuthUser user) {
    emit(user);
    SessionStorage.saveUser(user);
  }

  /// مسح الجلسة عند تسجيل الخروج.
  void clear() {
    emit(null);
    SessionStorage.clearUser();
    SessionStorage.clearTokens();
  }

  /// استعادة جلسة محفوظة محلياً (إن وُجدت) دون إعادة إرسالها للتخزين.
  /// تُستدعى من شاشة البداية فقط.
  Future<AuthUser?> restore() async {
    final user = await SessionStorage.loadUser();
    if (user != null) emit(user);
    return user;
  }
}
