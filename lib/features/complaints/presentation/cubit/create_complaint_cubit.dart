import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaints_repository.dart';
import 'create_complaint_state.dart';

class CreateComplaintCubit extends Cubit<CreateComplaintState> {
  CreateComplaintCubit(this._repository) : super(const CreateComplaintIdle());

  final ComplaintsRepository _repository;

  Future<void> submit({
    required String type,
    required String title,
    required String description,
    bool isAnonymous = false,
    List<Uint8List> images = const [],
  }) async {
    emit(const CreateComplaintSubmitting());

    final result = await _repository.submitComplaint(
      type: type,
      title: title,
      description: description,
      isAnonymous: isAnonymous,
      images: images,
    );

    switch (result) {
      case ApiSuccess<Complaint>(:final data):
        emit(CreateComplaintSuccess(data));
      case ApiFailureResult<Complaint>(:final failure):
        emit(CreateComplaintFailure(failure));
    }
  }
}
