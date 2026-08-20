import '../../../../core/network/api_client.dart';
import '../../../../core/utils/parse_utc_date_time.dart';
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
    super.imageUrl,
    super.colorVariant,
    super.startDate,
    super.endDate,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      colorVariant: json['colorVariant'] as String,
    );
  }

  /// يحوّل عنصر `AdvertisementDto` من خدمة الإعلانات الحقيقية (ASP.NET
  /// Core، راجع `/swagger`) إلى نموذج التطبيق. `colorVariant` يبقى بقيمته
  /// الافتراضية (تُستخدم فقط كاحتياط عند غياب [imageUrl]).
  factory AnnouncementModel.fromAdJson(Map<String, dynamic> json) {
    final startDate = json['startDate'] as String?;
    final endDate = json['endDate'] as String?;
    return AnnouncementModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      subtitle: json['description'] as String? ?? '',
      imageUrl: _resolveImageUrl(json['imageUrl'] as String?),
      startDate: startDate != null ? parseUtcDateTime(startDate) : null,
      endDate: endDate != null ? parseUtcDateTime(endDate) : null,
    );
  }

  static String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${ApiClient.adsBaseUrl}$normalized';
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
