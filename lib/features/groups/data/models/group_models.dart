import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/groups_data.dart';
import '../../domain/entities/student_group.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.id,
    required super.name,
    required super.isLeader,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isLeader: json['isLeader'] as bool,
    );
  }
}

class StudentGroupModel extends StudentGroup {
  const StudentGroupModel({
    required super.id,
    required super.code,
    required super.maxMembers,
    required super.members,
  });

  factory StudentGroupModel.fromJson(Map<String, dynamic> json) {
    return StudentGroupModel(
      id: json['id'] as String,
      code: json['code'] as String,
      maxMembers: json['maxMembers'] as int,
      members:
          (json['members'] as List)
              .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class GroupInviteModel extends GroupInvite {
  const GroupInviteModel({
    required super.id,
    required super.groupId,
    required super.groupLabel,
    required super.fromUserName,
  });

  factory GroupInviteModel.fromJson(Map<String, dynamic> json) {
    return GroupInviteModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      groupLabel: json['groupLabel'] as String,
      fromUserName: json['fromUserName'] as String,
    );
  }
}

class GroupsDataModel extends GroupsData {
  const GroupsDataModel({required super.myGroup, required super.invites});
}
