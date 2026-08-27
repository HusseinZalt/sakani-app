import 'package:shared_preferences/shared_preferences.dart';

/// طلب انضمام أرسله الطالب بنفسه، وما زال (على حد علم التطبيق) بانتظار
/// رد قائد الغروب — راجع التوثيق المفصَّل على [PendingJoinRequestStorage].
class PendingJoinRequest {
  const PendingJoinRequest({required this.code, required this.sentAt});

  final String code;
  final DateTime sentAt;

  Duration get elapsed => DateTime.now().difference(sentAt);
}

/// تخزين محلي (SharedPreferences) لكود آخر طلب انضمام أرسله الطالب
/// ووقت إرساله، بانتظار رد قائد الغروب عليه.
///
/// **حدود معروفة، مهم فهمها:** خدمة السكن لا توفّر أي نقطة نهاية للطالب
/// يستعلم فيها عن حالة طلب الانضمام يلي أرسله بنفسه، ولا نقطة لإلغائه
/// فعلياً على الخادم (`POST /api/housing-groups/invitations/{id}/respond`
/// مخصّصة لقائد الغروب فقط ليوافق/يرفض، وليست للطالب نفسه). هذا يعني
/// تحديداً: **لو رفض القائد الطلب (وليس بس تجاهله)، ما في أي طريقة يعرف
/// فيها التطبيق بذلك** — الرفض والصمت يبدوان متطابقين تماماً من منظور
/// الطالب. لذلك:
/// - هذا التخزين مجرد تتبّع محلي بحت لعرض واجهة "بانتظار الرد" ومنع
///   الطالب من إرسال طلب انضمام تاني أو إنشاء غروب جديد بينما طلبه
///   الحالي معلَّق — وليس مصدر حقيقة فعلياً موجود على الخادم.
/// - بعد مضي وقت طويل بلا رد (راجع `_staleAfter` بالشاشة)، تعرض الواجهة
///   تلميحاً صريحاً إنه الطلب ممكن يكون انرفض فعلاً بصمت، وتشجّع الطالب
///   يلغي الانتظار بنفسه — أفضل تخفيف ممكن بغياب أي إشارة حقيقية من
///   الخادم، وليس حلاً كاملاً.
/// - "إلغاء الانتظار" هنا يمسح هذا التتبّع المحلي فقط؛ الطلب الأصلي يبقى
///   معلَّقاً فعلياً عند الخادم حتى يستجيب له القائد لاحقاً (فلو استجاب
///   بالموافقة بعد إلغاء الطالب انتظاره محلياً، سينضم فعلياً لذلك الغروب
///   عند أول تحديث للبيانات — حالة نادرة ناتجة عن عدم وجود نقطة نهاية
///   حقيقية للإلغاء، وليست خطأً بالتطبيق).
class PendingJoinRequestStorage {
  const PendingJoinRequestStorage._();

  static const _codeKey = 'pending_group_join_code';
  static const _sentAtKey = 'pending_group_join_sent_at';

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, code);
    await prefs.setString(_sentAtKey, DateTime.now().toUtc().toIso8601String());
  }

  static Future<PendingJoinRequest?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_codeKey);
    if (code == null) return null;
    final sentAtRaw = prefs.getString(_sentAtKey);
    final sentAt =
        sentAtRaw != null ? DateTime.tryParse(sentAtRaw)?.toLocal() : null;
    // احتياطي لو غاب وقت الإرسال لأي سبب (تخزين من نسخة أقدم من
    // التطبيق مثلاً) — نعتبره "الآن" بدل طرح خطأ أو اعتباره قديماً جداً.
    return PendingJoinRequest(code: code, sentAt: sentAt ?? DateTime.now());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codeKey);
    await prefs.remove(_sentAtKey);
  }
}
