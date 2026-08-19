import '../../../../core/utils/parse_utc_date_time.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';

class HousingRequestModel extends HousingRequest {
  const HousingRequestModel({
    required super.id,
    required super.userId,
    required super.requestType,
    required super.roomType,
    required super.preferredBuilding,
    required super.status,
    required super.createdAt,
    super.groupCode,
    super.documents,
    super.notes,
  });

  /// ملاحظة: بايتات المستندات لا يمكن أن تصل عبر JSON (بيانات ثنائية محلية
  /// فقط)، لذا تبقى null دائماً عند القراءة من استجابة حقيقية مستقبلاً —
  /// يُفترض عندها أن تحمل الاستجابة `url` بدلاً منها.
  factory HousingRequestModel.fromJson(Map<String, dynamic> json) {
    return HousingRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      requestType: json['requestType'] as String,
      roomType: json['roomType'] as String,
      preferredBuilding: json['preferredBuilding'] as String,
      status: json['status'] as String,
      createdAt: parseUtcDateTime(json['createdAt'] as String),
      groupCode: json['groupCode'] as String?,
      documents:
          (json['documents'] as List<dynamic>?)
              ?.map(
                (d) => HousingDocument(
                  name: (d as Map<String, dynamic>)['name'] as String,
                  url: d['url'] as String?,
                ),
              )
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }
}
