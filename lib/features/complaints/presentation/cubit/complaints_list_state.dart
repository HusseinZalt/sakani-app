import '../../../../core/network/api_result.dart';
import '../../domain/entities/complaint.dart';

sealed class ComplaintsListState {
  const ComplaintsListState();
}

final class ComplaintsListInitial extends ComplaintsListState {
  const ComplaintsListInitial();
}

final class ComplaintsListLoading extends ComplaintsListState {
  const ComplaintsListLoading();
}

final class ComplaintsListSuccess extends ComplaintsListState {
  const ComplaintsListSuccess(this.complaints);

  final List<Complaint> complaints;
}

final class ComplaintsListFailure extends ComplaintsListState {
  const ComplaintsListFailure(this.failure);

  final ApiFailure failure;
}
