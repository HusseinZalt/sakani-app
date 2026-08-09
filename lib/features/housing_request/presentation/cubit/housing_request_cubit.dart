import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../../groups/domain/entities/groups_data.dart';
import '../../../groups/domain/repositories/groups_repository.dart';
import '../../domain/entities/housing_request.dart';
import '../../domain/repositories/housing_request_repository.dart';
import 'housing_request_state.dart';

/// يدير حالة شاشة طلب السكن عبر [HousingRequestRepository]، دون معرفة ما
/// إذا كانت البيانات وهمية حالياً أو قادمة من API حقيقي مستقبلاً.
///
/// يعتمد أيضاً على [GroupsRepository] لمعرفة غروب المستخدم الحالي (إن
/// وُجد)، اللازم لتفعيل وربط خيار "طلب كغروب".
class HousingRequestCubit extends Cubit<HousingRequestState> {
  HousingRequestCubit(this._repository, this._groupsRepository)
    : super(const HousingRequestLoading());

  final HousingRequestRepository _repository;
  final GroupsRepository _groupsRepository;

  Future<void> fetchMyRequest() async {
    emit(const HousingRequestLoading());

    final result = await _repository.fetchMyRequest();

    switch (result) {
      case ApiSuccess<HousingRequest?>(:final data):
        if (data != null) {
          emit(HousingRequestSubmitted(data));
          return;
        }
        final groupsResult = await _groupsRepository.fetchGroupsData();
        final myGroup = switch (groupsResult) {
          ApiSuccess<GroupsData>(:final data) => data.myGroup,
          ApiFailureResult<GroupsData>() => null,
        };
        emit(HousingRequestEmpty(myGroup: myGroup));
      case ApiFailureResult<HousingRequest?>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  Future<void> submitRequest({
    required String requestType,
    required String roomType,
    required String preferredBuilding,
    String? groupCode,
    List<String> documentNames = const [],
    String? notes,
  }) async {
    emit(const HousingRequestSubmitting());

    final result = await _repository.submitRequest(
      requestType: requestType,
      roomType: roomType,
      preferredBuilding: preferredBuilding,
      groupCode: groupCode,
      documentNames: documentNames,
      notes: notes,
    );

    switch (result) {
      case ApiSuccess<HousingRequest>(:final data):
        emit(HousingRequestSubmitted(data));
      case ApiFailureResult<HousingRequest>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }
}
