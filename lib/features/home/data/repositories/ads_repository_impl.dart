import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/ads_repository.dart';
import '../datasources/ads_remote_data_source.dart';

class AdsRepositoryImpl implements AdsRepository {
  AdsRepositoryImpl({AdsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? AdsRemoteDataSource();

  final AdsRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<Announcement>> fetchAdById(String id) async {
    try {
      final ad = await _remoteDataSource.fetchAdById(id);
      return ApiResult.success(ad);
    } on AdsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
