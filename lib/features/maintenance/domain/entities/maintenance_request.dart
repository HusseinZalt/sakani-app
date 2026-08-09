import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// الكيان (Entity) الذي يمثل طلب خدمة ضمن طبقة الـ Domain.
///
/// يبقى مستقلاً تماماً عن مصدر البيانات (وهمي حالياً، وحقيقي عبر REST API
/// خلف Ocelot API Gateway مستقبلاً)، ولا يحتوي على أي منطق تحويل JSON.
class MaintenanceRequest extends Equatable {
  const MaintenanceRequest({
    required this.id,
    required this.userId,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.imageBytes,
  });

  final String id;

  /// معرّف صاحب الطلب، لضمان عدم ظهور طلبات مستخدم آخر عند تبديل الحساب
  /// على نفس الجهاز.
  final String userId;
  final String description;

  /// مفتاح تصنيف الطلب (internet, plumbing, electrical, cleaning, keys, other).
  final String category;

  /// حالة الطلب (pending, inProgress, completed).
  final String status;

  final DateTime createdAt;

  /// رابط صورة مرفقة بالطلب بعد رفعها لخادم حقيقي (غير متوفر بعد).
  final String? imageUrl;

  /// بايتات الصورة المرفقة محلياً — الطريقة الوحيدة المتاحة حالياً لعرض
  /// الصورة بما أن مصدر البيانات وهمي ولا يرفع أي شيء فعلياً بعد.
  final Uint8List? imageBytes;

  @override
  List<Object?> get props => [
    id,
    userId,
    description,
    category,
    status,
    createdAt,
    imageUrl,
    imageBytes,
  ];
}
