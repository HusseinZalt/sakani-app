import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/groups_data.dart';
import '../../domain/repositories/groups_repository.dart';
import 'groups_state.dart';

/// يدير حالة شاشة الغروبات عبر [GroupsRepository]، دون معرفة ما إذا كانت
/// البيانات وهمية حالياً أو قادمة من API حقيقي مستقبلاً.
///
/// عمليات الإجراءات الفردية (إنشاء، انضمام، دعوة، قبول، رفض) تُرجع
/// [ApiResult] مباشرة للشاشة لعرض رسالة مناسبة، وتُحدّث الحالة الرئيسية
/// محلياً عند النجاح دون الحاجة لإعادة الجلب الكامل.
class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this._repository) : super(const GroupsInitial());

  final GroupsRepository _repository;

  Future<void> fetchGroupsData() async {
    emit(const GroupsLoading());

    final result = await _repository.fetchGroupsData();

    switch (result) {
      case ApiSuccess<GroupsData>(:final data):
        emit(GroupsSuccess(data));
      case ApiFailureResult<GroupsData>(:final failure):
        emit(GroupsFailure(failure));
    }
  }

  Future<ApiResult<void>> createGroup() async {
    final result = await _repository.createGroup();
    if (result.isSuccess) await fetchGroupsData();
    return result.map((group) {});
  }

  Future<ApiResult<void>> joinGroupByCode(String code) async {
    final result = await _repository.joinGroupByCode(code);
    if (result.isSuccess) await fetchGroupsData();
    return result.map((group) {});
  }

  Future<ApiResult<void>> inviteMember(String identifier) {
    return _repository.inviteMember(identifier);
  }

  Future<ApiResult<void>> acceptInvite(String inviteId) async {
    final result = await _repository.acceptInvite(inviteId);
    if (result.isSuccess) await fetchGroupsData();
    return result.map((group) {});
  }

  Future<ApiResult<void>> declineInvite(String inviteId) async {
    final result = await _repository.declineInvite(inviteId);
    if (result.isSuccess) await fetchGroupsData();
    return result;
  }

  Future<ApiResult<void>> leaveGroup() async {
    final result = await _repository.leaveGroup();
    if (result.isSuccess) await fetchGroupsData();
    return result;
  }

  Future<ApiResult<void>> transferLeadership(String newLeaderId) async {
    final result = await _repository.transferLeadership(newLeaderId);
    if (result.isSuccess) await fetchGroupsData();
    return result.map((group) {});
  }
}
