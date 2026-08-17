import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/routing/app_router.dart';
import 'core/session/user_session_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  runApp(MyApp(themeController: themeController));

  // بدون انتظار (fire-and-forget) حتى لا يتأخر ظهور واجهة التطبيق بسبب
  // نافذة إذن الإشعارات ونداء الشبكة لجلب رمز الجهاز. مُهيّأ فقط لأندرويد/iOS
  // حالياً (google-services.json مضبوط للأندرويد فقط) — تفعيلها على الويب
  // يحتاج FirebaseOptions صريحة (flutterfire configure) غير مُعدّة بعد،
  // فتفشل بخطأ غير معالَج لو استُدعيت هناك. أي فشل آخر (جهاز بدون خدمات
  // جوجل مثلاً) يُلتقط بصمت أيضاً حتى لا يؤثر على بقية التطبيق.
  // TODO: عند توفر نقطة نهاية تسجيل رمز الجهاز (FCM Token) من فريق الباك
  // إند، اربطها هنا عبر PushNotificationService.instance.onTokenRegistered.
  if (!kIsWeb) {
    unawaited(
      PushNotificationService.instance.initialize().catchError((
        Object error,
      ) {
        debugPrint('تعذّر تهيئة خدمة الإشعارات: $error');
      }),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // يُحدَّث سطوع الألوان تلقائياً إذا كان وضع التطبيق "حسب النظام" وبدّل
    // المستخدم إعداد نظام التشغيل بينما التطبيق مفتوح.
    widget.themeController.syncWithPlatformBrightness(
      SchedulerBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      // يُوفَّر مرة واحدة هنا في الجذر ليتمكن أي مكان في التطبيق (شاشة
      // الإعدادات) من قراءة وتبديل وضع الثيم الحالي عبر context.read/watch،
      // مع إعادة بناء تلقائية للمعتمِدين (ChangeNotifierProvider خاص
      // بالكائنات القابلة للاستماع، خلافاً لـ RepositoryProvider العادي).
      value: widget.themeController,
      child: BlocProvider(
        // يُوفَّر مرة واحدة هنا في الجذر ليبقى المصدر الوحيد لبيانات المستخدم
        // الحالي عبر كل شاشات التطبيق.
        create: (_) => UserSessionCubit(),
        child: ListenableBuilder(
          listenable: widget.themeController,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'سكني',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: widget.themeController.mode,
              routerConfig: AppRouter.router,

              // دعم اللغة العربية واتجاه الكتابة من اليمين إلى اليسار (RTL).
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  // شاشات كثيرة تقرأ ألوانها (خلفية الـ Scaffold مثلاً) عبر
                  // AppColors.xxx مباشرة كقيمة ثابتة داخل build()، وليس عبر
                  // Theme.of(context) — وهي آلية لا يتتبعها نظام إعادة
                  // البناء بفلاتر إطلاقاً. لذلك لا يُعاد بناء الشاشة تلقائياً
                  // عند تبديل الثيم إلا إذا كانت أصلاً "تراقب" شيئاً آخر
                  // يتغيّر (مثل Cubit)، وإلا بقيت عالقة بالألوان القديمة
                  // إلى أن تُعاد بناؤها لسبب آخر (كالخروج من الشاشة
                  // والعودة إليها). الحل: نفرض إعادة بناء الشجرة الموجّهة
                  // بالكامل من الصفر عند تغيّر السطوع الفعلي عبر مفتاح
                  // (Key) متغيّر، فتلتقط كل الشاشات القيم الجديدة فوراً.
                  child: KeyedSubtree(
                    key: ValueKey(AppColors.brightness),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
