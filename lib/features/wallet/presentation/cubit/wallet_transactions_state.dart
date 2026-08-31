import '../../../../core/network/api_result.dart';
import '../../domain/entities/wallet_transaction.dart';

/// حالات شاشة سجل عمليات المحفظة.
///
/// استخدام sealed class يجبر واجهة المستخدم على معالجة كل الحالات
/// الممكنة (Loading/Success/Failure) عبر switch شامل دون إغفال أي حالة.
sealed class WalletTransactionsState {
  const WalletTransactionsState();
}

/// الحالة الابتدائية قبل أول عملية جلب.
final class WalletTransactionsInitial extends WalletTransactionsState {
  const WalletTransactionsInitial();
}

/// جارٍ جلب الصفحة الأولى من السجل.
final class WalletTransactionsLoading extends WalletTransactionsState {
  const WalletTransactionsLoading();
}

/// تم جلب السجل بنجاح (صفحة واحدة أو أكثر مجمّعة).
final class WalletTransactionsSuccess extends WalletTransactionsState {
  const WalletTransactionsSuccess({
    required this.transactions,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<WalletTransaction> transactions;
  final bool hasMore;

  /// جارٍ جلب صفحة إضافية حالياً — تُعرض كمؤشر تحميل صغير أسفل القائمة
  /// دون إخفاء العناصر المعروضة فعلاً.
  final bool isLoadingMore;

  WalletTransactionsSuccess copyWith({
    List<WalletTransaction>? transactions,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WalletTransactionsSuccess(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// فشل جلب السجل مع تفاصيل الخطأ.
final class WalletTransactionsFailure extends WalletTransactionsState {
  const WalletTransactionsFailure(this.failure);

  final ApiFailure failure;
}
