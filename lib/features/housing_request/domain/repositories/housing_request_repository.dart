import '../../../../core/network/api_result.dart';
import '../entities/housing_request.dart';

/// عقد (Interface) طبقة طلب السكن، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API حقيقي مستقبلاً).
abstract class HousingRequestRepository {
  /// جلب طلب السكن الحالي للطالب، أو null إن لم يقدَّم طلب بعد.
  Future<ApiResult<HousingRequest?>> fetchMyRequest();

  /// تقديم طلب سكن جديد.
  Future<ApiResult<HousingRequest>> submitRequest({
    required String requestType,
    required String roomType,
    required String preferredBuilding,
    String? groupCode,
    List<String> documentNames,
    String? notes,
  });
}
