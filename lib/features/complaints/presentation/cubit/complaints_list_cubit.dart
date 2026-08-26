import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaints_repository.dart';
import 'complaints_list_state.dart';

class ComplaintsListCubit extends Cubit<ComplaintsListState> {
  ComplaintsListCubit(this._repository) : super(const ComplaintsListInitial());

  final ComplaintsRepository _repository;

  Future<void> fetchComplaints() async {
    // لا تُصفَّر القائمة المعروضة فعلياً بمؤشر تحميل كامل الشاشة عند
    // التحديث بالسحب أو بعد إضافة شكوى جديدة، لتفادي وميض/إخفاء المحتوى
    // الظاهر بالفعل أثناء طلب خلفي.
    if (state is! ComplaintsListSuccess) emit(const ComplaintsListLoading());

    final result = await _repository.fetchComplaints();

    switch (result) {
      case ApiSuccess<List<Complaint>>(:final data):
        emit(ComplaintsListSuccess(data));
      case ApiFailureResult<List<Complaint>>(:final failure):
        emit(ComplaintsListFailure(failure));
    }
  }
}
