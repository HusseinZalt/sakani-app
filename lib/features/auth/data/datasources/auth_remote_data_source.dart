import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/session/session_storage.dart';
import '../../domain/entities/register_data.dart';
import '../models/auth_user_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب،
/// ليتم تحويله لاحقاً إلى [ApiFailure] داخل الـ Repository.
class AuthException implements Exception {
  const AuthException(this.message, {this.type = ApiErrorType.badRequest});

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات المصادقة — يستدعي خدمة المصادقة الحقيقية (Node/Express على
/// Vercel، راجع `/api-docs` على الخدمة للاطلاع على التوثيق الكامل).
class AuthRemoteDataSource {
  AuthRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  Future<AuthUserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data!['data'] as Map<String, dynamic>;
      await SessionStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return AuthUserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> register(RegisterData data) async {
    try {
      final formData = FormData.fromMap({
        'firstName': data.firstName,
        'secondName': data.secondName,
        'email': data.email.trim(),
        'password': data.password,
        'phoneNumber': data.phoneNumber,
        'gender': data.gender,
        'university': data.universityIndex,
        'nationalId': data.nationalId,
        'studyYear': data.studyYear,
        if (data.studentNumber != null && data.studentNumber!.isNotEmpty)
          'studentNumber': data.studentNumber,
        if (data.nationality != null && data.nationality!.isNotEmpty)
          'nationality': data.nationality,
        if (data.residence != null && data.residence!.isNotEmpty)
          'residence': data.residence,
        'personalPhoto': MultipartFile.fromBytes(
          data.personalPhoto,
          filename: 'personal_photo.jpg',
        ),
        'idFrontPhoto': MultipartFile.fromBytes(
          data.idFrontPhoto,
          filename: 'id_front.jpg',
        ),
        'idBackPhoto': MultipartFile.fromBytes(
          data.idBackPhoto,
          filename: 'id_back.jpg',
        ),
      });

      await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: formData,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/verify-email',
        data: {'email': email.trim(), 'code': code},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> resendVerification({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/resend-verification',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/reset-password',
        data: {'email': email.trim(), 'code': code, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await SessionStorage.loadRefreshToken();
    if (refreshToken == null) return;

    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } on DioException {
      // تسجيل الخروج محلياً يجب أن ينجح دائماً حتى لو فشل إبطال الرمز على
      // الخادم (مثال: لا يوجد اتصال بالإنترنت وقت الخروج).
    }
  }

  /// يترجم رسائل الخطأ الإنجليزية القادمة من الخادم إلى نص عربي واضح.
  /// الخادم لا يوفّر رسائل مُعرَّبة، فبدون هذه الترجمة يظهر نص إنجليزي خام
  /// (مثل "Invalid code" أو "Validation failed") داخل تطبيق عربي بالكامل.
  String? _translateServerMessage(String? raw, List<dynamic>? errors) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();

    if (lower.contains('invalid code') || lower.contains('code expired')) {
      return 'الرمز الذي أدخلته غير صحيح أو منتهي الصلاحية.';
    }
    if (lower.contains('email already verified')) {
      return 'هذا البريد الإلكتروني مفعّل بالفعل.';
    }
    if (lower.contains('user not found') ||
        lower.contains('account not found')) {
      return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.';
    }
    if (lower == 'validation failed') {
      final codeError = errors?.firstWhere(
        (err) => err is String && err.toLowerCase().startsWith('code:'),
        orElse: () => null,
      );
      if (codeError != null) {
        return 'يرجى إدخال رمز تحقق صحيح.';
      }
      if (errors != null && errors.isNotEmpty) {
        return errors.whereType<String>().join('\n');
      }
      return 'البيانات المدخلة غير صحيحة.';
    }
    return raw;
  }

  AuthException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData =
        e.response?.data is Map ? e.response!.data as Map : null;
    final serverMessage = _translateServerMessage(
      responseData?['message'] as String?,
      responseData?['errors'] as List<dynamic>?,
    );

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AuthException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const AuthException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        return AuthException(serverMessage ?? 'البيانات المدخلة غير صحيحة.');
      case 401:
        return AuthException(
          serverMessage ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          type: ApiErrorType.unauthorized,
        );
      case 403:
        final lowerMessage = serverMessage?.toLowerCase() ?? '';
        final isBanned =
            lowerMessage.contains('ban') || lowerMessage.contains('حظر');
        return AuthException(
          serverMessage ??
              (isBanned
                  ? 'تم حظر هذا الحساب من قبل الإدارة.'
                  : 'هذا الحساب غير مفعّل بعد. يرجى تأكيد رمز التفعيل أولاً.'),
          type:
              isBanned
                  ? ApiErrorType.accountBanned
                  : ApiErrorType.unverifiedAccount,
        );
      case 404:
        return AuthException(
          serverMessage ?? 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.',
          type: ApiErrorType.notFound,
        );
      case 409:
        return AuthException(
          serverMessage ?? 'يوجد حساب مسجّل بالفعل بهذا البريد الإلكتروني.',
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const AuthException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return AuthException(
          serverMessage ?? 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
        );
    }
  }
}
