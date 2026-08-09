import '../../domain/entities/complaint.dart';
import '../../domain/entities/complaint_reply.dart';

class ComplaintReplyModel extends ComplaintReply {
  const ComplaintReplyModel({required super.text, required super.createdAt});

  factory ComplaintReplyModel.fromJson(Map<String, dynamic> json) {
    return ComplaintReplyModel(
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ComplaintModel extends Complaint {
  const ComplaintModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.description,
    required super.status,
    required super.createdAt,
    super.adminReply,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      adminReply:
          json['adminReply'] != null
              ? ComplaintReplyModel.fromJson(
                json['adminReply'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}
