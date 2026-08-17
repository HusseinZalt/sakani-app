import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/auth_repository_impl.dart';

enum _Stage { email, resetCode, done }

/// شاشة "نسيت كلمة المرور" على ثلاث مراحل: إدخال البريد الإلكتروني وطلب
/// رمز إعادة التعيين، إدخال الرمز مع كلمة مرور جديدة، ثم رسالة نجاح.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepository = AuthRepositoryImpl();

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Stage _stage = _Stage.email;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final result = await _authRepository.forgotPassword(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      setState(() => _stage = _Stage.resetCode);
    } else {
      _showError(result.failureOrNull!.message);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('كلمتا المرور غير متطابقتين.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _authRepository.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      setState(() => _stage = _Stage.done);
    } else {
      _showError(result.failureOrNull!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: 'نسيت كلمة المرور',
              onBack: _stage == _Stage.done ? null : () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (_stage) {
                  _Stage.email => _buildEmailStage(theme),
                  _Stage.resetCode => _buildResetStage(theme),
                  _Stage.done => _buildSuccessView(theme),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStage(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildIconHeader(Icons.lock_reset_rounded),
          const SizedBox(height: 20),
          Text(
            'أدخل بريدك الإلكتروني الجامعي وسنرسل لك رمزاً لإعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@university.edu',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
              if (!trimmed.contains('@')) {
                return 'صيغة البريد الإلكتروني غير صحيحة';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'إرسال رمز إعادة التعيين',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _requestCode,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStage(ThemeData theme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _buildIconHeader(Icons.mark_email_read_outlined),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
              children: [
                const TextSpan(text: 'أدخل الرمز المُرسل إلى\n'),
                TextSpan(
                  text: _emailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(text: '\nوكلمة المرور الجديدة.'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          CustomTextField(
            controller: _codeController,
            label: 'رمز التحقق',
            hint: '83920',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال رمز التحقق'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _newPasswordController,
            label: 'كلمة المرور الجديدة',
            hint: '••••••••',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'يرجى إدخال كلمة المرور الجديدة';
              }
              if (v.length < 6) return 'يجب ألا تقل عن 6 أحرف';
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'تأكيد كلمة المرور الجديدة',
            hint: '••••••••',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator:
                (v) =>
                    (v == null || v.isEmpty) ? 'يرجى تأكيد كلمة المرور' : null,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'إعادة تعيين كلمة المرور',
            icon: Icons.check_rounded,
            isLoading: _isSubmitting,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildIconHeader(IconData icon) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 32),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'تم تغيير كلمة المرور',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        CustomButton(
          label: 'العودة لتسجيل الدخول',
          icon: Icons.login_rounded,
          onPressed: () => context.goNamed(AppRoutes.login),
        ),
      ],
    );
  }
}
