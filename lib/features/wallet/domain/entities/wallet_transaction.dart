import 'package:equatable/equatable.dart';

/// حركة واحدة ضمن سجل عمليات المحفظة (شحن أو دفع)، قادمة من خدمة
/// المصادقة (`GET /api/wallet/transactions`، راجع
/// `wallet_remote_data_source.dart`).
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.reference,
  });

  /// 'topup' (شحن) أو 'payment' (دفع) كما يُرجعها الخادم — راجع
  /// [isTopup]/[isPayment] بدل مقارنة النص مباشرة في الواجهة.
  final String type;

  final double amount;

  /// الرصيد بعد تنفيذ هذه الحركة مباشرة.
  final double balanceAfter;

  final DateTime createdAt;

  /// مرجع الحركة: هوية طلب السكن عند الدفع (مثال: `housing-request-482`)،
  /// أو معرّف كود الشحن عند الشحن. قد يكون فارغاً.
  final String? reference;

  bool get isTopup => type == 'topup';

  bool get isPayment => type == 'payment';

  @override
  List<Object?> get props => [type, amount, balanceAfter, createdAt, reference];
}
