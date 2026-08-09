import '../../../../core/network/api_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/register_data.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// التنفيذ الفعلي لعقد [AuthRepository]، مسؤول فقط عن استدعاء مصدر
/// البيانات وتحويل نتيجته (أو الاستثناء الذي يرميه) إلى [ApiResult] موحّد
/// تستهلكه طبقة الـ Presentation دون الحاجة لمعرفة تفاصيل مصدر البيانات.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({AuthRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource();

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return ApiResult.success(user);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> register(RegisterData data) async {
    try {
      await _remoteDataSource.register(data);
      return ApiResult.success(null);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await _remoteDataSource.verifyEmail(email: email, code: code);
      return ApiResult.success(null);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> resendVerification({required String email}) async {
    try {
      await _remoteDataSource.resendVerification(email: email);
      return ApiResult.success(null);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> forgotPassword({required String email}) async {
    try {
      await _remoteDataSource.forgotPassword(email: email);
      return ApiResult.success(null);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return ApiResult.success(null);
    } on AuthException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return ApiResult.success(null);
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
