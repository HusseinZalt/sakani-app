import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/session/session_storage.dart';
import '../../domain/entities/home_dashboard.dart';
import '../models/home_dashboard_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class AdsException implements Exception {
  const AdsException(this.message, {this.type = ApiErrorType.badRequest});

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الإعلانات — يستدعي خدمة الإعلانات الحقيقية (ASP.NET Core
/// على `advertisingservice001.runasp.net`، راجع `/swagger`).
class AdsRemoteDataSource {
  AdsRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.ads.dio;

  final Dio _dio;

  /// نوع "Banner" (`AdType` = 1) — مؤكَّد عبر `GET /api/ad-types` الفعلية
  /// (`[{"id":1,"name":"Banner"},{"id":2,"name":"Notification"}]`).
  static const _bannerAdType = 1;

  /// قيم `TargetGender` — مؤكَّدة عبر `GET /api/target-genders` الفعلية
  /// (`[{"id":1,"name":"Male"},{"id":2,"name":"Female"},{"id":3,"name":"Both"}]`).
  static const _targetGenderMale = 1;
  static const _targetGenderFemale = 2;

  /// يجلب الإعلانات النشطة حالياً (`GET /api/ads/active`) لعرضها بالشريط
  /// الدوّار أعلى الرئيسية. يُبقي فقط إعلانات نوع "Banner" (المصحوبة
  /// بصورة) — إعلانات نوع "Notification" (نصية بلا صورة) مكانها الطبيعي
  /// صندوق الإشعارات وليس شريط الرئيسية المرئي.
  ///
  /// تُفلتَر حسب جنس المستخدم الحالي إن كان معروفاً محلياً (`gender` من
  /// جلسة المستخدم). غير مفلترة حسب الكلية/المحافظة بعد — لا توجد نقطة
  /// نهاية بخدمة الإعلانات لتحويل اسم الكلية/المحافظة النصي المخزَّن
  /// بحساب المستخدم إلى المعرّف الرقمي (`collegeId`/`governorateId`)
  /// الذي تتوقعه.
  Future<List<AnnouncementModel>> fetchActiveAds() async {
    try {
      final user = await SessionStorage.loadUser();
      final targetGender = switch (user?.gender) {
        'male' => _targetGenderMale,
        'female' => _targetGenderFemale,
        _ => null,
      };

      final response = await _dio.get<dynamic>(
        '/api/ads/active',
        queryParameters: {
          if (targetGender != null) 'targetGender': targetGender,
        },
      );
      final items = _asJsonList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .where((json) => json['type'] == _bannerAdType)
          .map(AnnouncementModel.fromAdJson)
          .toList();
    } on DioException {
      // فشل جلب الإعلانات لا يجب أن يمنع عرض باقي الرئيسية — يكفي إخفاء
      // الشريط الدوّار (الشاشة أصلاً بتخفيه لو القائمة فاضية).
      return const [];
    }
  }

  /// يجلب إعلاناً واحداً بمعرّفه (`GET /api/ads/{id}`) — تُستخدم لشاشة
  /// تفاصيل الإعلان عند الوصول عبر إشعار (لا يحمل سوى المعرّف)، بعكس
  /// الوصول من شريط الرئيسية حيث الإعلان الكامل متوفر أصلاً بالذاكرة.
  Future<Announcement> fetchAdById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/api/ads/$id');
      final json = _asJsonMap(response.data);
      return AnnouncementModel.fromAdJson(json);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const AdsException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  /// يطبّع جسم الاستجابة إلى `List<dynamic>` بغض النظر عن نوع المحتوى
  /// الفعلي الذي أرجعه الخادم (راجع نفس المنطق بخدمتَي الآراء والإشعارات).
  List<dynamic> _asJsonList(dynamic data) {
    if (data is List) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  AdsException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AdsException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const AdsException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 401:
        return const AdsException(
          'تعذّر التحقق من صلاحية الدخول لهذه الخدمة، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 404:
        return const AdsException(
          'لم يتم العثور على هذا الإعلان، قد يكون أُزيل.',
          type: ApiErrorType.notFound,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const AdsException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const AdsException('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
    }
  }
}
