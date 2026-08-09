import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/maintenance_request.dart';
import '../../domain/repositories/maintenance_repository.dart';
import 'create_maintenance_state.dart';

/// يدير حالة شاشة إضافة طلب صيانة جديد: اختيار/إزالة صورة مرفقة عبر
/// image_picker، ثم إرسال الطلب عبر [MaintenanceRepository].
class CreateMaintenanceCubit extends Cubit<CreateMaintenanceState> {
  CreateMaintenanceCubit(this._repository, {ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker(),
      super(const CreateMaintenanceState());

  final MaintenanceRepository _repository;
  final ImagePicker _imagePicker;

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      emit(
        state.copyWith(
          pickedImageBytes: bytes,
          pickedImageName: pickedFile.name,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'تعذر اختيار الصورة، يرجى المحاولة مرة أخرى.',
        ),
      );
    }
  }

  void removeImage() {
    emit(state.copyWith(clearImage: true));
  }

  Future<void> submit({
    required String description,
    required String category,
  }) async {
    emit(
      state.copyWith(
        status: CreateMaintenanceStatus.submitting,
        clearError: true,
      ),
    );

    final result = await _repository.submitRequest(
      description: description,
      category: category,
      imageBytes: state.pickedImageBytes,
    );

    switch (result) {
      case ApiSuccess<MaintenanceRequest>(:final data):
        emit(
          state.copyWith(
            status: CreateMaintenanceStatus.success,
            createdRequest: data,
          ),
        );
      case ApiFailureResult<MaintenanceRequest>(:final failure):
        emit(
          state.copyWith(
            status: CreateMaintenanceStatus.failure,
            errorMessage: failure.message,
          ),
        );
    }
  }
}
