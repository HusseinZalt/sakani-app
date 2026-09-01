import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/server_message_ar.dart';
import '../models/complaint_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class ComplaintsException implements Exception {
  const ComplaintsException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الشكاوى والاقتراحات — يستدعي خدمة الآراء الحقيقية
/// (ASP.NET Core على `feedbackservice001.runasp.net`، راجع `/swagger`).
///
/// **مؤكَّد بالاختبار الفعلي (2026-08-17):** هذه الخدمة تثق بنفس الـ Access
/// Token الصادر من خدمة المصادقة. `GET /api/Feedbacks` مخصّصة للإدارة فقط
/// (كانت تُرجع 403 لحسابات الطلاب)، فتُستخدم بدلاً منها `GET
/// /api/Feedbacks/mine` المخصّصة للطالب، والمؤكَّد أنها تُعيد شكاواه هو فقط.
class ComplaintsRemoteDataSource {
  ComplaintsRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.feedback.dio;

  final Dio _dio;

  Future<List<ComplaintModel>> fetchComplaints() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/Feedbacks/mine',
        queryParameters: {'PageNumber': 1, 'PageSize': 100},
      );
      final body = _asJsonMap(response.data);
      final items = (body['items'] as List?) ?? const [];
      final complaints =
          items
              .whereType<Map<String, dynamic>>()
              .map(ComplaintModel.fromJson)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return complaints;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<ComplaintModel> fetchComplaintById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/api/Feedbacks/$id');
      return ComplaintModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<ComplaintModel> submitComplaint({
    required String type,
    required String title,
    required String description,
    bool isAnonymous = false,
    List<Uint8List> images = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'Type': ComplaintModel.typeToApi(type),
        'Title': title,
        'Description': description,
        'IsAnonymous': isAnonymous,
        if (images.isNotEmpty)
          'Images': [
            for (var i = 0; i < images.length; i++)
              MultipartFile.fromBytes(images[i], filename: 'image_$i.jpg'),
          ],
      });

      final response = await _dio.post<dynamic>(
        '/api/Feedbacks/with-images',
        data: formData,
      );
      return ComplaintModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// يطبّع جسم الاستجابة إلى `Map<String, dynamic>` بغض النظر عن نوع
  /// المحتوى الفعلي الذي أرجعه الخادم.
  ///
  /// بعض استجابات خدمة الآراء ترجع بنوع محتوى `text/plain` (راجع توثيق
  /// Swagger الخاص بها) رغم أن الجسم فعلياً JSON صالح — في هذه الحالة لا
  /// يُحوِّل Dio الاستجابة تلقائياً، فتصل هنا كسلسلة نصية (String) بدل
  /// Map جاهزة، فنفكّها يدوياً بدل أن تفشل العملية بخطأ نوع غامض غير
  /// مفهوم للمستخدم.
  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const ComplaintsException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  /// نسخة لا تُلقي استثناءً من [_asJsonMap]، تُستخدم عند استخراج رسالة خطأ
  /// من استجابة فاشلة أصلاً (لا داعي لإخفاء رسالة الخطأ الحقيقية بخطأ تحويل).
  Map<String, dynamic>? _tryAsJsonMap(dynamic data) {
    try {
      return _asJsonMap(data);
    } catch (_) {
      return null;
    }
  }

  ComplaintsException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = _tryAsJsonMap(e.response?.data);

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ComplaintsException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const ComplaintsException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        return ComplaintsException(_extractValidationMessage(responseData));
      case 401:
        return const ComplaintsException(
          'تعذّر التحقق من صلاحية الدخول لهذه الخدمة، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 403:
        // ⚠️ لوحظ فعلياً (2026-08-17) أن الخادم يرفض حسابات بدور "student"
        // برمز 403 حتى مع توكن صالح وحديث — على الأرجح تقييد صلاحيات غير
        // مقصود على هذه النقطة بالباك إند (تمنع الطلاب من استخدام ميزة
        // مُصمَّمة أصلاً لهم). يجب إبلاغ فريق الباك إند بهذا تحديداً.
        return const ComplaintsException(
          'لا تملك صلاحية الوصول لهذه الخدمة حالياً (خطأ إعداد صلاحيات من طرف الخادم)، يرجى إبلاغ فريق الدعم.',
          type: ApiErrorType.forbidden,
        );
      case 404:
        return const ComplaintsException(
          'لم يتم العثور على الشكوى المطلوبة.',
          type: ApiErrorType.notFound,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const ComplaintsException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const ComplaintsException('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
    }
  }

  /// يحاول استخراج رسالة مفهومة من شكل أخطاء تحقّق ASP.NET Core القياسي
  /// (`ValidationProblemDetails`: `{errors: {field: [رسائل]}, title}`).
  String _extractValidationMessage(Map? responseData) {
    const fallback = 'البيانات المدخلة غير صحيحة، يرجى مراجعتها.';

    // رسالة عمل صريحة من الخادم — تُترجَم للعربية بدل عرضها كما هي.
    final serverText =
        (responseData?['message'] ??
                responseData?['detail'] ??
                responseData?['error'])
            as String?;
    if (serverText != null && serverText.trim().isNotEmpty) {
      return translateServerMessageAr(serverText, fallback: fallback);
    }

    final errors = responseData?['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final messages =
          errors.values
              .whereType<List>()
              .expand((list) => list)
              .whereType<String>()
              .map((m) => translateServerMessageAr(m, fallback: fallback))
              .toSet()
              .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    final title = responseData?['title'];
    if (title is String && title.isNotEmpty) {
      return translateServerMessageAr(title, fallback: fallback);
    }
    return fallback;
  }
}
