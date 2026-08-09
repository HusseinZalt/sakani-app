import 'package:equatable/equatable.dart';

/// الكيان (Entity) الذي يمثل طلب خدمة ضمن طبقة الـ Domain.
///
/// يبقى مستقلاً تماماً عن مصدر البيانات (وهمي حالياً، وحقيقي عبر REST API
/// خلف Ocelot API Gateway مستقبلاً)، ولا يحتوي على أي منطق تحويل JSON.
class MaintenanceRequest extends Equatable {
  const MaintenanceRequest({
    required this.id,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  final String id;
  final String description;

  /// مفتاح تصنيف الطلب (internet, plumbing, electrical, cleaning, keys, other).
  final String category;

  /// حالة الطلب (pending, inProgress, completed).
  final String status;

  final DateTime createdAt;

  /// رابط صورة مرفقة بالطلب إن وُجدت.
  final String? imageUrl;

  @override
  List<Object?> get props => [
    id,
    description,
    category,
    status,
    createdAt,
    imageUrl,
  ];
}
