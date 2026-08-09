import '../../domain/entities/home_dashboard.dart';

class HousingStatusModel extends HousingStatus {
  const HousingStatusModel({
    required super.status,
    super.buildingUnit,
    super.roomNumber,
    super.daysUntilPayment,
    super.paymentReference,
  });

  factory HousingStatusModel.fromJson(Map<String, dynamic> json) {
    return HousingStatusModel(
      status: json['status'] as String,
      buildingUnit: json['buildingUnit'] as String?,
      roomNumber: json['roomNumber'] as String?,
      daysUntilPayment: json['daysUntilPayment'] as int?,
      paymentReference: json['paymentReference'] as String?,
    );
  }
}

class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.colorVariant,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      colorVariant: json['colorVariant'] as String,
    );
  }
}

class ActivityLogItemModel extends ActivityLogItem {
  const ActivityLogItemModel({
    required super.id,
    required super.text,
    required super.time,
    required super.colorKey,
  });

  factory ActivityLogItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogItemModel(
      id: json['id'] as String,
      text: json['text'] as String,
      time: json['time'] as String,
      colorKey: json['colorKey'] as String,
    );
  }
}

class HomeDashboardModel extends HomeDashboard {
  const HomeDashboardModel({
    required super.studentName,
    required super.housingStatus,
    required super.announcements,
    required super.activities,
  });

  factory HomeDashboardModel.fromJson(Map<String, dynamic> json) {
    return HomeDashboardModel(
      studentName: json['studentName'] as String,
      housingStatus: HousingStatusModel.fromJson(
        json['housingStatus'] as Map<String, dynamic>,
      ),
      announcements:
          (json['announcements'] as List)
              .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      activities:
          (json['activities'] as List)
              .map(
                (e) => ActivityLogItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
