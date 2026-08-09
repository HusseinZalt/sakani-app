/// تسميات طلب السكن بالعربية.
class HousingRequestLabels {
  const HousingRequestLabels._();

  static const Map<String, String> requestTypes = {
    'individual': 'طلب فردي',
    'group': 'طلب كغروب',
  };

  static const Map<String, String> roomTypes = {
    'shared': 'غرفة مشتركة',
    'private': 'غرفة فردية',
  };

  static const Map<String, String> buildings = {
    'unit_a': 'الوحدة أ',
    'unit_b': 'الوحدة ب',
    'unit_c': 'الوحدة ج',
    'none': 'بدون تفضيل',
  };

  static const Map<String, String> statuses = {
    'pending': 'قيد المراجعة',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
  };

  static String requestTypeLabel(String key) => requestTypes[key] ?? key;

  static String roomTypeLabel(String key) => roomTypes[key] ?? key;

  static String buildingLabel(String key) => buildings[key] ?? key;

  static String statusLabel(String key) => statuses[key] ?? key;
}
