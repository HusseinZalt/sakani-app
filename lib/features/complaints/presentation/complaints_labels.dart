/// تسميات الشكاوى والاقتراحات بالعربية.
class ComplaintsLabels {
  const ComplaintsLabels._();

  static const Map<String, String> types = {
    'complaint': 'شكوى',
    'suggestion': 'اقتراح',
  };

  static const Map<String, String> statuses = {
    'pending': 'قيد المعالجة',
    'resolved': 'تم الحل',
  };

  static String typeLabel(String key) => types[key] ?? key;

  static String statusLabel(String key) => statuses[key] ?? key;
}
