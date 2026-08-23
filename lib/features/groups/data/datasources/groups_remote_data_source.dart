import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/group_models.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class GroupsException implements Exception {
  const GroupsException(this.message, {this.type = ApiErrorType.badRequest});

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الغروبات — يستدعي خدمة السكن الحقيقية (ASP.NET Core على
/// `housingservice001.runasp.net`، راجع `HousingService_Guide.md`).
class GroupsRemoteDataSource {
  GroupsRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.housing.dio;

  final Dio _dio;

  /// غروب المستخدم الحالي، أو null إن لم يكن ضمن أي غروب (404).
  Future<StudentGroupModel?> fetchMyGroup() async {
    try {
      final response = await _dio.get<dynamic>('/api/housing-groups/mine');
      return StudentGroupModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapDioException(e);
    }
  }

  Future<StudentGroupModel> createGroup({String? description}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/housing-groups',
        data: {if (description != null) 'description': description},
      );
      return StudentGroupModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> joinGroupByCode(String code) async {
    try {
      await _dio.post<dynamic>(
        '/api/housing-groups/join',
        data: {'code': code},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> respondToInvitation({
    required int invitationId,
    required bool approve,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/housing-groups/invitations/$invitationId/respond',
        data: {'approve': approve},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> leaveGroup() async {
    try {
      await _dio.post<dynamic>('/api/housing-groups/mine/leave', data: {});
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
    throw const GroupsException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  Map<String, dynamic>? _tryAsJsonMap(dynamic data) {
    try {
      return _asJsonMap(data);
    } catch (_) {
      return null;
    }
  }

  static const _fieldLabels = <String, String>{
    'Code': 'كود الغروب',
    'Description': 'الوصف',
    'Approve': 'الموافقة',
  };

  /// نفس منطق استخراج رسالة 400 المؤكَّد بالاختبار الفعلي لخدمة طلب
  /// السكن (`ValidationProblemDetails` أو نص خام) — راجع
  /// `housing_request_remote_data_source.dart` لتفاصيل الحالتين.
  String _extract400Message(dynamic rawData) {
    final body = _tryAsJsonMap(rawData);

    if (body != null && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      final messages = <String>[];
      errors.forEach((field, value) {
        final label = _fieldLabels[field.toString()] ?? field.toString();
        messages.add(label);
      });
      if (messages.isNotEmpty) return messages.join('، ');
    }

    final title = body?['title'] as String?;
    if (title != null &&
        title.isNotEmpty &&
        title != 'One or more validation errors occurred.') {
      return title;
    }

    if (rawData is String && rawData.trim().isNotEmpty) {
      return rawData.trim();
    }

    return 'تعذّر تنفيذ العملية، يرجى مراجعة البيانات والمحاولة مرة أخرى.';
  }

  GroupsException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const GroupsException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const GroupsException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        return GroupsException(_extract400Message(e.response?.data));
      case 401:
        return const GroupsException(
          'تعذّر التحقق من صلاحية الدخول لهذه الخدمة، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 403:
        return const GroupsException(
          'لا تملك صلاحية الوصول لهذه الخدمة حالياً.',
          type: ApiErrorType.forbidden,
        );
      case 404:
        return const GroupsException(
          'لم يتم العثور على المطلوب — تحقق من الكود.',
          type: ApiErrorType.notFound,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const GroupsException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const GroupsException('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.');
    }
  }
}
