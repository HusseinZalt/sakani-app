import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_cycle.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';
import '../../domain/repositories/housing_request_repository.dart';
import 'housing_request_state.dart';

/// يدير حالة شاشة طلب السكن عبر [HousingRequestRepository].
///
/// التسلسل عند التحميل: تحقّق من وجود دورة سكن مفتوحة أولاً — إن لم توجد
/// فلا معنى لعرض نموذج تقديم أصلاً (`HousingRequestCycleClosed`)، بغض
/// النظر إن كان للطالب طلب قديم أو لا.
class HousingRequestCubit extends Cubit<HousingRequestState> {
  HousingRequestCubit(this._repository) : super(const HousingRequestLoading());

  final HousingRequestRepository _repository;

  Future<void> fetchMyRequest() async {
    emit(const HousingRequestLoading());

    final cycleResult = await _repository.fetchCurrentCycle();
    final HousingCycle? cycle;
    switch (cycleResult) {
      case ApiSuccess<HousingCycle?>(:final data):
        cycle = data;
      case ApiFailureResult<HousingCycle?>(:final failure):
        emit(HousingRequestFailure(failure));
        return;
    }
    if (cycle == null || !cycle.isOpen) {
      emit(const HousingRequestCycleClosed());
      return;
    }

    final requestResult = await _repository.fetchMyRequest();
    switch (requestResult) {
      case ApiSuccess<HousingRequest?>(:final data):
        if (data != null) {
          emit(HousingRequestSubmitted(data));
          return;
        }
        final governoratesResult = await _repository.fetchGovernorates();
        final governorates = switch (governoratesResult) {
          ApiSuccess<List<Governorate>>(:final data) => data,
          ApiFailureResult<List<Governorate>>() => const <Governorate>[],
        };
        emit(HousingRequestEmpty(governorates: governorates));
      case ApiFailureResult<HousingRequest?>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  Future<void> submitRequest({
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
  }) async {
    emit(const HousingRequestSubmitting());

    final result = await _repository.submitRequest(
      gender: gender,
      governorateId: governorateId,
      academicLevel: academicLevel,
      detailedAddress: detailedAddress,
      hasSpecialNeeds: hasSpecialNeeds,
      isPreviousResident: isPreviousResident,
      previousBuildingId: previousBuildingId,
      previousFloor: previousFloor,
      previousRoomNumber: previousRoomNumber,
      specialNotes: specialNotes,
      documents: documents,
    );

    switch (result) {
      case ApiSuccess<HousingRequest>(:final data):
        emit(HousingRequestSubmitted(data));
      case ApiFailureResult<HousingRequest>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  Future<void> updateRequest({
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
  }) async {
    emit(const HousingRequestSubmitting());

    final result = await _repository.updateRequest(
      requestId: requestId,
      gender: gender,
      governorateId: governorateId,
      academicLevel: academicLevel,
      detailedAddress: detailedAddress,
      hasSpecialNeeds: hasSpecialNeeds,
      isPreviousResident: isPreviousResident,
      previousBuildingId: previousBuildingId,
      previousFloor: previousFloor,
      previousRoomNumber: previousRoomNumber,
      specialNotes: specialNotes,
      replacedDocuments: replacedDocuments,
    );

    switch (result) {
      case ApiSuccess<HousingRequest>(:final data):
        emit(HousingRequestSubmitted(data));
      case ApiFailureResult<HousingRequest>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }
}
