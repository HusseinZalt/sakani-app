import '../../../../core/network/api_result.dart';
import '../../domain/entities/maintenance_request.dart';

/// حالات شاشة قائمة طلبات الصيانة.
///
/// استخدام sealed class يجبر واجهة المستخدم على معالجة كل الحالات
/// الممكنة (Loading/Success/Failure) عبر switch شامل دون إغفال أي حالة.
sealed class MaintenanceListState {
  const MaintenanceListState();
}

/// الحالة الابتدائية قبل أول عملية جلب.
final class MaintenanceListInitial extends MaintenanceListState {
  const MaintenanceListInitial();
}

/// جارٍ جلب طلبات الصيانة.
final class MaintenanceListLoading extends MaintenanceListState {
  const MaintenanceListLoading();
}

/// تم جلب طلبات الصيانة بنجاح.
final class MaintenanceListSuccess extends MaintenanceListState {
  const MaintenanceListSuccess(this.requests);

  final List<MaintenanceRequest> requests;
}

/// فشل جلب طلبات الصيانة مع تفاصيل الخطأ.
final class MaintenanceListFailure extends MaintenanceListState {
  const MaintenanceListFailure(this.failure);

  final ApiFailure failure;
}
