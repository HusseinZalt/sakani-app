import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/register_data.dart';
import '../../domain/repositories/auth_repository.dart';
import 'register_state.dart';

/// يدير حالة شاشة إنشاء الحساب عبر [AuthRepository]، دون معرفة ما إذا
/// كانت البيانات وهمية حالياً أو قادمة من API حقيقي مستقبلاً.
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._authRepository) : super(const RegisterInitial());

  final AuthRepository _authRepository;

  Future<void> register(RegisterData data) async {
    emit(const RegisterLoading());

    final result = await _authRepository.register(data);

    switch (result) {
      case ApiSuccess<void>():
        emit(RegisterOtpSent(data.email));
      case ApiFailureResult<void>(:final failure):
        emit(RegisterFailureState(failure));
    }
  }
}
