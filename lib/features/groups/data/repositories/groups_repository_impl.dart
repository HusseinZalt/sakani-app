import '../../../../core/network/api_result.dart';
import '../../domain/entities/student_group.dart';
import '../../domain/repositories/groups_repository.dart';
import '../datasources/groups_remote_data_source.dart';

/// التنفيذ الفعلي لعقد [GroupsRepository]، مسؤول فقط عن استدعاء مصدر
/// البيانات وتحويل نتيجته (أو الاستثناء الذي يرميه) إلى [ApiResult] موحّد.
class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl({GroupsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? GroupsRemoteDataSource();

  final GroupsRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<StudentGroup?>> fetchMyGroup() async {
    try {
      final group = await _remoteDataSource.fetchMyGroup();
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<StudentGroup>> createGroup({String? description}) async {
    try {
      final group = await _remoteDataSource.createGroup(
        description: description,
      );
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> joinGroupByCode(String code) async {
    try {
      await _remoteDataSource.joinGroupByCode(code);
      return ApiResult.success(null);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> respondToInvitation({
    required int invitationId,
    required bool approve,
  }) async {
    try {
      await _remoteDataSource.respondToInvitation(
        invitationId: invitationId,
        approve: approve,
      );
      return ApiResult.success(null);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> leaveGroup() async {
    try {
      await _remoteDataSource.leaveGroup();
      return ApiResult.success(null);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> removeMember(String studentId) async {
    try {
      await _remoteDataSource.removeMember(studentId);
      return ApiResult.success(null);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
