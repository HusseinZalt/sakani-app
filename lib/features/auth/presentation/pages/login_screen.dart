import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import 'otp_verification_screen.dart';

/// شاشة تسجيل الدخول عبر البريد الإلكتروني الجامعي وكلمة المرور، مطابقة
/// للشاشة رقم 1 من التصميم المعتمد في مجلد `UI/`.
///
/// عند نجاح التحقق من البيانات يتم إرسال رمز تأكيد (OTP) والانتقال إلى
/// شاشة التحقق.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(AuthRepositoryImpl()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _showUnverifiedAccountDialog({
    required String message,
    required String email,
    required String password,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('الحساب غير مفعّل'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'إعادة إرسال الرمز',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;
    AuthRepositoryImpl().resendVerification(email: email);
    if (!mounted) return;
    context.pushNamed(
      AppRoutes.otp,
      extra: OtpRouteArgs(identifier: email, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<LoginCubit, LoginState>(
          listener: (context, state) {
            switch (state) {
              case LoginSuccess(:final user):
                context.read<UserSessionCubit>().setUser(user);
                context.goNamed(AppRoutes.home);
              case LoginFailureState(:final failure)
                  when failure.type == ApiErrorType.unverifiedAccount:
                _showUnverifiedAccountDialog(
                  message: failure.message,
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                );
              case LoginFailureState(:final failure):
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(failure.message)));
              case LoginInitial():
              case LoginLoading():
                break;
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),
                    const Center(child: AppLogo(size: 76)),
                    const SizedBox(height: 14),
                    Text(
                      'سكني',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تطبيق المدينة الجامعية',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 26),
                    CustomCard(
                      padding: const EdgeInsets.all(18),
                      showBorder: false,
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'تسجيل الدخول',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أدخل بياناتك للوصول إلى حسابك',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _emailController,
                            label: 'البريد الإلكتروني',
                            hint: 'example@university.edu',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isLoading,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'يرجى إدخال البريد الإلكتروني';
                              }
                              if (!trimmed.contains('@')) {
                                return 'صيغة البريد الإلكتروني غير صحيحة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            enabled: !isLoading,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            onFieldSubmitted: (_) => _handleLogin(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              if (value.length < 6) {
                                return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
                              }
                              return null;
                            },
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () => context.pushNamed(
                                        AppRoutes.forgotPassword,
                                      ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 36),
                              ),
                              child: const Text('نسيت كلمة المرور؟'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          CustomButton(
                            label: 'تسجيل الدخول',
                            icon: Icons.login_rounded,
                            isLoading: isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ليس لديك حساب؟',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () => context.pushNamed(
                                          AppRoutes.register,
                                        ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                ),
                                child: const Text('إنشاء حساب جديد'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'بوابتك للسكن الجامعي',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
