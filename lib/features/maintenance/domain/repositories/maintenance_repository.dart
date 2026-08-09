import '../../../../core/network/api_result.dart';
import '../entities/maintenance_request.dart';

/// عقد (Interface) طبقة طلبات الصيانة، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر REST API حقيقي خلف
/// Ocelot API Gateway مستقبلاً).
abstract class MaintenanceRepository {
  /// جلب جميع طلبات الصيانة الخاصة بالمستخدم الحالي.
  Future<ApiResult<List<MaintenanceRequest>>> fetchRequests();

  /// إرسال طلب خدمة جديد.
  ///
  /// [imagePath] مرجع محلي (اسم/مسار الملف) للصورة المرفقة إن وُجدت، وسيُستبدل
  /// عند ربط الباك إند برابط الصورة الفعلي بعد رفعها.
  Future<ApiResult<MaintenanceRequest>> submitRequest({
    required String description,
    required String category,
    String? imagePath,
  });

  /// إلغاء طلب صيانة قائم عبر معرّفه.
  Future<ApiResult<void>> cancelRequest(String requestId);
}
