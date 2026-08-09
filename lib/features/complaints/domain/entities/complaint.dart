import 'package:equatable/equatable.dart';

import 'complaint_reply.dart';

/// شكوى أو اقتراح يقدّمه الطالب.
///
/// [type]: complaint (شكوى) أو suggestion (اقتراح).
/// [status]: pending (قيد المعالجة)، resolved (تم الحل).
class Complaint extends Equatable {
  const Complaint({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.adminReply,
  });

  final String id;

  /// معرّف صاحب الشكوى، لضمان عدم ظهور شكاوى مستخدم آخر عند تبديل الحساب
  /// على نفس الجهاز.
  final String userId;
  final String type;
  final String title;
  final String description;
  final String status;
  final DateTime createdAt;
  final ComplaintReply? adminReply;

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    title,
    description,
    status,
    createdAt,
    adminReply,
  ];
}
