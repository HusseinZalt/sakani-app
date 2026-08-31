import 'package:equatable/equatable.dart';

/// نتيجة شحن كود (Voucher) بنجاح عبر `POST /api/wallet/redeem`: قيمة
/// الشحنة نفسها، والرصيد الإجمالي الجديد بعد إضافتها مباشرة.
class WalletRedeemResult extends Equatable {
  const WalletRedeemResult({required this.amount, required this.balance});

  final double amount;
  final double balance;

  @override
  List<Object?> get props => [amount, balance];
}
