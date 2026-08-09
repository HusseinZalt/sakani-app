import 'session_storage.dart';

/// يحلّ هوية المستخدم الحقيقي الحالي لصالح مصادر البيانات الوهمية (قبل
/// ربطها بباك إند حقيقي)، مع الرجوع لهوية بديلة ثابتة (placeholder) فقط
/// عندما لا توجد جلسة حقيقية بعد (مثال: فتح شاشة تعتمد على مستخدم حالي دون
/// تسجيل دخول أثناء الاختبار).
///
/// دون هذا الحل، كانت مصادر البيانات الوهمية تستخدم معرّف/اسم مستخدم وهمي
/// منفصل تماماً عن الجلسة الحقيقية — ما يُنتج بيانات لا تخص المستخدم
/// المسجّل فعلياً، ويمنع مقارنات "هل أنا صاحب هذا العنصر؟" من العمل بشكل
/// صحيح (كما حدث في ميزة الغروبات).
class MockCurrentUser {
  const MockCurrentUser._();

  static Future<({String id, String name})> resolve({
    required String placeholderId,
    required String placeholderName,
  }) async {
    final user = await SessionStorage.loadUser();
    return (
      id: user?.id ?? placeholderId,
      name: user?.fullName ?? placeholderName,
    );
  }
}
