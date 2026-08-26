import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../data/group_member_names_cache.dart';
import '../../domain/entities/student_group.dart';
import '../../domain/repositories/groups_repository.dart';
import 'groups_state.dart';

/// يدير حالة شاشة الغروبات عبر [GroupsRepository].
class GroupsCubit extends Cubit<GroupsState> {
  GroupsCubit(this._repository) : super(const GroupsInitial());

  final GroupsRepository _repository;

  /// عند استدعاء متكرر (مثلاً عند العودة للتبويب) وسبق أن ظهرت بيانات
  /// ناجحة، لا نُظهر شاشة تحميل كاملة من جديد — نُبقي المحتوى الحالي
  /// ونستبدله بهدوء فقط عند وصول النتيجة الجديدة.
  Future<void> fetchMyGroup() async {
    if (state is! GroupsSuccess) emit(const GroupsLoading());

    final result = await _repository.fetchMyGroup();

    switch (result) {
      case ApiSuccess<StudentGroup?>(:final data):
        // كل طلب انضمام يمرّ أمام القائد (حتى لو رُفض أو قُبل لاحقاً)
        // يحمل اسم الطالب الحقيقي — نخزّنه محلياً فور وصوله حتى يبقى
        // معروفاً حتى بعد اختفاء الطلب من قائمة "المعلَّقة".
        await GroupMemberNamesCache.merge({
          for (final invitation in data?.pendingInvitations ?? const [])
            if (invitation.studentName != null)
              invitation.invitedStudentId: invitation.studentName!,
        });
        final memberNames = await GroupMemberNamesCache.load();
        emit(GroupsSuccess(data, memberNames: memberNames));
      case ApiFailureResult<StudentGroup?>(:final failure):
        emit(GroupsFailure(failure));
    }
  }

  Future<ApiResult<void>> createGroup({String? description}) async {
    final result = await _repository.createGroup(description: description);
    if (result.isSuccess) await fetchMyGroup();
    return result.map((_) {});
  }

  Future<ApiResult<void>> joinGroupByCode(String code) async {
    final result = await _repository.joinGroupByCode(code);
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }

  Future<ApiResult<void>> respondToInvitation({
    required int invitationId,
    required bool approve,
  }) async {
    final result = await _repository.respondToInvitation(
      invitationId: invitationId,
      approve: approve,
    );
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }

  Future<ApiResult<void>> leaveGroup() async {
    final result = await _repository.leaveGroup();
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }
}
