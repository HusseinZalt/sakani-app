import 'package:dio/dio.dart';

import '../session/session_storage.dart';

/// عميل HTTP موحّد لكل طلبات الباك إند الحقيقي، مبني فوق Dio.
///
/// يرفق تلقائياً رمز الدخول (Access Token) المحفوظ محلياً على كل طلب،
/// ويحاول تجديده تلقائياً عبر [SessionStorage] ونقطة `/refresh-token` عند
/// انتهاء صلاحيته (استجابة 401)، ثم يعيد إرسال الطلب الأصلي مرة واحدة.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionStorage.loadAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthEndpoint =
              path.contains('/auth/login') ||
              path.contains('/auth/register') ||
              path.contains('/auth/refresh-token');

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              try {
                final retried = await _retry(error.requestOptions);
                return handler.resolve(retried);
              } catch (_) {
                // تابع لمسار الفشل الأصلي إن فشلت إعادة المحاولة أيضاً.
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  static const String baseUrl = 'https://university-auth-lemon.vercel.app';

  late final Dio _dio;

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await SessionStorage.loadRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(baseUrl: baseUrl),
      ).post<Map<String, dynamic>>(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      await SessionStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await SessionStorage.loadAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
