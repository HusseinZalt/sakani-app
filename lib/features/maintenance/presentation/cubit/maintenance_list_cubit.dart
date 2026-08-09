import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/maintenance_request.dart';
import '../../domain/repositories/maintenance_repository.dart';
import 'maintenance_list_state.dart';

/// يدير حالة شاشة قائمة طلبات الصيانة عبر [MaintenanceRepository]، دون
/// معرفة ما إذا كانت البيانات وهمية حالياً أو قادمة من API حقيقي مستقبلاً.
class MaintenanceListCubit extends Cubit<MaintenanceListState> {
  MaintenanceListCubit(this._repository)
    : super(const MaintenanceListInitial());

  final MaintenanceRepository _repository;

  Future<void> fetchRequests() async {
    emit(const MaintenanceListLoading());

    final result = await _repository.fetchRequests();

    switch (result) {
      case ApiSuccess<List<MaintenanceRequest>>(:final data):
        emit(MaintenanceListSuccess(data));
      case ApiFailureResult<List<MaintenanceRequest>>(:final failure):
        emit(MaintenanceListFailure(failure));
    }
  }

  /// إلغاء طلب صيانة واحد. تُرجع [ApiResult] للسماح للشاشة بعرض رسالة
  /// تنبيهية مناسبة (نجاح/فشل) دون التأثير على بقية القائمة المعروضة.
  Future<ApiResult<void>> cancelRequest(String requestId) async {
    final result = await _repository.cancelRequest(requestId);

    if (result case ApiSuccess<void>()) {
      final current = state;
      if (current is MaintenanceListSuccess) {
        emit(
          MaintenanceListSuccess(
            current.requests
                .where((request) => request.id != requestId)
                .toList(),
          ),
        );
      }
    }

    return result;
  }
}
