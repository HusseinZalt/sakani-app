import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../data/pending_join_request_storage.dart';
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
        if (data != null) {
          // صار عضواً فعلياً (سواء بموافقة قائد على طلبه، أو لأنه أنشأ
          // غروباً بنفسه) — أي طلب انضمام معلَّق محلياً لم يعد ذا معنى.
          await PendingJoinRequestStorage.clear();
          emit(GroupsSuccess(data));
          return;
        }
        final pendingRequest = await PendingJoinRequestStorage.load();
        emit(GroupsSuccess(data, pendingJoinRequest: pendingRequest));
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
    if (result.isSuccess) {
      // يُخزَّن قبل fetchMyGroup لأن الأخير هو من يقرأه لعرض حالة
      // "بانتظار الرد" فوراً.
      await PendingJoinRequestStorage.save(code);
      await fetchMyGroup();
    }
    return result;
  }

  /// يوقف عرض حالة "بانتظار الرد" محلياً — راجع التوثيق المفصَّل بـ
  /// [PendingJoinRequestStorage] لحدود هذا الإجراء (لا يُلغي الطلب فعلياً
  /// عند الخادم، لعدم وجود نقطة نهاية لذلك حالياً).
  Future<void> cancelPendingJoinRequest() async {
    await PendingJoinRequestStorage.clear();
    final current = state;
    if (current is GroupsSuccess) {
      emit(GroupsSuccess(current.myGroup, pendingJoinRequest: null));
    }
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

  Future<ApiResult<void>> removeMember(String studentId) async {
    final result = await _repository.removeMember(studentId);
    if (result.isSuccess) await fetchMyGroup();
    return result;
  }
}
