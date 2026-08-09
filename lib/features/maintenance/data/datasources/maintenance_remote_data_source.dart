import '../../../../core/network/api_result.dart';
import '../models/maintenance_request_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب،
/// ليتم تحويله لاحقاً إلى [ApiFailure] داخل الـ Repository.
class MaintenanceException implements Exception {
  const MaintenanceException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات طلبات الخدمة.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات في
/// الذاكرة + محاكاة زمن استجابة الشبكة عبر `Future.delayed`) نظراً لعدم
/// جاهزية الباك إند بعد. عند ربط الـ REST API الحقيقي (خلف Ocelot API
/// Gateway)، يكفي استبدال محتوى هذا الملف فقط بطلبات HTTP فعلية
/// (مثال: `dio.get('/api/service-requests')`) دون أي تعديل على
/// الـ Repository أو الـ Cubits أو الشاشات، لأن جميعها تعتمد على العقد
/// المجرّد [MaintenanceRepository] فقط.
/// ==================================================================
class MaintenanceRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 900);

  /// مخزّن وهمي مشترك (static) في الذاكرة، ليبقى متاحاً ومتّسقاً عبر كل
  /// النسخ المُنشأة من هذا المصدر (كل شاشة تُنشئ نسختها الخاصة من
  /// [MaintenanceRepositoryImpl])، تماماً كما ستكون قاعدة بيانات الباك إند
  /// الحقيقية مصدراً واحداً مشتركاً لاحقاً.
  static final List<MaintenanceRequestModel> _requests = [
    MaintenanceRequestModel(
      id: 'mnt_5001',
      description: 'مشكلة في الإضاءة',
      category: 'electrical',
      status: 'inProgress',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MaintenanceRequestModel(
      id: 'mnt_5002',
      description: 'تسريب بسيط بالحمام',
      category: 'plumbing',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  Future<List<MaintenanceRequestModel>> fetchRequests() async {
    await Future.delayed(_networkDelay);
    final sorted = List<MaintenanceRequestModel>.from(_requests)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<MaintenanceRequestModel> submitRequest({
    required String description,
    required String category,
    String? imagePath,
  }) async {
    await Future.delayed(_networkDelay);

    if (description.trim().length < 10) {
      throw const MaintenanceException('يرجى كتابة وصف لا يقل عن 10 أحرف.');
    }

    final request = MaintenanceRequestModel(
      id: 'mnt_${DateTime.now().millisecondsSinceEpoch}',
      description: description.trim(),
      category: category,
      status: 'pending',
      createdAt: DateTime.now(),
      imageUrl: imagePath,
    );

    _requests.add(request);
    return request;
  }

  Future<void> cancelRequest(String requestId) async {
    await Future.delayed(_networkDelay);

    final index = _requests.indexWhere((request) => request.id == requestId);
    if (index == -1) {
      throw const MaintenanceException(
        'لم يتم العثور على الطلب المطلوب إلغاؤه.',
        type: ApiErrorType.notFound,
      );
    }

    if (_requests[index].status == 'completed') {
      throw const MaintenanceException('لا يمكن إلغاء طلب مكتمل بالفعل.');
    }

    _requests.removeAt(index);
  }
}
