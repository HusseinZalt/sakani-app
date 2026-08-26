import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'otp_state.dart';

/// يدير حالة شاشة تأكيد الحساب: التحقق من رمز الـ OTP، وإعادة الإرسال مع
/// عدّاد تنازلي مستقل عن حالة التحقق نفسها.
///
/// بما أن تأكيد البريد وحده لا يُرجع جلسة دخول (خدمة المصادقة تفصل بين
/// `verify-email` و`login`)، يقوم هذا الـ Cubit تلقائياً بتسجيل الدخول
/// بعد نجاح التأكيد إن كانت كلمة المرور متوفرة معه (تُمرَّر من شاشتي
/// التسجيل أو الدخول مباشرة، ولا تُخزَّن محلياً لأسباب أمنية). إن لم تكن
/// متوفرة لأي سبب، يُترك [OtpState.user] فارغاً وتوجّه الشاشة المستخدم
/// لتسجيل الدخول يدوياً.
class OtpCubit extends Cubit<OtpState> {
  OtpCubit(this._authRepository, {required this.identifier, this.password})
    : super(const OtpState()) {
    _startResendTimer();
  }

  final AuthRepository _authRepository;
  final String identifier;
  final String? password;

  static const _resendCooldownSeconds = 60;

  Timer? _timer;

  void _startResendTimer() {
    _timer?.cancel();
    emit(state.copyWith(secondsRemaining: _resendCooldownSeconds));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining <= 1) {
        timer.cancel();
        emit(state.copyWith(secondsRemaining: 0));
      } else {
        emit(state.copyWith(secondsRemaining: state.secondsRemaining - 1));
      }
    });
  }

  Future<void> verifyOtp(String code) async {
    // بدون هذا الحرس، يمكن لصق/إكمال الرمز مرة أخرى (عبر `onCompleted` في
    // حقل الرمز، الذي لا يُعطَّل أثناء التحقق) بينما طلب تحقق سابق ما زال
    // قيد التنفيذ، فيُرسَل طلبان متزامنان تتسابق نتائجهما على الحالة.
    if (state.status == OtpStatus.verifying) return;
    emit(state.copyWith(status: OtpStatus.verifying, clearError: true));

    final result = await _authRepository.verifyEmail(
      email: identifier,
      code: code,
    );

    switch (result) {
      case ApiSuccess<void>():
        final user = await _tryAutoLogin();
        emit(state.copyWith(status: OtpStatus.verified, user: user));
      case ApiFailureResult<void>(:final failure):
        emit(
          state.copyWith(
            status: OtpStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<AuthUser?> _tryAutoLogin() async {
    if (password == null) return null;

    final loginResult = await _authRepository.login(
      email: identifier,
      password: password!,
    );
    return switch (loginResult) {
      ApiSuccess<AuthUser>(:final data) => data,
      ApiFailureResult<AuthUser>() => null,
    };
  }

  /// يعيد الحالة إلى [OtpStatus.idle] بعد أن تعرض الشاشة رسالة الفشل مرة
  /// واحدة. بدون هذا، تبقى [OtpStatus.failure] كما هي بين تكات مؤقت إعادة
  /// الإرسال (الذي يستمر بالعمل بشكل مستقل كل ثانية)، فتُعيد كل تكة إطلاق
  /// نفس معالجة الفشل بواجهة المستخدم (مسح الخانات وإظهار الرسالة من
  /// جديد)، فيبدو الأمر وكأن أي رقم يُكتب يُحذف فوراً.
  void clearFailure() {
    if (state.status == OtpStatus.failure) {
      emit(state.copyWith(status: OtpStatus.idle));
    }
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;

    emit(state.copyWith(isResending: true, clearError: true));

    final result = await _authRepository.resendVerification(email: identifier);

    switch (result) {
      case ApiSuccess<void>():
        emit(state.copyWith(isResending: false, status: OtpStatus.idle));
        _startResendTimer();
      case ApiFailureResult<void>(:final failure):
        emit(state.copyWith(isResending: false, errorMessage: failure.message));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
