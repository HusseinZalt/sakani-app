import '../../../../core/network/api_result.dart';
import '../../../groups/domain/entities/student_group.dart';
import '../../domain/entities/housing_request.dart';

sealed class HousingRequestState {
  const HousingRequestState();
}

final class HousingRequestLoading extends HousingRequestState {
  const HousingRequestLoading();
}

/// لا يوجد طلب سكن مقدَّم بعد — يُعرض النموذج فارغاً.
///
/// [myGroup]: غروب المستخدم الحالي إن وُجد، يُستخدم لتفعيل خيار "طلب
/// كغروب" وعرض بيانات الغروب عند اختياره.
final class HousingRequestEmpty extends HousingRequestState {
  const HousingRequestEmpty({this.myGroup});

  final StudentGroup? myGroup;
}

/// جارٍ إرسال الطلب.
final class HousingRequestSubmitting extends HousingRequestState {
  const HousingRequestSubmitting();
}

/// يوجد طلب سكن مقدَّم (قيد المراجعة/مقبول/مرفوض).
final class HousingRequestSubmitted extends HousingRequestState {
  const HousingRequestSubmitted(this.request);

  final HousingRequest request;
}

final class HousingRequestFailure extends HousingRequestState {
  const HousingRequestFailure(this.failure);

  final ApiFailure failure;
}
