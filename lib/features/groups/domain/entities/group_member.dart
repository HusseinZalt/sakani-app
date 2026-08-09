import 'package:equatable/equatable.dart';

/// عضو ضمن غروب السكن.
class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.name,
    required this.isLeader,
  });

  final String id;
  final String name;

  /// هل هذا العضو هو قائد الغروب (منشئه).
  final bool isLeader;

  /// الحروف الأولى من الاسم لعرضها داخل الصورة الرمزية الدائرية.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  @override
  List<Object?> get props => [id, name, isLeader];
}
