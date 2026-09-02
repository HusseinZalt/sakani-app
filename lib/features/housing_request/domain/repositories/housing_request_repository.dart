import '../../../../core/network/api_result.dart';
import '../entities/building.dart';
import '../entities/dorm_room.dart';
import '../entities/governorate.dart';
import '../entities/housing_cycle.dart';
import '../entities/housing_document.dart';
import '../entities/housing_request.dart';

/// عقد (Interface) طبقة طلب السكن، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية.
abstract class HousingRequestRepository {
  /// دورة السكن المفتوحة حالياً، أو null إن لم توجد دورة مفتوحة بالنظام.
  Future<ApiResult<HousingCycle?>> fetchCurrentCycle();

  /// قائمة المحافظات لملء نموذج التقديم.
  Future<ApiResult<List<Governorate>>> fetchGovernorates();

  /// قائمة الأبنية لملء اختيار "المبنى السابق" بقسم "سكنت سابقاً".
  Future<ApiResult<List<Building>>> fetchBuildings();

  /// غرف مبنى واحد، لفلترتها حسب الطابق المختار وعرض أرقام غرف حقيقية.
  Future<ApiResult<List<DormRoom>>> fetchRoomsForBuilding(int buildingId);

  /// جلب طلب السكن الحالي للطالب، أو null إن لم يقدَّم طلب بعد.
  Future<ApiResult<HousingRequest?>> fetchMyRequest();

  /// تقديم طلب سكن جديد.
  Future<ApiResult<HousingRequest>> submitRequest({
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> documents,
  });

  /// تعديل طلب بحالة `NeedsRevision` — يرسل فقط المستندات المُستبدَلة.
  Future<ApiResult<HousingRequest>> updateRequest({
    required int requestId,
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> replacedDocuments,
  });

  /// حذف طلب سكن — الطالب يحذف طلبه هو فقط. يُرفض إن كان الطالب مُسكّناً
  /// فعلياً (لازم إخلاء المبنى أولاً من جهة الإدارة).
  Future<ApiResult<void>> deleteRequest(int requestId);

  /// دفع رسوم طلب سكن مقبول من رصيد محفظة الطالب (`POST
  /// /api/housing-requests/{id}/pay`) — [amount] هو الرسم المتوجّب
  /// (`HousingRequest.feeAmount`) يُرسَل كما هو للتأكيد. راجع تحفظات
  /// التوثيق بـ [HousingRequestRemoteDataSource.payForRequest]. تُرجع
  /// الرصيد الجديد إن أرجعه الخادم، أو null إن لم يُرجعه (لا يعني فشل
  /// العملية، فقط عدم توفر رصيد محدَّث لعرضه فوراً).
  Future<ApiResult<double?>> payForRequest(int requestId, {required double amount});
}
