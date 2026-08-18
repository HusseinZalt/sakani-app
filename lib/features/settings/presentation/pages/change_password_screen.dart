import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

enum _Stage { verifyCurrent, setNew }

/// شاشة تغيير كلمة المرور من الإعدادات، على مرحلتين حقيقيتين:
///
/// 1. التحقق من كلمة المرور الحالية فعلياً عبر محاولة تسجيل دخول بها
///    (`AuthRepository.login`) — لا يُسمح بالمتابعة إن كانت خاطئة.
/// 2. إدخال كلمة مرور جديدة. بما أن خدمة المصادقة لا توفر حالياً نقطة
///    نهاية مخصّصة لتغيير كلمة المرور أثناء تسجيل الدخول، تُستخدم آلية
///    `forgot-password`/`reset-password` (يُرسَل رمز تأكيد للبريد
///    تلقائياً فور نجاح المرحلة الأولى) لإتمام التغيير فعلياً على
///    الخادم.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _authRepository = AuthRepositoryImpl();

  final _currentFormKey = GlobalKey<FormState>();
  final _newFormKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _codeController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  _Stage _stage = _Stage.verifyCurrent;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _codeController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyCurrentPassword() async {
    if (!_currentFormKey.currentState!.validate()) return;

    final email = context.read<UserSessionCubit>().state?.email;
    if (email == null) return;

    setState(() => _isSubmitting = true);
    final loginResult = await _authRepository.login(
      email: email,
      password: _currentController.text,
    );
    if (!mounted) return;

    if (!loginResult.isSuccess) {
      setState(() => _isSubmitting = false);
      _showError(
        loginResult.failureOrNull!.type == ApiErrorType.unauthorized
            ? 'كلمة المرور الحالية غير صحيحة.'
            : loginResult.failureOrNull!.message,
      );
      return;
    }

    // كلمة المرور الحالية صحيحة — أرسل رمز تأكيد للبريد لإتمام التغيير.
    final codeResult = await _authRepository.forgotPassword(email: email);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!codeResult.isSuccess) {
      _showError(codeResult.failureOrNull!.message);
      return;
    }

    setState(() => _stage = _Stage.setNew);
  }

  Future<void> _submitNewPassword() async {
    if (!_newFormKey.currentState!.validate()) return;

    final email = context.read<UserSessionCubit>().state?.email;
    if (email == null) return;

    setState(() => _isSubmitting = true);
    final result = await _authRepository.resetPassword(
      email: email,
      code: _codeController.text.trim(),
      newPassword: _newController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      _showError(result.failureOrNull!.message);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح.')),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: 'تغيير كلمة المرور',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: switch (_stage) {
                  _Stage.verifyCurrent => _buildVerifyStage(),
                  _Stage.setNew => _buildNewPasswordStage(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyStage() {
    return Form(
      key: _currentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أدخل كلمة المرور الحالية للتأكد من هويتك قبل تغييرها.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _currentController,
            label: 'كلمة المرور الحالية',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور الحالية';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'متابعة',
            // اتجاه "متابعة" بالعربي (RTL) بصرياً نحو اليسار — arrow_back
            // يرسم سهماً لليسار فعلياً رغم اسمه.
            icon: Icons.arrow_back_rounded,
            isLoading: _isSubmitting,
            onPressed: _verifyCurrentPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStage() {
    return Form(
      key: _newFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'أرسلنا رمز تأكيد إلى بريدك الإلكتروني لإتمام تغيير كلمة المرور.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _codeController,
            label: 'رمز التأكيد',
            hint: '83920',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال رمز التأكيد'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _newController,
            label: 'كلمة المرور الجديدة',
            hint: '••••••••',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور الجديدة';
              }
              if (value.length < 6) return 'يجب ألا تقل عن 6 أحرف';
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _confirmController,
            label: 'تأكيد كلمة المرور الجديدة',
            hint: '••••••••',
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: true,
            enabled: !_isSubmitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            validator: (value) {
              if (value != _newController.text) {
                return 'كلمتا المرور غير متطابقتين';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'حفظ كلمة المرور الجديدة',
            icon: Icons.check_rounded,
            isLoading: _isSubmitting,
            onPressed: _submitNewPassword,
          ),
        ],
      ),
    );
  }
}
