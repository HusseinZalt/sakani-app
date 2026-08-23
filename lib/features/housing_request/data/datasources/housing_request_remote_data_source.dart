import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/housing_document.dart';
import '../models/housing_request_model.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب.
class HousingRequestException implements Exception {
  const HousingRequestException(
    this.message, {
    this.type = ApiErrorType.badRequest,
  });

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات طلب السكن — يستدعي خدمة السكن الحقيقية (ASP.NET Core على
/// `housingservice001.runasp.net`، راجع `HousingService_Guide.md`).
///
/// **مؤكَّد بالاختبار الفعلي (2026-08-23):** نقاط `/mine` (طلب السكن،
/// الغروبات، التخصيص) كانت تُرجع 403 لكل حسابات الطلاب بسبب عدم تطابق
/// قيمة الدور بالتوكن (`student` من خدمة المصادقة) مع الدور المتوقَّع
/// (`user`) — تم إصلاحه من جهة الباك إند.
class HousingRequestRemoteDataSource {
  HousingRequestRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.housing.dio;

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
      return HousingRequestModel.fromJson(_asJsonMap(response.data));
    } on DioException catch (e) {
      throw _mapDioException(e);
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
        final body = _tryAsJsonMap(e.response?.data);
        final message =
            body?['message'] as String? ??
            body?['title'] as String? ??
            'البيانات المُدخلة غير صحيحة، يرجى مراجعتها.';
        return HousingRequestException(message);
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
}
