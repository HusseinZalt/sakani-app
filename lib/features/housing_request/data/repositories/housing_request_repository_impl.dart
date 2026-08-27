import '../../../../core/network/api_result.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/dorm_room.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_cycle.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';
import '../../domain/repositories/housing_request_repository.dart';
import '../datasources/housing_request_remote_data_source.dart';

class HousingRequestRepositoryImpl implements HousingRequestRepository {
  HousingRequestRepositoryImpl({
    HousingRequestRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? HousingRequestRemoteDataSource();

  final HousingRequestRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<HousingCycle?>> fetchCurrentCycle() async {
    try {
      final cycle = await _remoteDataSource.fetchCurrentCycle();
      return ApiResult.success(cycle);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<List<Governorate>>> fetchGovernorates() async {
    try {
      final governorates = await _remoteDataSource.fetchGovernorates();
      return ApiResult.success(governorates);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<List<Building>>> fetchBuildings() async {
    try {
      final buildings = await _remoteDataSource.fetchBuildings();
      return ApiResult.success(buildings);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<List<DormRoom>>> fetchRoomsForBuilding(
    int buildingId,
  ) async {
    try {
      final rooms = await _remoteDataSource.fetchRoomsForBuilding(buildingId);
      return ApiResult.success(rooms);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<HousingRequest?>> fetchMyRequest() async {
    try {
      final request = await _remoteDataSource.fetchMyRequest();
      return ApiResult.success(request);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<HousingRequest>> submitRequest({
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> documents,
  }) async {
    try {
      final request = await _remoteDataSource.submitRequest(
        gender: gender,
        governorateId: governorateId,
        academicLevel: academicLevel,
        detailedAddress: detailedAddress,
        hasSpecialNeeds: hasSpecialNeeds,
        isPreviousResident: isPreviousResident,
        previousBuildingId: previousBuildingId,
        previousFloor: previousFloor,
        previousRoomNumber: previousRoomNumber,
        specialNotes: specialNotes,
        documents: documents,
      );
      return ApiResult.success(request);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<HousingRequest>> updateRequest({
    required int requestId,
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> replacedDocuments,
  }) async {
    try {
      final request = await _remoteDataSource.updateRequest(
        requestId: requestId,
        gender: gender,
        governorateId: governorateId,
        academicLevel: academicLevel,
        detailedAddress: detailedAddress,
        hasSpecialNeeds: hasSpecialNeeds,
        isPreviousResident: isPreviousResident,
        previousBuildingId: previousBuildingId,
        previousFloor: previousFloor,
        previousRoomNumber: previousRoomNumber,
        specialNotes: specialNotes,
        replacedDocuments: replacedDocuments,
      );
      return ApiResult.success(request);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> deleteRequest(int requestId) async {
    try {
      await _remoteDataSource.deleteRequest(requestId);
      return ApiResult.success(null);
    } on HousingRequestException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
