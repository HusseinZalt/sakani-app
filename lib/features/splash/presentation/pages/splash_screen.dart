import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/session_storage.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/pages/otp_verification_screen.dart';

/// شاشة البداية (Splash) التي تظهر عند تشغيل التطبيق أثناء التحقق من
/// وجود جلسة محفوظة محلياً (عبر [SessionStorage])، قبل التوجيه التلقائي
/// إلى الوجهة المناسبة:
/// - جلسة مستخدم مؤكَّدة محفوظة → الرئيسية مباشرة.
/// - حساب أُنشئ ولم يُكمل صاحبه تأكيده عبر OTP → شاشة التأكيد مباشرة.
/// - لا شيء محفوظ → شاشة تسجيل الدخول.
///
/// لاحقاً عند ربط الباك إند، يُستبدل هذا التحقق المحلي بتحقق فعلي من
/// صلاحية رمز الدخول (Token) المحفوظ مع الخادم.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final savedUser = await context.read<UserSessionCubit>().restore();
    if (savedUser != null && savedUser.isVerified) {
      await minDelay;
      if (!mounted) return;
      context.goNamed(AppRoutes.home);
      return;
    }

    final pendingIdentifier = await SessionStorage.loadPendingVerification();
    await minDelay;
    if (!mounted) return;

    if (pendingIdentifier != null && pendingIdentifier.isNotEmpty) {
      context.goNamed(
        AppRoutes.otp,
        extra: OtpRouteArgs(identifier: pendingIdentifier),
      );
    } else {
      context.goNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 110, variant: AppLogoVariant.dark),
              const SizedBox(height: 20),
              Text(
                'سكني',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'بوابتك للسكن الجامعي',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
