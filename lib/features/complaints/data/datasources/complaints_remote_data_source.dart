import '../../../../core/network/api_result.dart';
import '../../../../core/session/mock_current_user.dart';
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
  static const _placeholderUserId = 'usr_1001';
  static const _placeholderUserName = 'أحمد محمد';

  static String? _currentUserId;
  static bool _seedPatched = false;

  static final List<ComplaintModel> _complaints = [
    ComplaintModel(
      id: 'cmp_6001',
      userId: _placeholderUserId,
      type: 'complaint',
      title: 'مشكلة في التكييف',
      description: 'التكييف لا يعمل بشكل جيد في غرفتي',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ComplaintModel(
      id: 'cmp_6002',
      userId: _placeholderUserId,
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

  /// يحمّل هوية المستخدم الحقيقي الحالي (مرة واحدة)، ويستبدل بها بذور
  /// البيانات الوهمية المُعلَّمة بالمعرّف البديل، حتى لا تظهر شكاوى/بيانات
  /// حساب تجريبي منفصل تماماً عن المستخدم المسجَّل دخوله فعلياً.
  Future<void> _ensureCurrentUser() async {
    if (_currentUserId != null) return;

    final resolved = await MockCurrentUser.resolve(
      placeholderId: _placeholderUserId,
      placeholderName: _placeholderUserName,
    );
    _currentUserId = resolved.id;

    if (_seedPatched || resolved.id == _placeholderUserId) return;
    _seedPatched = true;
    for (var i = 0; i < _complaints.length; i++) {
      if (_complaints[i].userId != _placeholderUserId) continue;
      _complaints[i] = ComplaintModel(
        id: _complaints[i].id,
        userId: resolved.id,
        type: _complaints[i].type,
        title: _complaints[i].title,
        description: _complaints[i].description,
        status: _complaints[i].status,
        createdAt: _complaints[i].createdAt,
        adminReply: _complaints[i].adminReply,
      );
    }
  }

  Future<List<ComplaintModel>> fetchComplaints() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);
    final mine =
        _complaints.where((c) => c.userId == _currentUserId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<ComplaintModel> fetchComplaintById(String id) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final match =
        _complaints
            .where((c) => c.id == id && c.userId == _currentUserId)
            .toList();
    if (match.isEmpty) {
      throw const ComplaintsException(
        'لم يتم العثور على الشكوى المطلوبة.',
        type: ApiErrorType.notFound,
      );
    }
    return match.first;
  }

  Future<ComplaintModel> submitComplaint({
    required String type,
    required String title,
    required String description,
  }) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    if (title.trim().isEmpty) {
      throw const ComplaintsException('يرجى إدخال العنوان.');
    }
    if (description.trim().length < 10) {
      throw const ComplaintsException('يرجى كتابة وصف لا يقل عن 10 أحرف.');
    }

    final complaint = ComplaintModel(
      id: 'cmp_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
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
