import 'dart:typed_data';

import '../../../../core/network/api_result.dart';
import '../entities/complaint.dart';

/// عقد (Interface) طبقة الشكاوى والاقتراحات، تعتمد عليه طبقة الـ
/// Presentation دون معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API
/// حقيقي مستقبلاً).
abstract class ComplaintsRepository {
  /// جلب جميع شكاوى/اقتراحات المستخدم الحالي.
  Future<ApiResult<List<Complaint>>> fetchComplaints();

  /// جلب شكوى/اقتراح واحد عبر معرّفه — يُستخدم عند الوصول للتفاصيل دون
  /// المرور بشاشة القائمة أولاً (مثال: رابط مباشر أو إشعار).
  Future<ApiResult<Complaint>> fetchComplaintById(String id);

  /// تقديم شكوى أو اقتراح جديد، مع إمكانية إرفاق صور وتقديمها بشكل مجهول.
  Future<ApiResult<Complaint>> submitComplaint({
    required String type,
    required String title,
    required String description,
    bool isAnonymous = false,
    List<Uint8List> images = const [],
  });
}
