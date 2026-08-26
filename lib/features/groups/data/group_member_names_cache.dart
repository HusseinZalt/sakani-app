import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي (SharedPreferences) لأسماء طلاب مرتبطة بمعرّفاتهم، مبني من
/// طلبات الانضمام التي مرّت أمام قائد الغروب — هذه الطلبات وحدها تحمل اسماً
/// حقيقياً ([GroupInvitation.studentName]) قبل أن يوافق عليها القائد.
///
/// خدمة السكن لا تُرجع أسماء لقائمة أعضاء الغروب الفعليين إطلاقاً (راجع
/// التوثيق في `student_group.dart`)، فهذا أفضل تقريب ممكن من طرف التطبيق
/// وحده: كل عضو ينضم عبر كود يمرّ حتماً كطلب معلَّق يوافق/يرفض عليه القائد،
/// فيصل اسمه لجهاز القائد تحديداً في تلك اللحظة — نخزّنه هنا فوراً حتى لو
/// اختفى الطلب لاحقاً من قائمة "المعلَّقة" بعد قبوله.
///
/// حدود معروفة: يعمل فقط على جهاز القائد (العضو العادي لا تصله بيانات
/// طلبات الانضمام إطلاقاً)، ولا يمكنه استرجاع اسم عضو انضمّ وتمت الموافقة
/// عليه قبل تفعيل هذا التخزين لأول مرة.
class GroupMemberNamesCache {
  const GroupMemberNamesCache._();

  static const _key = 'group_member_names_cache';

  static Future<void> merge(Map<String, String> names) async {
    if (names.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await _read(prefs);
    current.addAll(names);
    await prefs.setString(_key, jsonEncode(current));
  }

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  static Future<Map<String, String>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (_) {
      return {};
    }
  }
}
