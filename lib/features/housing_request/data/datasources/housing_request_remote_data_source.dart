import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/server_message_ar.dart';
import '../../domain/entities/housing_document.dart';
import '../models/housing_request_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class HousingRequestException implements Exception {
  const HousingRequestException(
    this.message, {
    this.type = ApiErrorType.badRequest,
    this.statusCode,
  });

  final String message;
  final ApiErrorType type;

  /// كود الحالة HTTP الخام، عند الحاجة للتمييز بين حالتين تحملان نفس
  /// [type] (راجع الاستخدام بـ [payForRequest] لـ 409 الغامض).
  final int? statusCode;
}

/// مصدر بيانات طلب السكن — يستدعي خدمة السكن الحقيقية (ASP.NET Core على
/// `housingservice001.runasp.net`، راجع `HousingService_Guide.md`).
///
/// **مؤكَّد بالاختبار الفعلي (2026-08-23):** نقاط `/mine` (طلب السكن،
/// الغروبات، التخصيص) كانت تُرجع 403 لكل حسابات الطلاب بسبب عدم تطابق
/// قيمة الدور بالتوكن (`student` من خدمة المصادقة) مع الدور المتوقَّع
/// (`user`) — تم إصلاحه من جهة الباك إند.
class HousingRequestRemoteDataSource {
  HousingRequestRemoteDataSource({Dio? dio})
    : _dio = dio ?? ApiClient.housing.dio;

  final Dio _dio;

  /// دورة السكن المفتوحة حالياً، أو null إن لم توجد (404).
  Future<HousingCycleModel?> fetchCurrentCycle() async {
    try {
      final response = await _dio.get<dynamic>('/api/housing-cycles/current');
      return HousingCycleModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapDioException(e);
    }
  }

  /// تخصيص الغرفة الفعلي للطالب، أو null إن لم يُخصَّص بعد (404) — إجراء
  /// إداري منفصل عن قرار القبول، قد يتأخر عنه.
  Future<AllocationModel?> fetchMyAllocation() async {
    try {
      final response = await _dio.get<dynamic>('/api/allocations/mine');
      final allocation = AllocationModel.fromJson(_asJsonMap(response.data));
      // احتياطي: لو رجعت الخدمة تخصيصاً قديماً أُخلي عنه فعلاً
      // (`vacatedAt` معبّأ) بدل حذفه من `/mine`، نتعامل معه كأنه لا
      // يوجد تخصيص نشط أصلاً — وإلا يبقى الطالب يظهر "مسكون" للأبد
      // حتى بعد إخلاء غرفته فعلياً.
      if (allocation.vacatedAt != null) return null;
      return allocation;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _mapDioException(e);
    }
  }

