import '../../../../core/network/api_result.dart';
import '../../domain/entities/wallet_redeem_result.dart';

/// حالات عملية شحن الرصيد عبر كود QR.
sealed class WalletRedeemState {
  const WalletRedeemState();
}

/// بانتظار مسح كود (لم تُرسَل أي محاولة شحن بعد).
final class WalletRedeemIdle extends WalletRedeemState {
  const WalletRedeemIdle();
}

/// جارٍ إرسال الكود للخادم.
final class WalletRedeemLoading extends WalletRedeemState {
  const WalletRedeemLoading();
}

/// تم الشحن بنجاح.
final class WalletRedeemSuccess extends WalletRedeemState {
  const WalletRedeemSuccess(this.result);

  final WalletRedeemResult result;
}

/// فشل الشحن (كود غير صحيح، مُستخدم سابقاً، أو خطأ اتصال).
final class WalletRedeemFailure extends WalletRedeemState {
  const WalletRedeemFailure(this.failure);

  final ApiFailure failure;
}
