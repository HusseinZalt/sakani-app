import '../../../../core/network/api_result.dart';
import '../../../../core/session/mock_current_user.dart';
import '../../domain/entities/housing_document.dart';
import '../models/housing_request_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class HousingRequestException implements Exception {
  const HousingRequestException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات طلب السكن.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات
/// مشتركة (static) في الذاكرة + محاكاة زمن استجابة الشبكة). عند الربط
/// الحقيقي، يكفي استبدال محتوى هذا الملف بطلبات HTTP فعلية دون أي تعديل
/// على الـ Repository أو الـ Cubit أو الشاشة.
/// ==================================================================
class HousingRequestRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 800);
  static const _placeholderUserId = 'usr_1001';
  static const _placeholderUserName = 'أحمد محمد';

  static String? _currentUserId;

  /// طلب سكن واحد على الأكثر لكل مستخدم، بمفتاح معرّف المستخدم — بدل حقل
  /// وحيد مشترك بين كل من يستخدم التطبيق على نفس الجهاز.
  static final Map<String, HousingRequestModel> _requestsByUser = {};

  Future<void> _ensureCurrentUser() async {
    if (_currentUserId != null) return;
    final resolved = await MockCurrentUser.resolve(
      placeholderId: _placeholderUserId,
      placeholderName: _placeholderUserName,
    );
    _currentUserId = resolved.id;
  }

  Future<HousingRequestModel?> fetchMyRequest() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);
    return _requestsByUser[_currentUserId];
  }

  Future<HousingRequestModel> submitRequest({
    required String requestType,
    required String roomType,
    required String preferredBuilding,
    String? groupCode,
    List<HousingDocument> documents = const [],
    String? notes,
  }) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    if (_requestsByUser.containsKey(_currentUserId)) {
      throw const HousingRequestException(
        'لديك طلب سكن مقدَّم بالفعل قيد المعالجة.',
      );
    }
    if (requestType == 'group' && (groupCode == null || groupCode.isEmpty)) {
      throw const HousingRequestException(
        'يجب الانضمام إلى غروب أو إنشاء واحد أولاً لتقديم طلب كغروب.',
      );
    }
    if (documents.isEmpty) {
      throw const HousingRequestException(
        'يرجى إرفاق المستندات الداعمة المطلوبة قبل الإرسال.',
      );
    }

    final request = HousingRequestModel(
      id: 'hrq_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
      requestType: requestType,
      roomType: roomType,
      preferredBuilding: preferredBuilding,
      status: 'pending',
      createdAt: DateTime.now(),
      groupCode: requestType == 'group' ? groupCode : null,
      documents: documents,
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    );

    _requestsByUser[_currentUserId!] = request;
    return request;
  }
}
