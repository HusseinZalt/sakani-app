import '../../../../core/network/api_result.dart';
import '../../domain/entities/wallet_redeem_result.dart';
import '../../domain/entities/wallet_transactions_page.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

/// التنفيذ الفعلي لعقد [WalletRepository]، مسؤول فقط عن استدعاء مصدر
/// البيانات وتحويل نتيجته (أو الاستثناء الذي يرميه) إلى [ApiResult] موحّد
/// تستهلكه طبقة الـ Presentation دون الحاجة لمعرفة تفاصيل مصدر البيانات.
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({WalletRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? WalletRemoteDataSource();

  final WalletRemoteDataSource _remoteDataSource;

  @override
  Future<ApiResult<WalletRedeemResult>> redeemVoucher(String code) async {
    try {
      final result = await _remoteDataSource.redeem(code);
      return ApiResult.success(
        WalletRedeemResult(amount: result.amount, balance: result.balance),
      );
    } on WalletException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }

  @override
  Future<ApiResult<WalletTransactionsPage>> fetchTransactions({
    required int page,
    int limit = 20,
  }) async {
    try {
      final result = await _remoteDataSource.fetchTransactions(
        page: page,
        limit: limit,
      );
      return ApiResult.success(result);
    } on WalletException catch (e) {
      return ApiResult.failure(ApiFailure(message: e.message, type: e.type));
    } catch (_) {
      return ApiResult.failure(ApiFailure.unknown());
    }
  }
}
