import 'dart:typed_data';

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
  /// [imageBytes] بايتات الصورة المرفقة إن وُجدت، وسيُستبدل عند ربط الباك
  /// إند برفع فعلي للملف والاحتفاظ برابطه بدلاً من البايتات المحلية.
  Future<ApiResult<MaintenanceRequest>> submitRequest({
    required String description,
    required String category,
    Uint8List? imageBytes,
  });

  /// إلغاء طلب صيانة قائم عبر معرّفه.
  Future<ApiResult<void>> cancelRequest(String requestId);
}
