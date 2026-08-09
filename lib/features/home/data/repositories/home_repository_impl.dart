import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

/// التنفيذ الفعلي لعقد [HomeRepository]، مسؤول فقط عن استدعاء مصدر
/// البيانات وتحويل نتيجته إلى [ApiResult] موحّد تستهلكه طبقة الـ
/// Presentation دون الحاجة لمعرفة تفاصيل مصدر البيانات.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({HomeRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? HomeRemoteDataSource();

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<HomeDashboard>> fetchDashboard() async {
    try {
      final dashboard = await _remoteDataSource.fetchDashboard();
      return ApiResult.success(dashboard);
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
