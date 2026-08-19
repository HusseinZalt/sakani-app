/// يفكّ ترميز طابع زمني قادم من الخادم إلى [DateTime] بمنطقة UTC دائماً.
///
/// ⚠️ بعض حقول الاستجابة (متل `repliedAt` بخدمة الآراء) تصل أحياناً بدون
/// لاحقة `Z`/إزاحة (مثال حقيقي رُصِد: `"2026-08-17T22:07:26.2793667"`)، رغم
/// أنّ القيمة فعلياً بتوقيت UTC (كل حقول الخادم UTC، متل `createdAt` يلي
/// وصل بنفس الاستجابة مع `Z`). `DateTime.parse` بهيك حالة بفسّرها كوقت محلي
/// خاطئ، وهاد كان بيسبب فرق ساعات وهمي بالوقت النسبي المعروض (formatRelativeTime).
/// هاد الهيلبر بيتأكد إنو القيمة دايماً موسومة UTC بغض النظر عن وجود `Z`.
DateTime parseUtcDateTime(String value) {
  final parsed = DateTime.parse(value);
  if (parsed.isUtc) return parsed;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
