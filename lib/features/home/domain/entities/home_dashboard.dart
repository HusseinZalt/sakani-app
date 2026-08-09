import 'package:equatable/equatable.dart';

/// حالة طلب السكن الجامعي كما تظهر في لوحة الرئيسية.
///
/// القيمة الممكنة لـ [status]: pending (قيد المراجعة)، accepted (مقبول)،
/// rejected (مرفوض)، none (لم يقدَّم طلب بعد).
class HousingStatus extends Equatable {
  const HousingStatus({
    required this.status,
    this.buildingUnit,
    this.roomNumber,
    this.daysUntilPayment,
    this.paymentReference,
  });

  final String status;
  final String? buildingUnit;
  final String? roomNumber;
  final int? daysUntilPayment;
  final String? paymentReference;

  @override
  List<Object?> get props => [
    status,
    buildingUnit,
    roomNumber,
    daysUntilPayment,
    paymentReference,
  ];
}

/// إعلان إداري يظهر ضمن الشريط الدوّار (Swiper) أعلى الرئيسية.
class Announcement extends Equatable {
  const Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.colorVariant,
  });

  final String id;
  final String title;
  final String subtitle;

  /// نمط لوني للبطاقة: 'primary' أو 'warning'، يحدد التدرج اللوني المستخدم.
  final String colorVariant;

  @override
  List<Object?> get props => [id, title, subtitle, colorVariant];
}

/// عنصر في سجل آخر النشاطات.
class ActivityLogItem extends Equatable {
  const ActivityLogItem({
    required this.id,
    required this.text,
    required this.time,
    required this.colorKey,
  });

  final String id;
  final String text;
  final String time;

  /// مفتاح لون النقطة الدالة على نوع النشاط: success, info, neutral.
  final String colorKey;

  @override
  List<Object?> get props => [id, text, time, colorKey];
}

/// تجميعة بيانات لوحة الرئيسية بالكامل، تُجلَب دفعة واحدة عبر
/// [HomeRepository.fetchDashboard] (مطابقةً لنمط "GET /dashboard" شائع
/// في الباك إند الحقيقي مستقبلاً).
class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.studentName,
    required this.housingStatus,
    required this.announcements,
    required this.activities,
  });

  final String studentName;
  final HousingStatus housingStatus;
  final List<Announcement> announcements;
  final List<ActivityLogItem> activities;

  @override
  List<Object?> get props => [
    studentName,
    housingStatus,
    announcements,
    activities,
  ];
}
