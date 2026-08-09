import 'package:equatable/equatable.dart';

import 'group_member.dart';

/// غروب سكن جامعي: مجموعة طلاب يرغبون بمشاركة نفس الوحدة السكنية.
class StudentGroup extends Equatable {
  const StudentGroup({
    required this.id,
    required this.code,
    required this.maxMembers,
    required this.members,
  });

  final String id;

  /// كود الدعوة الخاص بالغروب (مثال: GRP-2025-A204).
  final String code;

  final int maxMembers;
  final List<GroupMember> members;

  int get memberCount => members.length;

  bool get isFull => memberCount >= maxMembers;

  @override
  List<Object?> get props => [id, code, maxMembers, members];
}
