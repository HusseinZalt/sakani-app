import '../../../../core/network/api_result.dart';
import '../entities/wallet_redeem_result.dart';
import '../entities/wallet_transactions_page.dart';

/// عقد (Interface) محفظة الطالب، تعتمد عليه طبقة الـ Presentation دون
/// معرفة تفاصيل التنفيذ الفعلية (نداءات REST حقيقية لخدمة المصادقة خلف
/// البوابة الموحّدة، راجع `wallet_remote_data_source.dart`).
abstract class WalletRepository {
  /// شحن الرصيد عبر كود مُستخرج من ملصق QR — يُستهلك مرة واحدة فقط
  /// (404 لكود غير صحيح، 409 لكود مُستخدم سابقاً، راجع تفاصيل الترجمة
  /// بـ [WalletException]).
  Future<ApiResult<WalletRedeemResult>> redeemVoucher(String code);

  /// جلب صفحة من سجل عمليات المحفظة (شحن + دفع)، الأحدث أولاً.
  Future<ApiResult<WalletTransactionsPage>> fetchTransactions({
    required int page,
    int limit = 20,
  });
}
