import '../../../../core/network/api_client.dart';
import '../../../../core/utils/parse_utc_date_time.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/entities/complaint_reply.dart';

class ComplaintReplyModel extends ComplaintReply {
  const ComplaintReplyModel({required super.text, required super.createdAt});

  factory ComplaintReplyModel.fromJson(Map<String, dynamic> json) {
    return ComplaintReplyModel(
      text: json['text'] as String,
      createdAt: parseUtcDateTime(json['createdAt'] as String),
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
    super.isAnonymous,
    super.imageUrls,
    super.adminReply,
  });

  /// يحوّل استجابة `FeedbackReadDto` من خدمة الآراء الحقيقية (ASP.NET Core،
  /// راجع `/swagger/v1/swagger.json` على الخدمة) إلى نموذج التطبيق.
  ///
  /// ⚠️ افتراض تأكَّد صحته عملياً (2026-08-17) عبر تقديم شكوى تجريبية
  /// حقيقية: 0=شكوى، 1=اقتراح، مطابق تماماً لترتيب "الشكاوى والاقتراحات"
  /// بتسمية الشاشة.
  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final images =
        (json['images'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((img) => img['imagePath'] as String?)
            .whereType<String>()
            .map(_resolveImageUrl)
            .toList() ??
        const <String>[];

    final replyText = json['adminReply'] as String?;
    final repliedAt = json['repliedAt'] as String?;

    return ComplaintModel(
      id: json['id'].toString(),
      userId: json['studentId'] as String? ?? '',
      type: _typeFromApi(json['type'] as int? ?? 0),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // 'resolved' الآن تعني رداً فعلياً من الإدارة (adminReply)، وليس
      // مجرد مراجعة (isRead) — أدق تمثيلاً لما تعنيه "تم الحل" فعلياً.
      status: replyText != null ? 'resolved' : 'pending',
      createdAt: parseUtcDateTime(json['createdAt'] as String),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      imageUrls: images,
      adminReply:
          replyText != null
              ? ComplaintReplyModel(
                text: replyText,
                createdAt:
                    repliedAt != null
                        ? parseUtcDateTime(repliedAt)
                        : DateTime.now().toUtc(),
              )
              : null,
    );
  }

  static String _typeFromApi(int value) => value == 1 ? 'suggestion' : 'complaint';

  static int typeToApi(String type) => type == 'suggestion' ? 1 : 0;

  /// `imagePath` بالاستجابة مسار نسبي غالباً (لم يُؤكَّد الشكل فعلياً بعد)؛
  /// نحوّله لرابط كامل ببادئة عنوان خدمة الآراء نفسها إن لم يكن رابطاً
  /// مطلقاً أصلاً.
  static String _resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${ApiClient.feedbackBaseUrl}$normalized';
  }
}
