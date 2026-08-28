import '../../../../core/network/api_result.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_request.dart';

sealed class HousingRequestState {
  const HousingRequestState();
}

final class HousingRequestLoading extends HousingRequestState {
  const HousingRequestLoading();
}

/// لا توجد دورة سكن مفتوحة حالياً بالنظام — لا يُعرض نموذج التقديم إطلاقاً.
final class HousingRequestCycleClosed extends HousingRequestState {
  const HousingRequestCycleClosed();
}

/// دورة مفتوحة ولا يوجد طلب سكن مقدَّم بعد — يُعرض النموذج فارغاً.
final class HousingRequestEmpty extends HousingRequestState {
  const HousingRequestEmpty({
    required this.governorates,
    this.buildings = const [],
    this.buildingsLoadFailed = false,
  });

  final List<Governorate> governorates;

  /// لملء اختيار "المبنى السابق" بقسم "سكنت سابقاً".
  final List<Building> buildings;

  /// true فقط إذا فشل نداء الأبنية فعلياً (شبكة/خادم) — يميّز عن حالة
  /// كون القائمة فارغة شرعياً (لا مبانٍ مسجَّلة)، حتى تعرض الواجهة زر
  /// "إعادة المحاولة" بدل رسالة خطأ عامة لا فائدة منها لو كانت القائمة
  /// فارغة فعلاً وليس بسبب عطل.
  final bool buildingsLoadFailed;
}

/// جارٍ إرسال/تعديل الطلب.
final class HousingRequestSubmitting extends HousingRequestState {
  const HousingRequestSubmitting();
}

/// يوجد طلب سكن مقدَّم (قيد المراجعة/يحتاج تعديل/صدر قرار).
final class HousingRequestSubmitted extends HousingRequestState {
  const HousingRequestSubmitted(
    this.request, {
    this.governorates = const [],
    this.buildings = const [],
    this.buildingsLoadFailed = false,
  });

  final HousingRequest request;

  /// لازمة فقط لإعادة عرض نموذج التعديل عند حالة `NeedsRevision`.
  final List<Governorate> governorates;
  final List<Building> buildings;

  /// راجع توثيق [HousingRequestEmpty.buildingsLoadFailed].
  final bool buildingsLoadFailed;
}

final class HousingRequestFailure extends HousingRequestState {
  const HousingRequestFailure(this.failure);

  final ApiFailure failure;
}
