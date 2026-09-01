import 'package:equatable/equatable.dart';

import 'housing_document.dart';

/// حالة طلب السكن العامة حسب `HousingRequestStatus` الحقيقية.
enum HousingRequestStatus {
  submitted(0, 'قيد المراجعة'),
  needsRevision(1, 'يحتاج تعديل'),
  locked(2, 'صدر قرار نهائي');

  const HousingRequestStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  static HousingRequestStatus fromApiValue(int value) {
    return HousingRequestStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => HousingRequestStatus.submitted,
    );
  }
}

/// حالة قرار القبول (`AdmissionDecisionStatus`) — قد لا يكون هناك قرار
/// بعد ([AdmissionDecision] بأكمله `null`).
enum AdmissionDecisionStatus {
  pending(0, 'قيد الانتظار'),
  accepted(1, 'مقبول'),
  waitingList(2, 'قائمة الانتظار'),
  rejected(3, 'مرفوض');

  const AdmissionDecisionStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  static AdmissionDecisionStatus fromApiValue(int value) {
    return AdmissionDecisionStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => AdmissionDecisionStatus.pending,
    );
  }
}

/// قرار القبول الصادر لطلب سكن واحد، إن وُجد.
class AdmissionDecision extends Equatable {
  const AdmissionDecision({
    required this.status,
    this.decisionReason,
    this.decisionDate,
  });

  final AdmissionDecisionStatus status;
  final String? decisionReason;
  final DateTime? decisionDate;

  @override
  List<Object?> get props => [status, decisionReason, decisionDate];
}

/// طلب سكن جامعي قدّمه الطالب — مطابق لـ `HousingRequestDto` الحقيقية.
///
/// ملاحظة: الطالب لا يختار غرفة ولا يقدّم "كغروب" وقت التقديم — طلب فردي
/// دائماً؛ الانضمام لغروب يتم لاحقاً وبشكل منفصل عبر تبويب "الغروبات"،
/// ويربط طلبات موجودة أصلاً ببعضها دون إنشاء طلب جديد.
class HousingRequest extends Equatable {
  const HousingRequest({
    required this.id,
    required this.gender,
    required this.governorateId,
    required this.academicLevel,
    required this.detailedAddress,
    required this.hasSpecialNeeds,
    required this.isPreviousResident,
    required this.status,
    required this.submittedAt,
    this.previousBuildingId,
    this.previousFloor,
    this.previousRoomNumber,
    this.specialNotes,
    this.documents = const [],
    this.decision,
    this.isPaid = false,
  });

  final int id;

  /// 0=ذكر، 1=أنثى، 2=مختلط (لن يُرسله الطالب فعلياً، فقط لعرض القيمة).
  final int gender;
  final int governorateId;

  /// المستوى الدراسي 1-5.
  final int academicLevel;
  final String detailedAddress;
  final bool hasSpecialNeeds;
  final bool isPreviousResident;
  final int? previousBuildingId;
  final int? previousFloor;
  final String? previousRoomNumber;
  final HousingRequestStatus status;
  final String? specialNotes;
  final List<HousingDocument> documents;
  final AdmissionDecision? decision;
  final DateTime submittedAt;

  /// دُفعت رسوم هذا الطلب فعلياً أم لا — حقل حقيقي دائم من `HousingRequestDto`
  /// (وليس تتبّعاً محلياً)، يحدّد وحده ظهور زر الدفع بشاشة الحالة.
  final bool isPaid;

  @override
  List<Object?> get props => [
    id,
    gender,
    governorateId,
    academicLevel,
    detailedAddress,
    hasSpecialNeeds,
    isPreviousResident,
    previousBuildingId,
    previousFloor,
    previousRoomNumber,
    status,
    specialNotes,
    documents,
    decision,
    submittedAt,
    isPaid,
  ];
}
