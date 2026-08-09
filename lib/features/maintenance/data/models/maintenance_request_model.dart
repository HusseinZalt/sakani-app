import '../../domain/entities/maintenance_request.dart';

/// نموذج بيانات طلب الخدمة (Model)، مسؤول عن تحويل استجابة الـ JSON
/// (وهمية حالياً، وحقيقية من REST API خلف Ocelot API Gateway مستقبلاً) إلى
/// الكيان [MaintenanceRequest] الذي تتعامل معه بقية طبقات التطبيق.
class MaintenanceRequestModel extends MaintenanceRequest {
  const MaintenanceRequestModel({
    required super.id,
    required super.userId,
    required super.description,
    required super.category,
    required super.status,
    required super.createdAt,
    super.imageUrl,
    super.imageBytes,
  });

  /// ملاحظة: [imageBytes] لا يمكن أن يصل عبر JSON (بيانات ثنائية محلية
  /// فقط)، لذا يبقى null دائماً عند القراءة من استجابة حقيقية مستقبلاً.
  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceRequestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'category': category,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
