import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_transactions_state.dart';

/// يدير حالة سجل عمليات المحفظة عبر [WalletRepository]، بما فيها تحميل
/// صفحات إضافية (Load more) عند الطلب.
class WalletTransactionsCubit extends Cubit<WalletTransactionsState> {
  WalletTransactionsCubit(this._repository)
    : super(const WalletTransactionsInitial());

  static const _pageSize = 20;

  final WalletRepository _repository;
  int _page = 1;

  /// جلب الصفحة الأولى من جديد (فتح الشاشة أو سحب للتحديث).
  Future<void> fetchTransactions() async {
    _page = 1;
    if (state is! WalletTransactionsSuccess) {
      emit(const WalletTransactionsLoading());
    }

    final result = await _repository.fetchTransactions(
      page: _page,
      limit: _pageSize,
    );

    switch (result) {
      case ApiSuccess(:final data):
        emit(
          WalletTransactionsSuccess(
            transactions: data.items,
            hasMore: data.hasMore,
          ),
        );
      case ApiFailureResult(:final failure):
        emit(WalletTransactionsFailure(failure));
    }
  }

  /// جلب الصفحة التالية وإلحاقها بالقائمة الحالية. لا تفعل شيئاً إن لم
  /// تكن هناك صفحة تالية، أو كان هناك جلب جارٍ بالفعل.
  Future<void> loadMore() async {
    final current = state;
    if (current is! WalletTransactionsSuccess ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));

    final nextPage = _page + 1;
    final result = await _repository.fetchTransactions(
      page: nextPage,
      limit: _pageSize,
    );

    switch (result) {
      case ApiSuccess(:final data):
        _page = nextPage;
        emit(
          WalletTransactionsSuccess(
            transactions: [...current.transactions, ...data.items],
            hasMore: data.hasMore,
          ),
        );
      case ApiFailureResult():
        // فشل جلب صفحة إضافية لا يجوز أن يمسح القائمة المعروضة فعلاً —
        // نعيدها لحالتها قبل محاولة التحميل حتى يتمكن المستخدم من إعادة
        // المحاولة بالضغط على "تحميل المزيد" مجدداً.
        emit(current.copyWith(isLoadingMore: false));
    }
  }
}