  Future<List<GovernorateModel>> fetchGovernorates() async {
    try {
      final response = await _dio.get<dynamic>('/api/governorates');
      final items = _asJsonList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(GovernorateModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// قائمة الأبنية السكنية — لملء اختيار "المبنى السابق" بقسم "سكنت
  /// سابقاً"، بنفس نمط [fetchGovernorates].
  ///
  /// **مؤكَّد بالاختبار الفعلي (2026-08-28):** `GET /api/buildings` (قائمة
  /// الإدارة الكاملة) ترجع 403 لأي حساب طالب — مقصورة فعلياً على
  /// admin/super_admin رغم أن توثيق Swagger لا يُظهر أي قيد صلاحيات
  /// عليها. نقطة `GET /api/buildings/lookup` هي المخصَّصة صراحة لهذا
  /// الاستخدام (ترجع 200 لأي حساب مصادَق). **تحديث (راجع
  /// `frontend-previous-residence-picker.md`):** `floorsCount` فعلياً
  /// جزء من `BuildingLookupDto` (قد يكون `null` لبعض المباني تحديداً،
  /// وليس غائباً عن الـ DTO بالكامل كما ظُنَّ سابقاً) — الواجهة تعرض
  /// طوابق `1..floorsCount` جاهزة عندما تتوفر، وتبقي الإدخال اليدوي
  /// احتياطاً فقط لحالة `null` (راجع `housing_request_screen.dart`).
  Future<List<BuildingModel>> fetchBuildings() async {
    try {
      final response = await _dio.get<dynamic>('/api/buildings/lookup');
      final items = _asJsonList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(BuildingModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// غرف مبنى واحد — تُستخدم لملء اختيار "رقم الغرفة" بعد فلترتها محلياً
  /// حسب الطابق المختار.
  ///
  /// **تحديث (راجع `frontend-previous-residence-picker.md`):**
  /// `GET /api/buildings/{id}/rooms` (المستخدَمة سابقاً هنا) إدارية
  /// بالكامل وترجع 403 لحساب طالب، تماماً متل `/api/buildings` قبلها
  /// (راجع توثيق [fetchBuildings] أعلاه) — `/rooms/lookup` هي النقطة
  /// المخصَّصة صراحة لهذا الاستخدام الطلابي (`RoomLookupDto`: `id`,
  /// `floor`, `roomNumber` فقط، بلا حالة الغرفة أو شغلها، حفاظاً على
  /// خصوصية الساكن الحالي).
  Future<List<DormRoomModel>> fetchRoomsForBuilding(int buildingId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/buildings/$buildingId/rooms/lookup',
      );
      final items = _asJsonList(response.data);
      return items
          .whereType<Map<String, dynamic>>()
          .map(DormRoomModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// طلب سكن واحد على الأكثر عادةً لكل طالب بكل دورة — نأخذ أول عنصر إن
  /// وُجد (`GET /api/housing-requests/mine` تُرجع مصفوفة).
  Future<HousingRequestModel?> fetchMyRequest() async {
    try {
      final response = await _dio.get<dynamic>('/api/housing-requests/mine');
      final items = _asJsonList(response.data);
      final maps = items.whereType<Map<String, dynamic>>().toList();
      if (maps.isEmpty) return null;
      return HousingRequestModel.fromJson(maps.first);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<HousingRequestModel> submitRequest({
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> documents,
  }) async {
    try {
      final formData = _buildFormData(
        gender: gender,
        governorateId: governorateId,
        academicLevel: academicLevel,
        detailedAddress: detailedAddress,
        hasSpecialNeeds: hasSpecialNeeds,
        isPreviousResident: isPreviousResident,
        previousBuildingId: previousBuildingId,
        previousFloor: previousFloor,
        previousRoomNumber: previousRoomNumber,
        specialNotes: specialNotes,
        documents: documents,
      );
      final response = await _dio.post<dynamic>(
        '/api/housing-requests',
        data: formData,
      );
      return HousingRequestModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// تعديل طلب بحالة `NeedsRevision` — أرسل فقط المستندات المُستبدَلة
  /// (`replacedDocuments`)، وليس كل المستندات الخمسة/السبعة من جديد.
  Future<HousingRequestModel> updateRequest({
    required int requestId,
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> replacedDocuments,
  }) async {
    try {
      final formData = _buildFormData(
        gender: gender,
        governorateId: governorateId,
        academicLevel: academicLevel,
        detailedAddress: detailedAddress,
        hasSpecialNeeds: hasSpecialNeeds,
        isPreviousResident: isPreviousResident,
        previousBuildingId: previousBuildingId,
        previousFloor: previousFloor,
        previousRoomNumber: previousRoomNumber,
        specialNotes: specialNotes,
        documents: replacedDocuments,
      );
      final response = await _dio.put<dynamic>(
        '/api/housing-requests/mine/$requestId',
        data: formData,
      );
      final body = _tryAsJsonMap(response.data);
      if (body != null) return HousingRequestModel.fromJson(body);

      // احتياطي: توثيق Swagger لهذا الـ endpoint تحديداً لا يُظهر أي
      // جسم استجابة (200 بلا محتوى) خلافاً لعملية التقديم المكافئة
      // (POST) التي ترجع الطلب كاملاً — قد يكون هذا سلوكاً فعلياً
      // للخادم، أو مجرد نقص بتوثيق Swagger. إن لم يصلنا جسم استجابة
      // صالح، نجلب الطلب المُحدَّث بنداء منفصل بدل اعتبار التعديل
      // فاشلاً رغم نجاحه فعلياً (الحالة 200 وصلت أصلاً).
      final refreshed = await fetchMyRequest();
      if (refreshed != null) return refreshed;
      throw const HousingRequestException(
        'تم حفظ التعديل، لكن تعذّر عرض النتيجة — يرجى تحديث الشاشة.',
        type: ApiErrorType.parsing,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// يحذف طلب سكن — مسموح فقط للطالب على طلبه هو (التحقق من الملكية من
  /// جهة الباك إند)، ويُرفض بـ 400 إن كان الطالب مُسكّناً فعلياً (لازم
  /// إخلاء المبنى أولاً). حسب توثيق الباك إند (2026-08-27) هذا الحذف
  /// يغادر الطالب تلقائياً من غروبه إن كان فيه، ويُلغي طلبات انضمامه
  /// المعلّقة لغروبات أخرى، ويحذف مستنداته من التخزين السحابي.
  Future<void> deleteRequest(int requestId) async {
    try {
      await _dio.delete<dynamic>('/api/housing-requests/$requestId');
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// دفع رسوم طلب سكن مقبول من رصيد محفظة الطالب.
  ///
  /// **عقد الفرونت §5 (محدَّث):** الجسم صار يحمل `amount` = الرسم
  /// المتوجّب على الطلب (`feeAmount` من `HousingRequestDto`) — قيمة
  /// مجمَّدة لا يختارها الطالب، نرسلها كما هي للتأكيد. نجاح 200 بجسم
  /// `{ "message": "...", "amount": 25.0, "balance": 75.0 }` —
  /// `balance` و`amount` حقول جذرية مباشرة، وقد يكون `balance` `null`
  /// أحياناً (عندها لا نغيّر الرصيد المحلي).
  Future<double?> payForRequest(int requestId, {required double amount}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/housing-requests/$requestId/pay',
        data: {'amount': amount},
      );
      final body = _tryAsJsonMap(response.data);
      return (body?['balance'] as num?)?.toDouble();
    } on DioException catch (e) {
      throw _mapPayException(e);
    }
  }

  /// **مؤكَّد الآن من فريق الباك إند:**
  /// - 402 حصرياً لرصيد غير كافٍ؛ 400 لـ"الطلب غير مقبول بعد" برسالة
  ///   مختلفة تماماً — لا داعي لتخمين السبب من نص الرسالة كما كان سابقاً.
  /// - 409 له معنيان لا يمكن التمييز بينهما من الاستجابة وحدها: مدفوع
  ///   مسبقاً، أو رسم السكن لهذه الدورة لم يُحدَّد بعد (0). الشاشة
  ///   المستدعية تُميّزهما بإعادة جلب الطلب وفحص `isPaid` الفعلي بعد هذا
  ///   الاستثناء (راجع `_StatusViewState._handlePay`)، فالرسالة هنا عامة
  ///   عمداً.
  /// - 403 = الطالب ليس مالك الطلب، 502 = تعذّر خدمة المصادقة (لا علاقة
  ///   بطلب السكن نفسه)، 404 بلا جسم.
  /// يعرض المبلغ بلا كسور إن كان عدداً صحيحاً، وإلا بمنزلتين عشريتين.
  static String _money(double amount) =>
      amount == amount.truncateToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);

  HousingRequestException _mapPayException(DioException e) {
    final statusCode = e.response?.statusCode;
    switch (statusCode) {
      case 400:
        return HousingRequestException(
          _extract400Message(e.response?.data),
          statusCode: statusCode,
        );
      case 402:
        final body = _tryAsJsonMap(e.response?.data);
        final needed = (body?['amount'] as num?)?.toDouble();
        final have = (body?['balance'] as num?)?.toDouble();
        return HousingRequestException(
          needed != null && have != null
              ? 'رصيدك في المحفظة غير كافٍ: رسوم السكن ${_money(needed)} '
                  'ورصيدك ${_money(have)}. يرجى شحن رصيدك أولاً.'
              : 'رصيدك في المحفظة غير كافٍ لدفع رسوم السكن، يرجى شحن رصيدك أولاً.',
          statusCode: statusCode,
        );
      case 403:
        return HousingRequestException(
          'لا تملك صلاحية دفع رسوم هذا الطلب.',
          type: ApiErrorType.forbidden,
          statusCode: statusCode,
        );
      case 404:
        return HousingRequestException(
          'لم يتم العثور على طلب السكن.',
          type: ApiErrorType.notFound,
          statusCode: statusCode,
        );
      case 409:
        return HousingRequestException(
          'تعذّر إتمام الدفع.',
          statusCode: statusCode,
        );
      case 502:
        return HousingRequestException(
          'تعذّر التحقق من حسابك حالياً، يرجى المحاولة لاحقاً.',
          type: ApiErrorType.server,
          statusCode: statusCode,
        );
      default:
        return _mapDioException(e);
    }
  }

  FormData _buildFormData({
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> documents,
  }) {
    final map = <String, dynamic>{
      'Gender': gender,
      'GovernorateId': governorateId,
      'AcademicLevel': academicLevel,
      'DetailedAddress': detailedAddress,
      'HasSpecialNeeds': hasSpecialNeeds,
      'IsPreviousResident': isPreviousResident,
      if (isPreviousResident && previousBuildingId != null)
        'PreviousBuildingId': previousBuildingId,
      if (isPreviousResident && previousFloor != null)
        'PreviousFloor': previousFloor,
      if (isPreviousResident &&
          previousRoomNumber != null &&
          previousRoomNumber.isNotEmpty)
        'PreviousRoomNumber': previousRoomNumber,
      if (specialNotes != null && specialNotes.isNotEmpty)
        'Notes': specialNotes,
    };

    for (final document in documents) {
      final bytes = document.bytes;
      if (bytes == null) continue;
      final field = _documentFieldName(document.type);
      map[field] = MultipartFile.fromBytes(
        bytes,
        filename: document.fileName ?? '$field.jpg',
      );
    }

    return FormData.fromMap(map);
  }

  static String _documentFieldName(HousingDocumentType type) {
    return switch (type) {
      HousingDocumentType.personalPhoto => 'PersonalPhoto',
      HousingDocumentType.nationalIdFront => 'NationalIdFront',
      HousingDocumentType.nationalIdBack => 'NationalIdBack',
      HousingDocumentType.universityIdFront => 'UniversityIdFront',
      HousingDocumentType.universityIdBack => 'UniversityIdBack',
      HousingDocumentType.departureReceipt => 'DepartureReceipt',
      HousingDocumentType.residencyProof => 'ResidencyProof',
    };
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw const HousingRequestException(
      'تعذّر قراءة استجابة الخادم، يرجى المحاولة مرة أخرى.',
      type: ApiErrorType.parsing,
    );
  }

  List<dynamic> _asJsonList(dynamic data) {
    if (data is List) return data;
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  HousingRequestException _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const HousingRequestException(
          'استغرق الاتصال بالخادم وقتاً أطول من المتوقع، حاول مرة أخرى.',
          type: ApiErrorType.timeout,
        );
      case DioExceptionType.connectionError:
        return const HousingRequestException(
          'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت.',
          type: ApiErrorType.network,
        );
      default:
        break;
    }

    switch (statusCode) {
      case 400:
        return HousingRequestException(_extract400Message(e.response?.data));
      case 401:
        return const HousingRequestException(
          'تعذّر التحقق من صلاحية الدخول لهذه الخدمة، يرجى تسجيل الدخول مرة أخرى.',
          type: ApiErrorType.unauthorized,
        );
      case 403:
        return const HousingRequestException(
          'لا تملك صلاحية الوصول لهذه الخدمة حالياً.',
          type: ApiErrorType.forbidden,
        );
      case 404:
        return const HousingRequestException(
          'لم يتم العثور على المطلوب.',
          type: ApiErrorType.notFound,
        );
      default:
        if (statusCode != null && statusCode >= 500) {
          return const HousingRequestException(
            'حدث خطأ في الخادم، يرجى المحاولة لاحقاً.',
            type: ApiErrorType.server,
          );
        }
        return const HousingRequestException(
          'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.',
        );
    }
  }

  Map<String, dynamic>? _tryAsJsonMap(dynamic data) {
    try {
      return _asJsonMap(data);
    } catch (_) {
      return null;
    }
  }

  static const _fieldLabels = <String, String>{
    'PersonalPhoto': 'الصورة الشخصية',
    'NationalIdFront': 'الهوية الوطنية (الوجه)',
    'NationalIdBack': 'الهوية الوطنية (الظهر)',
    'UniversityIdFront': 'الهوية الجامعية (الوجه)',
    'UniversityIdBack': 'الهوية الجامعية (الظهر)',
    'DepartureReceipt': 'إيصال المغادرة',
    'ResidencyProof': 'سند الإقامة',
    'Gender': 'الجنس',
    'GovernorateId': 'المحافظة',
    'AcademicLevel': 'المستوى الدراسي',
    'DetailedAddress': 'العنوان التفصيلي',
    'HasSpecialNeeds': 'الاحتياجات الخاصة',
    'IsPreviousResident': 'السكن السابق',
    'PreviousBuildingId': 'رقم المبنى السابق',
    'PreviousFloor': 'الطابق السابق',
    'PreviousRoomNumber': 'رقم الغرفة السابقة',
    'Notes': 'الملاحظات',
  };

  /// يستخرج رسالة خطأ عربية مفهومة من استجابة 400، بغض النظر عن شكلها:
  /// إما `ValidationProblemDetails` القياسية بـ ASP.NET Core (حقل
  /// `errors` بمفتاح لكل حقل غير صالح — مؤكَّد بالاختبار الفعلي هذا هو
  /// الشكل عند نقص مستند إلزامي)، أو نص خام بسيط بلا JSON إطلاقاً
  /// (مؤكَّد أيضاً — مثال: `"Governorate was not found."` عند معرّف
  /// محافظة غير موجود). **قبل هذا الإصلاح كانت كلتا الحالتين تُستبدَلان
  /// برسالة عامة غير مفيدة تخفي السبب الحقيقي عن المستخدم.**
  String _extract400Message(dynamic rawData) {
    final body = _tryAsJsonMap(rawData);
    const fallback = 'البيانات المُدخلة غير صحيحة، يرجى مراجعتها.';

    // رسالة عمل صريحة من الخادم (`{ "message": "..." }` / `detail`) —
    // المصدر الأساسي للنصوص الإنجليزية التي كانت تظهر كما هي، فتُترجَم
    // للعربية قبل أي معالجة أخرى.
    final serverText =
        (body?['message'] ?? body?['detail'] ?? body?['error']) as String?;
    if (serverText != null && serverText.trim().isNotEmpty) {
      return translateServerMessageAr(serverText, fallback: fallback);
    }

    if (body != null && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      final messages = <String>[];
      errors.forEach((field, value) {
        // نتجاهل الحقول غير المعروفة بدل إظهار اسمها الإنجليزي الخام.
        final label = _fieldLabels[field.toString()];
        if (label == null) return;
        final firstMessage =
            value is List && value.isNotEmpty ? value.first.toString() : null;
        if (firstMessage != null &&
            firstMessage.toLowerCase().contains('required')) {
          messages.add('$label مطلوب');
        } else {
          messages.add(label);
        }
      });
      if (messages.isNotEmpty) return messages.join('، ');
      return fallback;
    }

    final title = body?['title'] as String?;
    if (title != null &&
        title.isNotEmpty &&
        title != 'One or more validation errors occurred.') {
      return translateServerMessageAr(title, fallback: fallback);
    }

    if (rawData is String && rawData.trim().isNotEmpty) {
      final trimmed = rawData.trim();
      return _translateNotFoundMessage(trimmed) ??
          translateServerMessageAr(trimmed, fallback: fallback);
    }

    return fallback;
  }

  /// يترجم نص خطأ خام معروف الشكل مثل `"PreviousBuildingId was not
  /// found."` (مؤكَّد بالاختبار الفعلي — يظهر عند إدخال رقم مبنى سابق
  /// غير مسجَّل فعلياً بجدول المباني عند الخادم، إذ الحقل يُتحقَّق منه
  /// كمعرّف حقيقي لمبنى موجود وليس مجرد رقم حر يذكره الطالب) إلى رسالة
  /// عربية بنفس اسم الحقل المألوف للمستخدم بدل تركه بالإنجليزية الخام.
  String? _translateNotFoundMessage(String message) {
    final match = RegExp(
      r'^(\w+) was not found\.?$',
      caseSensitive: false,
    ).firstMatch(message);
    if (match == null) return null;
    final field = match.group(1)!;
    final label = _fieldLabels[field] ?? field;
    return '$label الذي أدخلته غير مسجَّل في النظام، يرجى التحقق منه.';
  }
}
