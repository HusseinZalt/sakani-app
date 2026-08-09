import '../../../../core/network/api_result.dart';
import '../../domain/entities/housing_request.dart';
import '../../domain/repositories/housing_request_repository.dart';
import '../datasources/housing_request_remote_data_source.dart';

class HousingRequestRepositoryImpl implements HousingRequestRepository {
  HousingRequestRepositoryImpl({
    HousingRequestRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? HousingRequestRemoteDataSource();

  final HousingRequestRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<HousingRequest?>> fetchMyRequest() async {
    try {
      final request = await _remoteDataSource.fetchMyRequest();
      return ApiResult.success(request);
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<HousingRequest>> submitRequest({
    required String requestType,
    required String roomType,
    required String preferredBuilding,
    String? groupCode,
    List<String> documentNames = const [],
    String? notes,
  }) async {
    try {
      final request = await _remoteDataSource.submitRequest(
        requestType: requestType,
        roomType: roomType,
        preferredBuilding: preferredBuilding,
        groupCode: groupCode,
        documentNames: documentNames,
        notes: notes,
      );
      return ApiResult.success(request);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
