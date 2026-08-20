import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../session/session_storage.dart';

/// عميل HTTP موحّد لطلبات أي من خدمات الباك إند الحقيقية (Microservices)،
/// مبني فوق Dio.
///
/// يرفق تلقائياً رمز الدخول (Access Token) المحفوظ محلياً على كل طلب،
/// ويحاول تجديده تلقائياً عبر [SessionStorage] ونقطة `/refresh-token` من
/// خدمة المصادقة تحديداً (بغض النظر عن أي خدمة فشل طلبها بـ 401 — التجديد
/// دائماً من نفس مصدر الجلسة الموحّد)، ثم يعيد إرسال الطلب الأصلي مرة واحدة.
///
/// **مؤكَّد بالاختبار الفعلي (2026-08-17):** توكن الدخول (Access Token)
/// عمره 15 دقيقة فقط بتصميم متعمَّد من الباك إند (قصير عمداً لأسباب أمنية)،
/// وخدمة الآراء تثق فعلاً بنفس التوكن الصادر من خدمة المصادقة. كما تأكَّد
/// أن الخادم **يُبطل رمز التجديد (Refresh Token) القديم فور استخدامه أول
/// مرة** (rotation) ويُصدر رمزاً جديداً بدله. لهذا السبب بالتحديد يُجمَّع كل
/// طلبات التجديد المتزامنة بعملية واحدة فقط عبر [_refreshFuture] الثابتة
/// (static) المشتركة بين كل نسخ [ApiClient] — وإلا فأي طلبين يفشلان بـ 401
/// بنفس اللحظة تقريباً (شائع جداً عند تحميل شاشة تطلق أكثر من نداء API معاً)
/// سيحاول كل منهما التجديد بنفس رمز التجديد القديم، وينجح أولهما فقط بينما
/// يفشل الثاني برمز مُبطَل فعلاً رغم وجود جلسة صالحة تماماً — وهو ما كان
/// يظهر للمستخدم كطلب متكرر لتسجيل الدخول من جديد كل ربع ساعة تقريباً.
class ApiClient {
  ApiClient._(this.baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        // Dio يرسل `Accept: */*` افتراضياً. بعض خدمات ASP.NET Core (مثل
        // خدمة الآراء) تتفاوض على نوع محتوى الاستجابة بناءً على هذا الترويسة
        // فترجع `text/plain` بدل `application/json` عند غيابه الصريح (راجع
        // قائمة أنواع المحتوى المُعلَنة لاستجابة 200 بتوثيق Swagger الخاص
        // بها)، فيفشل Dio بتحويل الاستجابة لـ Map<String, dynamic> بخطأ نوع
        // (type error) لا يُلتقط كـ DioException، فيظهر للمستخدم كرسالة
        // "خطأ غير متوقع" عامة بدل رسالة واضحة فعلياً.
        headers: {'Accept': 'application/json'},
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

    if (kDebugMode) {
      // تشخيص فقط: يطبع كل طلب/استجابة كاملة (بما فيها الجسم) للـ console
      // أثناء التطوير حصراً — لا يعمل إطلاقاً في نسخة الإصدار (release).
      // مُضاف بعد اعتراض إرفاق التوكن عمداً، حتى يعرض الترويسات الفعلية
      // المُرسَلة فعلياً (تسلسل onRequest بين الاعتراضات حسب ترتيب
      // إضافتها)، لا الحالة الوسيطة قبل إرفاق Authorization.
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  /// نقطة الدخول الموحّدة (API Gateway، Ocelot) لكل خدمات الباك إند — راجع
  /// `Gateway_Guide.md`. كل الخدمات (المصادقة، الآراء، الإعلانات،
  /// الإشعارات) بقيت خلفه الآن، بمسارات ثابتة بغض النظر عن أي خدمة
  /// تخدمها فعلياً خلف الكواليس؛ لم تعد هناك حاجة لعناوين مباشرة منفصلة
  /// لكل خدمة.
  static const String gatewayBaseUrl = 'http://gateway001.runasp.net';

  /// خدمة المصادقة — كانت سابقاً مستضافة خارج البوابة (Vercel مباشرة)،
  /// وأصبحت الآن مربوطة بالبوابة أيضاً بنفس المسارات (`/api/auth/...`،
  /// `/api/admin/...`).
  static const String authBaseUrl = gatewayBaseUrl;

  /// خدمة الآراء والشكاوى/الاقتراحات.
  static const String feedbackBaseUrl = gatewayBaseUrl;

  /// خدمة الإشعارات — صندوق الوارد الشخصي. ⚠️ لم يعد لهذه الخدمة نقطة
  /// تسجيل رمز جهاز منفصلة (`/api/device-tokens` أُزيلت نهائياً)؛ تسجيل
  /// رمز FCM يتم الآن حصراً ضمن جسم طلب تسجيل الدخول/التسجيل بخدمة
  /// المصادقة نفسها (مطبَّق أصلاً بـ `auth_remote_data_source.dart`).
  static const String notificationsBaseUrl = gatewayBaseUrl;

  /// خدمة الإعلانات — الإعلانات الإدارية المعروضة بالرئيسية.
  static const String adsBaseUrl = gatewayBaseUrl;

  /// للتوافق مع الاستخدام الحالي في طبقة المصادقة — نفس [auth].
  static final ApiClient instance = ApiClient._(authBaseUrl);

  static final ApiClient auth = instance;
  static final ApiClient feedback = ApiClient._(feedbackBaseUrl);
  static final ApiClient notifications = ApiClient._(notificationsBaseUrl);
  static final ApiClient ads = ApiClient._(adsBaseUrl);

  final String baseUrl;

  late final Dio _dio;

  Dio get dio => _dio;

  /// عملية التجديد الجارية حالياً (إن وُجدت)، مشتركة بين كل نسخ [ApiClient]
  /// حتى لا تتسابق طلبات متزامنة على استهلاك نفس رمز التجديد القديم (راجع
  /// شرح [ApiClient] أعلاه).
  static Future<bool>? _refreshFuture;

  Future<bool> _tryRefreshToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await SessionStorage.loadRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await Dio(
        BaseOptions(baseUrl: authBaseUrl),
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
