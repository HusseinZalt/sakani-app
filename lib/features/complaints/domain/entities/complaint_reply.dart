import 'package:equatable/equatable.dart';

/// رد الإدارة على شكوى أو اقتراح.
class ComplaintReply extends Equatable {
  const ComplaintReply({required this.text, required this.createdAt});

  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [text, createdAt];
}
