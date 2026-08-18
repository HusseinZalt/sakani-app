import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/app_notification_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class NotificationsException implements Exception {
  const NotificationsException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الإشعارات — يستدعي خدمة الإشعارات الحقيقية (ASP.NET Core
/// على `notificationservice001.runasp.net`، راجع `/swagger`).
///
/// **مؤكَّد بالاختبار الفعلي (2026-08-18):** `GET /api/Notifications` (بدون
/// `/mine`) مقصورة على الإدارة (403 لحساب طالب)، تماماً كما كان الحال مع
/// خدمة الآراء — لذلك تُستخدم `GET /api/Notifications/mine` هنا حصراً.
class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.notifications.dio;

  final Dio _dio;

  Future<List<AppNotificationModel>> fetchNotifications() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/Notifications/mine',
        queryParameters: {'PageNumber': 1, 'PageSize': 100},
      );
      final body = _asJsonMap(response.data);
      final items = (body['items'] as List?) ?? const [];
      return items
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      // لازم جسم صريح (ولو فارغ) — بدونه يرفض الخادم الطلب بـ 411 Length
      // Required (مؤكَّد بالاختبار الفعلي)، لأن هذه نقطة POST بلا حمولة
      // منطقية لكن الخادم لا يزال يتوقّع ترويسة Content-Length صريحة.
      await _dio.post<dynamic>('/api/Notifications/$id/read', data: {});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// يسجّل رمز الجهاز (FCM Token) الحالي لدى خدمة الإشعارات، حتى تعرف لأي
  /// جهاز ترسل الإشعارات الفورية لهذا المستخدم.
  Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await _dio.post<dynamic>(
        '/api/device-tokens',
        data: {'fcmToken': fcmToken, 'platform': 'android'},
      );
    } on DioException catch (_) {
      // تسجيل رمز الجهاز أفضل الجهد — فشله لا يجب أن يعطّل تسجيل
      // الدخول/التطبيق (قد لا تتوفر خدمة الإشعارات مؤقتاً مثلاً).
    }
  }

  /// يلغي تسجيل رمز الجهاز الحالي (عند تسجيل الخروج)، حتى لا يستمر الخادم
  /// بمحاولة إرسال إشعارات لجهاز خرج صاحبه من حسابه.
  Future<void> unregisterDeviceToken(String fcmToken) async {
    try {
      await _dio.delete<dynamic>(
        '/api/device-tokens',
        queryParameters: {'fcmToken': fcmToken},
      );
    } on DioException catch (_) {
      // أفضل الجهد أيضاً — لا يجب أن يمنع تسجيل الخروج المحلي.
    }
  }

  /// يطبّع جسم الاستجابة إلى `Map<String, dynamic>` بغض النظر عن نوع
  /// المحتوى الفعلي الذي أرجعه الخادم (راجع نفس المنطق في خدمة الآراء).
  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const NotificationsException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  NotificationsException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NotificationsException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const NotificationsException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 401:
        return const NotificationsException(
          'تعذّر التحقق من صلاحية الدخول لهذه الخدمة، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 403:
        return const NotificationsException(
          'لا تملك صلاحية الوصول لهذه الخدمة حالياً.',
          type: ApiErrorType.forbidden,
        );
      case 404:
        return const NotificationsException(
          'لم يتم العثور على الإشعار المطلوب.',
          type: ApiErrorType.notFound,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const NotificationsException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const NotificationsException(
          'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
        );
    }
  }
}
