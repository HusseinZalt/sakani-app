/// يبني نصاً عربياً للوقت النسبي المنقضي منذ [date] ("منذ 3 أيام"، "منذ
/// أسبوعين"...)، بمقياس موحّد عبر كل شاشات التطبيق حتى لا يظهر نفس التاريخ
/// بصياغتين مختلفتين على شاشتين مختلفتين لنفس العنصر.
String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 7) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
  if (diff.inDays >= 1) {
    return 'منذ ${diff.inDays} ${diff.inDays == 1 ? 'يوم' : 'أيام'}';
  }
  if (diff.inHours >= 1) {
    return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
  }
  return 'منذ قليل';
}
