import '../../../../core/network/api_result.dart';
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

  static HousingRequestModel? _myRequest;

  Future<HousingRequestModel?> fetchMyRequest() async {
    await Future.delayed(_networkDelay);
    return _myRequest;
  }

  Future<HousingRequestModel> submitRequest({
    required String requestType,
    required String roomType,
    required String preferredBuilding,
    String? groupCode,
    List<String> documentNames = const [],
    String? notes,
  }) async {
    await Future.delayed(_networkDelay);

    if (_myRequest != null) {
      throw const HousingRequestException(
        'لديك طلب سكن مقدَّم بالفعل قيد المعالجة.',
      );
    }
    if (requestType == 'group' && (groupCode == null || groupCode.isEmpty)) {
      throw const HousingRequestException(
        'يجب الانضمام إلى غروب أو إنشاء واحد أولاً لتقديم طلب كغروب.',
      );
    }
    if (documentNames.isEmpty) {
      throw const HousingRequestException(
        'يرجى إرفاق المستندات الداعمة المطلوبة قبل الإرسال.',
      );
    }

    final request = HousingRequestModel(
      id: 'hrq_${DateTime.now().millisecondsSinceEpoch}',
      requestType: requestType,
      roomType: roomType,
      preferredBuilding: preferredBuilding,
      status: 'pending',
      createdAt: DateTime.now(),
      groupCode: requestType == 'group' ? groupCode : null,
      documentNames: documentNames,
      notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
    );

    _myRequest = request;
    return request;
  }
}
