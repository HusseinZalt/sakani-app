import 'package:equatable/equatable.dart';

/// حالة طلب الانضمام لغروب سكن (`InvitationStatus` الحقيقية).
enum InvitationStatus {
  pending(0, 'قيد الانتظار'),
  accepted(1, 'مقبول'),
  rejected(2, 'مرفوض'),
  cancelled(3, 'ملغى');

  const InvitationStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  static InvitationStatus fromApiValue(int value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

/// طلب انضمام طالب لغروب — الطالب هو من يبادر بالطلب (سحب وليس دفعاً)
/// عبر الانضمام بالكود، وقائد الغروب هو من يوافق/يرفض. تظهر هذه القائمة
/// فقط للقائد ضمن غروبه.
///
/// [studentName] مؤكَّد بالاختبار الفعلي (2026-08-24): الباك إند صار
/// يرجعه ضمن `GroupInvitationDto` (`invitedStudentName`) بعد ما كان
/// غائباً تماماً بالبداية — يبقى نفس الحقل اختيارياً بالتطبيق تحسباً.
class GroupInvitation extends Equatable {
  const GroupInvitation({
    required this.id,
    required this.invitedStudentId,
    required this.status,
    required this.sentAt,
    this.studentName,
  });

  final int id;
  final String invitedStudentId;
  final InvitationStatus status;
  final DateTime sentAt;
  final String? studentName;

  @override
  List<Object?> get props => [
    id,
    invitedStudentId,
    status,
    sentAt,
    studentName,
  ];
}
