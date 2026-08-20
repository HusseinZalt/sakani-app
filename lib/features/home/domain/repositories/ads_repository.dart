import '../../../../core/network/api_result.dart';
import '../entities/home_dashboard.dart';

/// عقد (Interface) طبقة الإعلانات، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية.
abstract class AdsRepository {
  /// جلب إعلان واحد بمعرّفه — لشاشة تفاصيل الإعلان عند الوصول عبر إشعار.
  Future<ApiResult<Announcement>> fetchAdById(String id);
}
