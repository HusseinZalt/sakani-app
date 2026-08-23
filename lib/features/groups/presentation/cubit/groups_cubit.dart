import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/student_group.dart';
import '../../domain/repositories/groups_repository.dart';
import 'groups_state.dart';

/// يدير حالة شاشة الغروبات عبر [GroupsRepository].
class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this._repository) : super(const GroupsInitial());

  final GroupsRepository _repository;

  Future<void> fetchMyGroup() async {
    emit(const GroupsLoading());

    final result = await _repository.fetchMyGroup();

    switch (result) {
      case ApiSuccess<StudentGroup?>(:final data):
        emit(GroupsSuccess(data));
      case ApiFailureResult<StudentGroup?>(:final failure):
        emit(GroupsFailure(failure));
    }
  }

  Future<ApiResult<void>> createGroup({String? description}) async {
    final result = await _repository.createGroup(description: description);
    if (result.isSuccess) await fetchMyGroup();
    return result.map((group) {});
  }

  Future<ApiResult<void>> joinGroupByCode(String code) async {
    final result = await _repository.joinGroupByCode(code);
    return result;
  }

  Future<ApiResult<void>> respondToInvitation({
    required int invitationId,
    required bool approve,
  }) async {
    final result = await _repository.respondToInvitation(
      invitationId: invitationId,
      approve: approve,
    );
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }

  Future<ApiResult<void>> leaveGroup() async {
    final result = await _repository.leaveGroup();
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }
}
