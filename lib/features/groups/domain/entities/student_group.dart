import 'package:equatable/equatable.dart';

import 'group_invitation.dart';

/// حالة غروب السكن (`HousingGroupStatus` الحقيقية).
enum HousingGroupStatus {
  open(0, 'مفتوح لانضمام أعضاء جدد'),
  locked(1, 'مكتمل — بانتظار التخصيص'),
  allocated(2, 'تم تخصيص السكن'),
  closed(3, 'مغلق');

  const HousingGroupStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  static HousingGroupStatus fromApiValue(int value) {
    return HousingGroupStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => HousingGroupStatus.open,
    );
  }
}

/// غروب سكن جامعي: مجموعة طلاب يرغبون بمشاركة نفس الوحدة السكنية.
///
/// ملاحظة مهمة: الباك إند لا يُرجع أسماء الأعضاء إطلاقاً — فقط معرّفاتهم
/// (`memberStudentIds`)، ولا توجد نقطة نهاية متاحة للتطبيق لتحويل معرّف
/// طالب إلى اسمه (نقاط البحث الداخلية بين الخدمات فقط، خادم-لخادم). لذلك
/// تُعرض الأعضاء بواجهة التطبيق كـ"أنت"/"عضو" بدل أسماء حقيقية.
class StudentGroup extends Equatable {
  const StudentGroup({
    required this.id,
    required this.code,
    required this.leaderId,
    required this.maxMembers,
    required this.memberStudentIds,
    required this.status,
    this.description,
    this.pendingInvitations = const [],
  });

  final int id;

  /// كود الدعوة الخاص بالغروب (مثال: GRP-2026-R7K9).
  final String code;
  final String leaderId;
  final int maxMembers;
  final List<String> memberStudentIds;
  final HousingGroupStatus status;
  final String? description;

  /// تظهر فقط للقائد (تُرجعها الخدمة فارغة لغير القائد).
  final List<GroupInvitation> pendingInvitations;

  int get memberCount => memberStudentIds.length;

  bool get isFull => memberCount >= maxMembers;

  bool isLeader(String? studentId) => studentId != null && studentId == leaderId;

  @override
  List<Object?> get props => [
    id,
    code,
    leaderId,
    maxMembers,
    memberStudentIds,
    status,
    description,
    pendingInvitations,
  ];
}
