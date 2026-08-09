// اختبار تحقق أساسي (Smoke Test) للتأكد من أن التطبيق يقلع بنجاح، يعرض شاشة
// البداية (Splash)، ثم ينتقل تلقائياً إلى شاشة تسجيل الدخول دون أخطاء.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sakani/core/theme/theme_controller.dart';
import 'package:sakani/main.dart';

void main() {
  testWidgets('التطبيق يقلع ويعرض شاشة البداية ثم ينتقل لتسجيل الدخول',
      (WidgetTester tester) async {
    final themeController = await ThemeController.load();
    await tester.pumpWidget(MyApp(themeController: themeController));
    await tester.pump();

    expect(find.text('سكني'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // تفريغ مؤقت الانتقال التلقائي في شاشة البداية (2 ثانية) ثم انتظار
    // استقرار التنقل عبر GoRouter.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsWidgets);
  });
}
