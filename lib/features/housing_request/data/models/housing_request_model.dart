import '../../domain/entities/housing_request.dart';

class HousingRequestModel extends HousingRequest {
  const HousingRequestModel({
    required super.id,
    required super.requestType,
    required super.roomType,
    required super.preferredBuilding,
    required super.status,
    required super.createdAt,
    super.groupCode,
    super.documentNames,
    super.notes,
  });

  factory HousingRequestModel.fromJson(Map<String, dynamic> json) {
    return HousingRequestModel(
      id: json['id'] as String,
      requestType: json['requestType'] as String,
      roomType: json['roomType'] as String,
      preferredBuilding: json['preferredBuilding'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      groupCode: json['groupCode'] as String?,
      documentNames:
          (json['documentNames'] as List<dynamic>?)?.cast<String>() ?? const [],
      notes: json['notes'] as String?,
    );
  }
}
