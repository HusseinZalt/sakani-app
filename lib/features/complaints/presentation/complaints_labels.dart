/// تسميات الشكاوى والاقتراحات بالعربية.
class ComplaintsLabels {
  const ComplaintsLabels._();

  static const Map<String, String> types = {
    'complaint': 'شكوى',
    'suggestion': 'اقتراح',
  };

  // 'resolved' تعني الآن رداً فعلياً من الإدارة (adminReply من الـ API
  // الحقيقي)، وليست مجرد علامة "تمت المراجعة" كما كانت سابقاً.
  static const Map<String, String> statuses = {
    'pending': 'قيد المعالجة',
    'resolved': 'تم الرد',
  };

  static String typeLabel(String key) => types[key] ?? key;

  static String statusLabel(String key) => statuses[key] ?? key;
}
