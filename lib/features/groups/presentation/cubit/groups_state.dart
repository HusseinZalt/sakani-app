import '../../../../core/network/api_result.dart';
import '../../domain/entities/groups_data.dart';

sealed class GroupsState {
  const GroupsState();
}

final class GroupsInitial extends GroupsState {
  const GroupsInitial();
}

final class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

final class GroupsSuccess extends GroupsState {
  const GroupsSuccess(this.data);

  final GroupsData data;
}

final class GroupsFailure extends GroupsState {
  const GroupsFailure(this.failure);

  final ApiFailure failure;
}
