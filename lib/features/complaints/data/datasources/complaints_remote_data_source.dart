import '../../../../core/network/api_result.dart';
import '../models/complaint_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class ComplaintsException implements Exception {
  const ComplaintsException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الشكاوى والاقتراحات.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات
/// مشتركة (static) في الذاكرة + محاكاة زمن استجابة الشبكة). عند الربط
/// الحقيقي، يكفي استبدال محتوى هذا الملف بطلبات HTTP فعلية دون أي تعديل
/// على الـ Repository أو الـ Cubits أو الشاشات.
/// ==================================================================
class ComplaintsRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 800);

  static final List<ComplaintModel> _complaints = [
    ComplaintModel(
      id: 'cmp_6001',
      type: 'complaint',
      title: 'مشكلة في التكييف',
      description: 'التكييف لا يعمل بشكل جيد في غرفتي',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ComplaintModel(
      id: 'cmp_6002',
      type: 'suggestion',
      title: 'اقتراح تحسين المقصف',
      description: 'أقترح توسيع ساعات عمل المقصف',
      status: 'resolved',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      adminReply: ComplaintReplyModel(
        text: 'شكراً لاقتراحك القيّم. تم رفع الاقتراح للإدارة وسيتم النظر فيه.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ),
  ];

  Future<List<ComplaintModel>> fetchComplaints() async {
    await Future.delayed(_networkDelay);
    final sorted = List<ComplaintModel>.from(_complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<ComplaintModel> submitComplaint({
    required String type,
    required String title,
    required String description,
  }) async {
    await Future.delayed(_networkDelay);

    if (title.trim().isEmpty) {
      throw const ComplaintsException('يرجى إدخال العنوان.');
    }
    if (description.trim().length < 10) {
      throw const ComplaintsException('يرجى كتابة وصف لا يقل عن 10 أحرف.');
    }

    final complaint = ComplaintModel(
      id: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title.trim(),
      description: description.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    _complaints.add(complaint);
    return complaint;
  }
}
