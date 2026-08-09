/// أنواع أخطاء الشبكة/الـ API الموحّدة، تُستخدم لتصنيف سبب الفشل
/// بشكل يسهل التعامل معه في واجهة المستخدم (رسائل، أيقونات، إعادة محاولة...).
enum ApiErrorType {
  /// لا يوجد اتصال بالإنترنت.
  network,

  /// انتهت مهلة الاتصال بالخادم.
  timeout,

  /// خطأ من طرف الخادم (أكواد 5xx).
  server,

  /// بيانات الطلب غير صحيحة (أكواد 4xx بشكل عام).
  badRequest,

  /// المستخدم غير مصرح له (401).
  unauthorized,

  /// الحساب موجود لكنه لم يُفعَّل بعد عبر رمز الـ OTP.
  unverifiedAccount,

  /// الحساب محظور من قبل الإدارة.
  accountBanned,

  /// المستخدم لا يملك صلاحية الوصول (403).
  forbidden,

  /// المورد المطلوب غير موجود (404).
  notFound,

  /// فشل في تحويل/قراءة البيانات المستلمة (JSON غير متوقع مثلاً).
  parsing,

  /// إلغاء الطلب من قبل المستخدم أو النظام.
  cancelled,

  /// خطأ غير متوقع/غير مصنّف.
  unknown,
}

/// كائن الفشل الموحّد الذي يحمل تفاصيل الخطأ القادم من طبقة البيانات
/// (سواء من API حقيقي مستقبلاً أو من البيانات الوهمية حالياً).
class ApiFailure {
  const ApiFailure({
    required this.message,
    this.type = ApiErrorType.unknown,
    this.statusCode,
    this.errors,
    this.stackTrace,
  });

  /// رسالة قابلة للعرض مباشرة للمستخدم (يفضل أن تكون بالعربية).
  final String message;

  /// تصنيف نوع الخطأ.
  final ApiErrorType type;

  /// كود الحالة الراجع من الخادم إن وجد (200، 404، 500 ...).
  final int? statusCode;

  /// أخطاء تفصيلية لكل حقل، مثل أخطاء التحقق القادمة من الباك إند:
  /// { "email": ["البريد الإلكتروني مستخدم من قبل"] }
  final Map<String, List<String>>? errors;

  /// تتبع الخطأ الأصلي (لأغراض التسجيل/التشخيص فقط).
  final StackTrace? stackTrace;

  factory ApiFailure.network([
    String message =
        'تعذر الاتصال بالإنترنت، يرجى التحقق من اتصالك والمحاولة مجدداً.',
  ]) {
    return ApiFailure(message: message, type: ApiErrorType.network);
  }

  factory ApiFailure.timeout([
    String message =
        'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
  ]) {
    return ApiFailure(message: message, type: ApiErrorType.timeout);
  }

  factory ApiFailure.server({
    String message = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
    int? statusCode,
  }) {
    return ApiFailure(
      message: message,
      type: ApiErrorType.server,
      statusCode: statusCode,
    );
  }

  factory ApiFailure.unauthorized([
    String message = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً.',
  ]) {
    return const ApiFailure(
      message: '',
      type: ApiErrorType.unauthorized,
    ).copyWith(message: message, statusCode: 401);
  }

  factory ApiFailure.notFound([String message = 'العنصر المطلوب غير موجود.']) {
    return ApiFailure(
      message: message,
      type: ApiErrorType.notFound,
      statusCode: 404,
    );
  }

  factory ApiFailure.unknown([
    String message = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
  ]) {
    return ApiFailure(message: message, type: ApiErrorType.unknown);
  }

  ApiFailure copyWith({
    String? message,
    ApiErrorType? type,
    int? statusCode,
    Map<String, List<String>>? errors,
    StackTrace? stackTrace,
  }) {
    return ApiFailure(
      message: message ?? this.message,
      type: type ?? this.type,
      statusCode: statusCode ?? this.statusCode,
      errors: errors ?? this.errors,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }

  @override
  String toString() =>
      'ApiFailure(type: $type, statusCode: $statusCode, message: $message)';
}

/// نتيجة موحّدة لأي عملية قادمة من طبقة البيانات (Repository/DataSource)،
/// سواء كانت من بيانات وهمية محلية حالياً أو من API حقيقي مستقبلاً.
///
/// استخدام sealed class يتيح مطابقة الأنماط (pattern matching) الشاملة
/// عبر switch، بحيث يجبرنا المحلل على معالجة كل الحالات الممكنة.
///
/// مثال:
/// ```dart
/// final result = await repository.getHousings();
/// switch (result) {
///   case ApiSuccess(:final data):
///     // استخدام data
///   case ApiFailureResult(:final failure):
///     // عرض failure.message
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  /// إنشاء نتيجة ناجحة.
  factory ApiResult.success(T data) = ApiSuccess<T>;

  /// إنشاء نتيجة فاشلة.
  factory ApiResult.failure(ApiFailure failure) = ApiFailureResult<T>;

  bool get isSuccess => this is ApiSuccess<T>;

  bool get isFailure => this is ApiFailureResult<T>;

  /// إرجاع البيانات في حال النجاح أو null في حال الفشل.
  T? get dataOrNull => switch (this) {
    ApiSuccess<T>(:final data) => data,
    ApiFailureResult<T>() => null,
  };

  /// إرجاع كائن الفشل في حال الفشل أو null في حال النجاح.
  ApiFailure? get failureOrNull => switch (this) {
    ApiSuccess<T>() => null,
    ApiFailureResult<T>(:final failure) => failure,
  };

  /// تحويل النتيجة إلى قيمة واحدة عبر معالجة الحالتين إجبارياً.
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiFailure failure) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailureResult<T>(failure: final apiFailure) => failure(apiFailure),
    };
  }

  /// تحويل نوع البيانات الداخلي مع الحفاظ على حالة النجاح/الفشل.
  ApiResult<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      ApiSuccess<T>(:final data) => ApiResult<R>.success(transform(data)),
      ApiFailureResult<T>(:final failure) => ApiResult<R>.failure(failure),
    };
  }
}

/// حالة نجاح الطلب مع البيانات المطلوبة.
final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ApiSuccess<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'ApiSuccess(data: $data)';
}

/// حالة فشل الطلب مع تفاصيل الخطأ.
final class ApiFailureResult<T> extends ApiResult<T> {
  const ApiFailureResult(this.failure);

  final ApiFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiFailureResult<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'ApiFailureResult(failure: $failure)';
}
