import '../../../../core/network/api_result.dart';
import '../../domain/entities/maintenance_request.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_remote_data_source.dart';

/// التنفيذ الفعلي لعقد [MaintenanceRepository]، مسؤول فقط عن استدعاء مصدر
/// البيانات وتحويل نتيجته (أو الاستثناء الذي يرميه) إلى [ApiResult] موحّد
/// تستهلكه طبقة الـ Presentation دون الحاجة لمعرفة تفاصيل مصدر البيانات.
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl({MaintenanceRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? MaintenanceRemoteDataSource();

  final MaintenanceRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<List<MaintenanceRequest>>> fetchRequests() async {
    try {
      final requests = await _remoteDataSource.fetchRequests();
      return ApiResult.success(requests);
    } on MaintenanceException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<MaintenanceRequest>> submitRequest({
    required String description,
    required String category,
    String? imagePath,
  }) async {
    try {
      final request = await _remoteDataSource.submitRequest(
        description: description,
        category: category,
        imagePath: imagePath,
      );
      return ApiResult.success(request);
    } on MaintenanceException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> cancelRequest(String requestId) async {
    try {
      await _remoteDataSource.cancelRequest(requestId);
      return ApiResult.success(null);
    } on MaintenanceException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
