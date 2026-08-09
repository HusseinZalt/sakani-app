import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/session/user_session_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = await ThemeController.load();
  runApp(MyApp(themeController: themeController));
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
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
