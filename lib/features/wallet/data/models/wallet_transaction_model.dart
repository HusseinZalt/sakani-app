import '../../../../core/utils/parse_utc_date_time.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.type,
    required super.amount,
    required super.balanceAfter,
    required super.createdAt,
    super.reference,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      type: json['type'] as String? ?? 'payment',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      createdAt:
          json['createdAt'] is String
              ? parseUtcDateTime(json['createdAt'] as String)
              : DateTime.now().toUtc(),
      reference: json['reference'] as String?,
    );
  }
}
