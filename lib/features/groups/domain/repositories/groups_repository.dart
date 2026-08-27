import '../../../../core/network/api_result.dart';
import '../entities/student_group.dart';

/// عقد (Interface) طبقة الغروبات، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية.
abstract class GroupsRepository {
  /// جلب غروب المستخدم الحالي، أو null إن لم ينضم لأي غروب.
  Future<ApiResult<StudentGroup?>> fetchMyGroup();

  /// إنشاء غروب جديد يكون المستخدم الحالي قائداً له. يتطلب وجود طلب سكن
  /// فردي مقدَّم مسبقاً ضمن الدورة الحالية.
  Future<ApiResult<StudentGroup>> createGroup({String? description});

  /// إرسال طلب انضمام لغروب عبر كوده — طلب معلَّق بانتظار موافقة القائد،
  /// وليس انضماماً فورياً.
  Future<ApiResult<void>> joinGroupByCode(String code);

  /// الموافقة أو الرفض على طلب انضمام معلَّق (للقائد فقط).
  Future<ApiResult<void>> respondToInvitation({
    required int invitationId,
    required bool approve,
  });

  /// مغادرة الغروب الحالي — إن كان المستخدم القائد وبقي أعضاء آخرون، تُنقل
  /// القيادة تلقائياً لأقدم عضو من جهة الباك إند، دون أي إجراء إضافي هنا.
  Future<ApiResult<void>> leaveGroup();

  /// يشيل عضواً من الغروب — للقائد فقط، ولا يمكنه شيل نفسه (يستخدم
  /// [leaveGroup] بدلاً من ذلك).
  Future<ApiResult<void>> removeMember(String studentId);
}
