import '../../../../core/network/api_result.dart';
import '../entities/complaint.dart';

/// عقد (Interface) طبقة الشكاوى والاقتراحات، تعتمد عليه طبقة الـ
/// Presentation دون معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API
/// حقيقي مستقبلاً).
abstract class ComplaintsRepository {
  /// جلب جميع شكاوى/اقتراحات المستخدم الحالي.
  Future<ApiResult<List<Complaint>>> fetchComplaints();

  /// تقديم شكوى أو اقتراح جديد.
  Future<ApiResult<Complaint>> submitComplaint({
    required String type,
    required String title,
    required String description,
  });
}
