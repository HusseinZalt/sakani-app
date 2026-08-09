import 'package:equatable/equatable.dart';

/// دعوة انضمام إلى غروب سكن، مُرسلة من قائد غروب آخر.
class GroupInvite extends Equatable {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupLabel,
    required this.fromUserName,
  });

  final String id;
  final String groupId;

  /// اسم الغروب المعروض (مثال: "غروب الوحدة ب").
  final String groupLabel;
  final String fromUserName;

  @override
  List<Object?> get props => [id, groupId, groupLabel, fromUserName];
}
