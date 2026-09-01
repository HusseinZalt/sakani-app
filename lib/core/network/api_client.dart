import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../session/session_storage.dart';

/// سبب فشل آخر محاولة تجديد جلسة — يُستخدم لتمييز فشل التجديد بسبب
/// مشكلة اتصال مؤقتة (لا تعني انتهاء الجلسة فعلياً) عن فشل حقيقي
/// (رمز التجديد نفسه غير صالح/منتهٍ)، راجع توثيق `onError` بـ [ApiClient].
enum _RefreshFailureReason { network, unauthorized }

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
            } else if (_lastRefreshFailureReason == _RefreshFailureReason.network) {
              // فشل التجديد بسبب مشكلة اتصال مؤقتة (لا يوجد إنترنت مثلاً)،
              // وليس لأن الجلسة انتهت فعلياً — الخطأ الأصلي هنا 401 عادي
              // سيُترجَم لاحقاً برسالة "يرجى تسجيل الدخول مرة أخرى" رغم أن
              // رمز التجديد لا يزال صالحاً تماماً، وهو ما كان يدفع
              // المستخدم لتسجيل خروج/دخول غير ضروري كل مرة ينقطع فيها
              // اتصاله للحظة وقت انتهاء عمر رمز الدخول (كل 15 دقيقة).
              // نستبدله بخطأ اتصال حتى تظهر رسالة صحيحة تدفعه للمحاولة
              // لاحقاً بدل إعادة تسجيل الدخول.
              return handler.reject(
                DioException(
                  requestOptions: error.requestOptions,
                  type: DioExceptionType.connectionError,
                  error: error.error,
                ),
              );
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

  /// خدمة السكن — طلبات السكن، الغروبات، التخصيص.
  static const String housingBaseUrl = gatewayBaseUrl;

  /// خدمة المحفظة (`/api/wallet/...`) — **مؤكَّد من فريق الباك إند
  /// (2026-09-01):** لسا ما انربطت بالبوابة الموحّدة، وعم تُخدَّم مباشرة
  /// من نفس مضيف خدمة المصادقة القديم على Vercel (راجع [authBaseUrl]
  /// أعلاه لتاريخها). أي طلب `/api/wallet/...` عبر [gatewayBaseUrl] يرجع
  /// `404` فوراً (تأكَّد بالاختبار المباشر) لأن المسار غير مسجَّل أصلاً
  /// هناك، بينما نفس الطلب على هالمضيف يرجع استجابة حقيقية (401 بدون
  /// توكن، تماماً متل `/api/auth/login`). ⚠️ مؤقت — يُفترض حذفه والعودة
  /// لـ [gatewayBaseUrl] فور ما الباك إند يربط خدمة المحفظة بالبوابة.
  static const String walletBaseUrl = 'https://university-auth-lemon.vercel.app';

  /// للتوافق مع الاستخدام الحالي في طبقة المصادقة — نفس [auth].
  static final ApiClient instance = ApiClient._(authBaseUrl);

  static final ApiClient auth = instance;
  static final ApiClient feedback = ApiClient._(feedbackBaseUrl);
  static final ApiClient notifications = ApiClient._(notificationsBaseUrl);
  static final ApiClient housing = ApiClient._(housingBaseUrl);
  static final ApiClient ads = ApiClient._(adsBaseUrl);
  static final ApiClient wallet = ApiClient._(walletBaseUrl);

  final String baseUrl;

  late final Dio _dio;

  Dio get dio => _dio;

  /// عملية التجديد الجارية حالياً (إن وُجدت)، مشتركة بين كل نسخ [ApiClient]
  /// حتى لا تتسابق طلبات متزامنة على استهلاك نفس رمز التجديد القديم (راجع
  /// شرح [ApiClient] أعلاه).
  static Future<bool>? _refreshFuture;

  /// سبب فشل آخر محاولة تجديد (فقط ذو معنى مباشرة بعد `await
  /// _tryRefreshToken()` عائدة بـ false) — راجع [_RefreshFailureReason].
  static _RefreshFailureReason? _lastRefreshFailureReason;

  Future<bool> _tryRefreshToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await SessionStorage.loadRefreshToken();
    if (refreshToken == null) {
      _lastRefreshFailureReason = _RefreshFailureReason.unauthorized;
      return false;
    }

    try {
      // ⚠️ نفس فخ ترويسة `Accept` الموثّق أعلى هذا الصف بالضبط — هذا
      // النداء الوحيد بالتطبيق الذي يبني نسخة Dio خام بدل استخدام نسخة
      // [ApiClient] (لأن التجديد نفسه لازم يعمل بمعزل تام عن أي نسخة قد
      // تكون طلباتها الأصلية هي سبب الـ 401 أصلاً). بدون هذه الترويهة
      // الصريحة، بوابة الـ API (الآن خلف Ocelot بعد الانتقال، راجع توثيق
      // [baseUrl] بالأعلى) قد ترجع `text/plain` فيفشل التحويل لـ
      // `Map<String, dynamic>` بخطأ نوع غير مُلتقَط كـ DioException —
      // يُلتقط هنا بالـ `catch (_)` أدناه فعلاً فلا يتسبب بعطل، لكنه كان
      // يُترجَم خطأً لـ "رمز التجديد غير صالح" (تسجيل خروج كل ~15 دقيقة،
      // عمر رمز الدخول) رغم أن رمز التجديد نفسه لا يزال صالحاً تماماً.
      final response = await Dio(
        BaseOptions(
          baseUrl: authBaseUrl,
          headers: {'Accept': 'application/json'},
        ),
      ).post<dynamic>('/api/auth/refresh-token', data: {'refreshToken': refreshToken});
      final body = _asRefreshJsonMap(response.data);
      final data = body?['data'] as Map<String, dynamic>?;
      if (data == null) {
        _lastRefreshFailureReason = _RefreshFailureReason.unauthorized;
        return false;
      }

      await SessionStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          _lastRefreshFailureReason = _RefreshFailureReason.network;
        default:
          _lastRefreshFailureReason = _RefreshFailureReason.unauthorized;
      }
      return false;
    } catch (_) {
      _lastRefreshFailureReason = _RefreshFailureReason.unauthorized;
      return false;
    }
  }

  /// يطبّع جسم استجابة التجديد إلى `Map<String, dynamic>` بغض النظر عن نوع
  /// المحتوى الفعلي الذي أرجعه الخادم — نفس منطق `_asJsonMap` المكرَّر عبر
  /// مصادر البيانات الأخرى (راجع تعليق ترويسة `Accept` أعلى [_performRefresh]).
  Map<String, dynamic>? _asRefreshJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // جسم غير قابل لفك ترميزه كـ JSON إطلاقاً — يُعامَل كفشل تجديد
        // عادي أدناه (data == null) بدل رمي استثناء غير متوقَّع.
      }
    }
    return null;
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
