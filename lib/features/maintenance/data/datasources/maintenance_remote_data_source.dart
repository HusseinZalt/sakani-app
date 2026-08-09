import 'dart:typed_data';

import '../../../../core/network/api_result.dart';
import '../../../../core/session/mock_current_user.dart';
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
  static const _placeholderUserId = 'usr_1001';
  static const _placeholderUserName = 'أحمد محمد';

  static String? _currentUserId;
  static bool _seedPatched = false;

  /// مخزّن وهمي مشترك (static) في الذاكرة، ليبقى متاحاً ومتّسقاً عبر كل
  /// النسخ المُنشأة من هذا المصدر (كل شاشة تُنشئ نسختها الخاصة من
  /// [MaintenanceRepositoryImpl])، تماماً كما ستكون قاعدة بيانات الباك إند
  /// الحقيقية مصدراً واحداً مشتركاً لاحقاً.
  static final List<MaintenanceRequestModel> _requests = [
    MaintenanceRequestModel(
      id: 'mnt_5001',
      userId: _placeholderUserId,
      description: 'مشكلة في الإضاءة',
      category: 'electrical',
      status: 'inProgress',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MaintenanceRequestModel(
      id: 'mnt_5002',
      userId: _placeholderUserId,
      description: 'تسريب بسيط بالحمام',
      category: 'plumbing',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  /// يحمّل هوية المستخدم الحقيقي الحالي (مرة واحدة)، ويستبدل بها بذور
  /// البيانات الوهمية المُعلَّمة بالمعرّف البديل.
  Future<void> _ensureCurrentUser() async {
    if (_currentUserId != null) return;

    final resolved = await MockCurrentUser.resolve(
      placeholderId: _placeholderUserId,
      placeholderName: _placeholderUserName,
    );
    _currentUserId = resolved.id;

    if (_seedPatched || resolved.id == _placeholderUserId) return;
    _seedPatched = true;
    for (var i = 0; i < _requests.length; i++) {
      if (_requests[i].userId != _placeholderUserId) continue;
      _requests[i] = MaintenanceRequestModel(
        id: _requests[i].id,
        userId: resolved.id,
        description: _requests[i].description,
        category: _requests[i].category,
        status: _requests[i].status,
        createdAt: _requests[i].createdAt,
        imageUrl: _requests[i].imageUrl,
        imageBytes: _requests[i].imageBytes,
      );
    }
  }

  Future<List<MaintenanceRequestModel>> fetchRequests() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);
    final mine =
        _requests.where((r) => r.userId == _currentUserId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  Future<MaintenanceRequestModel> submitRequest({
    required String description,
    required String category,
    Uint8List? imageBytes,
  }) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    if (description.trim().length < 10) {
      throw const MaintenanceException('يرجى كتابة وصف لا يقل عن 10 أحرف.');
    }

    final request = MaintenanceRequestModel(
      id: 'mnt_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentUserId!,
      description: description.trim(),
      category: category,
      status: 'pending',
      createdAt: DateTime.now(),
      imageBytes: imageBytes,
    );

    _requests.add(request);
    return request;
  }

  Future<void> cancelRequest(String requestId) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final index = _requests.indexWhere(
      (request) => request.id == requestId && request.userId == _currentUserId,
    );
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
