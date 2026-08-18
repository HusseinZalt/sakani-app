import '../../../../core/network/api_result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({NotificationsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? NotificationsRemoteDataSource();

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<List<AppNotification>>> fetchNotifications() async {
    try {
      final notifications = await _remoteDataSource.fetchNotifications();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ApiResult.success(notifications);
    } on NotificationsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<void>> markAsRead(String id) async {
    try {
      await _remoteDataSource.markAsRead(id);
      return ApiResult.success(null);
    } on NotificationsException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
