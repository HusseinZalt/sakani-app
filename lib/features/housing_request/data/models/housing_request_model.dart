import '../../../../core/network/api_client.dart';
import '../../../../core/utils/parse_utc_date_time.dart';
import '../../domain/entities/allocation.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/dorm_room.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_cycle.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';

class AllocationModel extends Allocation {
  const AllocationModel({
    required super.roomNumber,
    required super.buildingName,
    required super.allocatedAt,
  });

  factory AllocationModel.fromJson(Map<String, dynamic> json) {
    return AllocationModel(
      roomNumber: json['roomNumber'] as String? ?? '',
      buildingName: json['buildingName'] as String? ?? '',
      allocatedAt: parseUtcDateTime(json['allocatedAt'] as String),
    );
  }
}

class GovernorateModel extends Governorate {
  const GovernorateModel({required super.id, required super.name});

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    return GovernorateModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

class BuildingModel extends Building {
  const BuildingModel({
    required super.id,
    required super.name,
    super.floorsCount,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      floorsCount: json['floorsCount'] as int?,
    );
  }
}

class DormRoomModel extends DormRoom {
  const DormRoomModel({
    required super.id,
    required super.roomNumber,
    required super.floor,
  });

  factory DormRoomModel.fromJson(Map<String, dynamic> json) {
    return DormRoomModel(
      id: json['id'] as int,
      roomNumber: json['roomNumber'] as String? ?? '',
      floor: json['floor'] as int? ?? 0,
    );
  }
}

class HousingCycleModel extends HousingCycle {
  const HousingCycleModel({
    required super.id,
    required super.name,
    required super.isOpen,
  });

  /// `HousingCycleStatus`: 0=Closed، 1=Open — مؤكَّدة عبر Swagger الخدمة.
  factory HousingCycleModel.fromJson(Map<String, dynamic> json) {
    return HousingCycleModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      isOpen: json['status'] == 1,
    );
  }
}

class HousingDocumentModel extends HousingDocument {
  const HousingDocumentModel({
    required super.type,
    super.id,
    super.url,
    super.reviewStatus,
    super.reviewNotes,
  });

  factory HousingDocumentModel.fromJson(Map<String, dynamic> json) {
    return HousingDocumentModel(
      type: HousingDocumentType.fromApiValue(json['type'] as int? ?? 0),
      id: json['id'] as int?,
      url: _resolveFileUrl(json['documentPath'] as String?),
      reviewStatus: DocumentReviewStatus.fromApiValue(
        json['reviewStatus'] as int? ?? 0,
      ),
      reviewNotes: json['reviewNotes'] as String?,
    );
  }

  static String? _resolveFileUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${ApiClient.housingBaseUrl}$normalized';
  }
}

class AdmissionDecisionModel extends AdmissionDecision {
  const AdmissionDecisionModel({
    required super.status,
    super.decisionReason,
    super.decisionDate,
  });

  factory AdmissionDecisionModel.fromJson(Map<String, dynamic> json) {
    final decisionDate = json['decisionDate'] as String?;
    return AdmissionDecisionModel(
      status: AdmissionDecisionStatus.fromApiValue(json['status'] as int? ?? 0),
      decisionReason: json['decisionReason'] as String?,
      decisionDate:
          decisionDate != null ? parseUtcDateTime(decisionDate) : null,
    );
  }
}

class HousingRequestModel extends HousingRequest {
  const HousingRequestModel({
    required super.id,
    required super.gender,
    required super.governorateId,
    required super.academicLevel,
    required super.detailedAddress,
    required super.hasSpecialNeeds,
    required super.isPreviousResident,
    required super.status,
    required super.submittedAt,
    super.previousBuildingId,
    super.previousFloor,
    super.previousRoomNumber,
    super.specialNotes,
    super.documents,
    super.decision,
  });

  /// يحوّل عنصر `HousingRequestDto` من خدمة السكن الحقيقية (ASP.NET Core،
  /// راجع `HousingService_Guide.md`) إلى نموذج التطبيق.
  factory HousingRequestModel.fromJson(Map<String, dynamic> json) {
    final decisionJson = json['decision'] as Map<String, dynamic>?;
    return HousingRequestModel(
      id: json['id'] as int,
      gender: json['gender'] as int? ?? 0,
      governorateId: json['governorateId'] as int,
      academicLevel: json['academicLevel'] as int,
      detailedAddress: json['detailedAddress'] as String? ?? '',
      hasSpecialNeeds: json['hasSpecialNeeds'] as bool? ?? false,
      isPreviousResident: json['isPreviousResident'] as bool? ?? false,
      previousBuildingId: json['previousBuildingId'] as int?,
      previousFloor: json['previousFloor'] as int?,
      previousRoomNumber: json['previousRoomNumber'] as String?,
      status: HousingRequestStatus.fromApiValue(json['status'] as int? ?? 0),
      specialNotes: json['specialNotes'] as String?,
      documents:
          (json['documents'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HousingDocumentModel.fromJson)
              .toList() ??
          const [],
      decision:
          decisionJson != null
              ? AdmissionDecisionModel.fromJson(decisionJson)
              : null,
      submittedAt: parseUtcDateTime(json['submittedAt'] as String),
    );
  }
}
