import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/entities/home_dashboard.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

/// يدير حالة شاشة الرئيسية عبر [HomeRepository]، دون معرفة ما إذا كانت
/// البيانات وهمية حالياً أو قادمة من API حقيقي مستقبلاً.
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeInitial());

  final HomeRepository _repository;

  /// عند استدعاء متكرر (مثلاً عند العودة للتبويب) وسبق أن ظهرت بيانات
  /// ناجحة، لا نُظهر شاشة تحميل كاملة من جديد — نُبقي المحتوى الحالي
  /// ونستبدله بهدوء فقط عند وصول النتيجة الجديدة.
  Future<void> fetchDashboard() async {
    if (state is! HomeSuccess) emit(const HomeLoading());

    final result = await _repository.fetchDashboard();

    switch (result) {
      case ApiSuccess<HomeDashboard>(:final data):
        emit(HomeSuccess(data));
      case ApiFailureResult<HomeDashboard>(:final failure):
        emit(HomeFailure(failure));
    }
  }
}
