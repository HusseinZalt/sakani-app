import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_state.dart';

/// يدير حالة شاشة تسجيل الدخول عبر [AuthRepository].
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authRepository) : super(const LoginInitial());

  final AuthRepository _authRepository;

  Future<void> login({required String email, required String password}) async {
    emit(const LoginLoading());

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    switch (result) {
      case ApiSuccess<AuthUser>(:final data):
        emit(LoginSuccess(data));
      case ApiFailureResult<AuthUser>(:final failure):
        emit(LoginFailureState(failure));
    }
  }
}
