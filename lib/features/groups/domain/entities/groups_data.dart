import 'package:equatable/equatable.dart';

import 'group_invite.dart';
import 'student_group.dart';

/// تجميعة بيانات شاشة الغروبات: غروبي الحالي (إن وُجد) ودعوات الانضمام
/// المعلّقة، تُجلب دفعة واحدة عبر [GroupsRepository.fetchGroupsData].
class GroupsData extends Equatable {
  const GroupsData({required this.myGroup, required this.invites});

  /// الغروب الذي ينتمي إليه المستخدم حالياً، أو null إذا لم ينضم لأي غروب.
  final StudentGroup? myGroup;
  final List<GroupInvite> invites;

  @override
  List<Object?> get props => [myGroup, invites];
}
