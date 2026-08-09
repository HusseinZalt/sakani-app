import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

/// حالة العملية الحالية في شاشة تأكيد الحساب (بشكل عام، منفصلة عن مؤقت
/// إعادة الإرسال الذي يستمر بالعمل بغض النظر عن حالة التحقق).
enum OtpStatus {
  /// بانتظار إدخال المستخدم للرمز.
  idle,

  /// جارٍ التحقق من الرمز المُدخل.
  verifying,

  /// تم التحقق من الرمز بنجاح.
  verified,

  /// فشل التحقق من الرمز.
  failure,
}

/// حالة شاشة تأكيد الحساب (OTP) الموحّدة، تجمع بين حالة التحقق من الرمز
/// وحالة العدّاد التنازلي لإعادة الإرسال معاً لأنهما يتغيران باستمرار
/// بشكل مستقل عن بعضهما.
class OtpState extends Equatable {
  const OtpState({
    this.status = OtpStatus.idle,
    this.secondsRemaining = 60,
    this.isResending = false,
    this.errorMessage,
    this.user,
  });

  final OtpStatus status;
  final int secondsRemaining;
  final bool isResending;
  final String? errorMessage;
  final AuthUser? user;

  bool get canResend => secondsRemaining <= 0 && !isResending;

  OtpState copyWith({
    OtpStatus? status,
    int? secondsRemaining,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
    AuthUser? user,
  }) {
    return OtpState(
      status: status ?? this.status,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
    status,
    secondsRemaining,
    isResending,
    errorMessage,
    user,
  ];
}
