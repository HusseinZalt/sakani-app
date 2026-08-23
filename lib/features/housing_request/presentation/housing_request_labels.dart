/// تسميات إضافية لطلب السكن بالعربية — الحالات الأساسية (الطلب، المستند،
/// القرار) لها تسمية جاهزة عبر enum.label الخاص بكل منها بالكيانات نفسها.
class HousingRequestLabels {
  const HousingRequestLabels._();

  static const Map<int, String> academicLevels = {
    1: 'السنة الأولى',
    2: 'السنة الثانية',
    3: 'السنة الثالثة',
    4: 'السنة الرابعة',
    5: 'السنة الخامسة',
  };

  static const Map<int, String> genders = {0: 'ذكر', 1: 'أنثى', 2: 'مختلط'};

  static String academicLevelLabel(int level) =>
      academicLevels[level] ?? 'السنة $level';

  static String genderLabel(int gender) => genders[gender] ?? '—';
}
