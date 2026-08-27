import '../../../../core/network/api_result.dart';
import '../../domain/entities/student_group.dart';

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
  const GroupsSuccess(this.myGroup, {this.pendingJoinCode});

  final StudentGroup? myGroup;

  /// كود آخر طلب انضمام أرسله الطالب وما زال بانتظار رد قائد الغروب —
  /// null إن لم يرسل طلباً، أو إن كان أصلاً ضمن غروب. راجع التوثيق
  /// المفصَّل بـ [PendingJoinRequestStorage] لحدود هذا التتبّع.
  final String? pendingJoinCode;
}

final class GroupsFailure extends GroupsState {
  const GroupsFailure(this.failure);

  final ApiFailure failure;
}
