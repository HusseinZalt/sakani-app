import '../../../../core/network/api_result.dart';
import '../../domain/entities/complaint.dart';

sealed class CreateComplaintState {
  const CreateComplaintState();
}

final class CreateComplaintIdle extends CreateComplaintState {
  const CreateComplaintIdle();
}

final class CreateComplaintSubmitting extends CreateComplaintState {
  const CreateComplaintSubmitting();
}

final class CreateComplaintSuccess extends CreateComplaintState {
  const CreateComplaintSuccess(this.complaint);

  final Complaint complaint;
}

final class CreateComplaintFailure extends CreateComplaintState {
  const CreateComplaintFailure(this.failure);

  final ApiFailure failure;
}
