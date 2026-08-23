import '../../../../core/utils/parse_utc_date_time.dart';
import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/student_group.dart';

class GroupInvitationModel extends GroupInvitation {
  const GroupInvitationModel({
    required super.id,
    required super.invitedStudentId,
    required super.status,
    required super.sentAt,
  });

  factory GroupInvitationModel.fromJson(Map<String, dynamic> json) {
    return GroupInvitationModel(
      id: json['id'] as int,
      invitedStudentId: json['invitedStudentId'] as String? ?? '',
      status: InvitationStatus.fromApiValue(json['status'] as int? ?? 0),
      sentAt: parseUtcDateTime(json['sentAt'] as String),
    );
  }
}

class StudentGroupModel extends StudentGroup {
  const StudentGroupModel({
    required super.id,
    required super.code,
    required super.leaderId,
    required super.maxMembers,
    required super.memberStudentIds,
    required super.status,
    super.description,
    super.pendingInvitations,
  });

  /// يحوّل عنصر `HousingGroupDto` من خدمة السكن الحقيقية (ASP.NET Core،
  /// راجع `HousingService_Guide.md`) إلى نموذج التطبيق.
  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    return StudentGroupModel(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      leaderId: json['leaderId'] as String? ?? '',
      maxMembers: json['maxMembers'] as int? ?? 4,
      memberStudentIds:
          (json['memberStudentIds'] as List?)?.cast<String>() ?? const [],
      status: HousingGroupStatus.fromApiValue(json['status'] as int? ?? 0),
      description: json['description'] as String?,
      pendingInvitations:
          (json['pendingInvitations'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupInvitationModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
