import '../../../../core/network/api_result.dart';
import '../../domain/entities/groups_data.dart';
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
  Future<ApiResult<GroupsData>> fetchGroupsData() async {
    try {
      final data = await _remoteDataSource.fetchGroupsData();
      return ApiResult.success(data);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<StudentGroup>> createGroup() async {
    try {
      final group = await _remoteDataSource.createGroup();
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<StudentGroup>> joinGroupByCode(String code) async {
    try {
      final group = await _remoteDataSource.joinGroupByCode(code);
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> inviteMember(String identifier) async {
    try {
      await _remoteDataSource.inviteMember(identifier);
      return ApiResult.success(null);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<StudentGroup>> acceptInvite(String inviteId) async {
    try {
      final group = await _remoteDataSource.acceptInvite(inviteId);
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> declineInvite(String inviteId) async {
    try {
      await _remoteDataSource.declineInvite(inviteId);
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
  Future<ApiResult<StudentGroup>> transferLeadership(String newLeaderId) async {
    try {
      final group = await _remoteDataSource.transferLeadership(newLeaderId);
      return ApiResult.success(group);
    } on GroupsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
