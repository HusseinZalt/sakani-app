import '../../../../core/network/api_result.dart';
import '../entities/groups_data.dart';
import '../entities/student_group.dart';

/// عقد (Interface) طبقة الغروبات، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (وهمية حالياً أو عبر API حقيقي مستقبلاً).
abstract class GroupsRepository {
  /// جلب غروب المستخدم الحالي (إن وُجد) ودعوات الانضمام المعلّقة.
  Future<ApiResult<GroupsData>> fetchGroupsData();

  /// إنشاء غروب جديد يكون المستخدم الحالي قائداً له.
  Future<ApiResult<StudentGroup>> createGroup();

  /// الانضمام إلى غروب عبر كوده. ينقل المستخدم من غروبه الحالي إن وُجد.
  Future<ApiResult<StudentGroup>> joinGroupByCode(String code);

  /// دعوة عضو جديد للانضمام إلى غروب المستخدم الحالي عبر بريده/جواله.
  Future<ApiResult<void>> inviteMember(String identifier);

  /// قبول دعوة انضمام معلّقة.
  Future<ApiResult<StudentGroup>> acceptInvite(String inviteId);

  /// رفض دعوة انضمام معلّقة.
  Future<ApiResult<void>> declineInvite(String inviteId);

  /// مغادرة الغروب الحالي. إن كان المستخدم قائداً وهناك أعضاء آخرون، يجب
  /// نقل القيادة أولاً عبر [transferLeadership].
  Future<ApiResult<void>> leaveGroup();

  /// نقل قيادة الغروب الحالي إلى عضو آخر (متاح فقط للقائد الحالي).
  Future<ApiResult<StudentGroup>> transferLeadership(String newLeaderId);
}
