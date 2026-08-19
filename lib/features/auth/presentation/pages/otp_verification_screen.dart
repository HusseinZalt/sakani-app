import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/otp_pin_field.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../cubit/otp_cubit.dart';
import '../cubit/otp_state.dart';

/// وسيطة التنقل إلى شاشة تأكيد الحساب: البريد الإلكتروني المُرسل إليه
/// الرمز، وكلمة المرور اختيارياً (تُستخدم لتسجيل الدخول تلقائياً فور
/// نجاح التأكيد، بما أن `verify-email` لا يُرجع جلسة دخول بذاته). لا
/// تُخزَّن كلمة المرور محلياً أبداً — تبقى في الذاكرة فقط أثناء هذا
/// التدفق، لذلك تكون `null` عند استئناف تأكيد معلَّق بعد إعادة فتح
/// التطبيق.
class OtpRouteArgs {
  const OtpRouteArgs({required this.identifier, this.password});

  final String identifier;
  final String? password;
}

/// شاشة تأكيد الحساب عبر رمز التحقق (OTP) المُرسل إلى البريد الإلكتروني
/// المُستخدم في شاشة تسجيل الدخول أو إنشاء الحساب.
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.password,
  });

  /// البريد الإلكتروني الذي أُرسل إليه رمز التحقق.
  final String identifier;

  /// كلمة المرور لتسجيل الدخول تلقائياً بعد التأكيد (راجع [OtpRouteArgs]).
  final String? password;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => OtpCubit(
            AuthRepositoryImpl(),
            identifier: identifier,
            password: password,
          ),
      child: _OtpView(identifier: identifier),
    );
  }
}

class _OtpView extends StatefulWidget {
  const _OtpView({required this.identifier});

  final String identifier;

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  String _currentCode = '';
  int _pinFieldResetKey = 0;

  void _submit(BuildContext context) {
    if (_currentCode.length < 5) return;
    context.read<OtpCubit>().verifyOtp(_currentCode);
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('إلغاء التفعيل؟'),
            content: const Text(
              'لم تُكمل تأكيد حسابك بعد. هل تريد الخروج من عملية التفعيل؟ يمكنك إكمالها لاحقاً.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('البقاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'خروج',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      context.goNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<OtpCubit, OtpState>(
            listener: (context, state) {
              if (state.status == OtpStatus.verified) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (state.user != null) {
                  context.read<UserSessionCubit>().setUser(state.user!);
                  context.goNamed(AppRoutes.home);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تأكيد بريدك بنجاح، يرجى تسجيل الدخول.'),
                    ),
                  );
                  context.goNamed(AppRoutes.login);
                }
              } else if (state.status == OtpStatus.failure) {
                setState(() => _pinFieldResetKey++);
                _currentCode = '';
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'حدث خطأ غير متوقع'),
                    ),
                  );
                context.read<OtpCubit>().clearFailure();
              }
            },
            builder: (context, state) {
              final isVerifying = state.status == OtpStatus.verifying;
              final hasError = state.status == OtpStatus.failure;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primarySubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.primaryDark,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'تأكيد الحساب',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'تم إرسال رمز مكوّن من 5 أرقام إلى بريدك الإلكتروني\n',
                          ),
                          TextSpan(
                            text: widget.identifier,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    OtpPinField(
                      key: ValueKey(_pinFieldResetKey),
                      length: 5,
                      hasError: hasError,
                      onChanged: (code) => _currentCode = code,
                      onCompleted: (code) {
                        _currentCode = code;
                        _submit(context);
                      },
                    ),
                    const SizedBox(height: 20),
                    _ResendSection(state: state),
                    const SizedBox(height: 28),
                    CustomButton(
                      label: 'تأكيد',
                      icon: Icons.check_rounded,
                      isLoading: isVerifying,
                      onPressed: () => _submit(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResendSection extends StatelessWidget {
  const _ResendSection({required this.state});

  final OtpState state;

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.canResend) {
      return Center(
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: 'إعادة الإرسال خلال '),
              TextSpan(
                text: _formatDuration(state.secondsRemaining),
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: TextButton(
        onPressed:
            state.isResending
                ? null
                : () => context.read<OtpCubit>().resendOtp(),
        child:
            state.isResending
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Text('إعادة إرسال الرمز'),
      ),
    );
  }
}
