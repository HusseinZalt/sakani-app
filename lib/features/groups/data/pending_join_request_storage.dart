import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي (SharedPreferences) لكود آخر طلب انضمام أرسله الطالب،
/// بانتظار رد قائد الغروب عليه.
///
/// **حدود معروفة، مهم فهمها:** خدمة السكن لا توفّر أي نقطة نهاية للطالب
/// يستعلم فيها عن حالة طلب الانضمام يلي أرسله بنفسه، ولا نقطة لإلغائه
/// فعلياً على الخادم (`POST /api/housing-groups/invitations/{id}/respond`
/// مخصّصة لقائد الغروب فقط ليوافق/يرفض، وليست للطالب نفسه). لذلك:
/// - هذا التخزين مجرد تتبّع محلي بحت لعرض واجهة "بانتظار الرد" ومنع
///   الطالب من إرسال طلب انضمام تاني أو إنشاء غروب جديد بينما طلبه
///   الحالي معلَّق — وليس مصدر حقيقة فعلياً موجود على الخادم.
/// - "إلغاء الانتظار" هنا يمسح هذا التتبّع المحلي فقط؛ الطلب الأصلي يبقى
///   معلَّقاً فعلياً عند الخادم حتى يستجيب له القائد لاحقاً (فلو استجاب
///   بالموافقة بعد إلغاء الطالب انتظاره محلياً، سينضم فعلياً لذلك الغروب
///   عند أول تحديث للبيانات — حالة نادرة ناتجة عن عدم وجود نقطة نهاية
///   حقيقية للإلغاء، وليست خطأً بالتطبيق).
class PendingJoinRequestStorage {
  const PendingJoinRequestStorage._();

  static const _key = 'pending_group_join_code';

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
