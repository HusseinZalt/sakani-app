import 'package:equatable/equatable.dart';

import 'wallet_transaction.dart';

/// صفحة واحدة من سجل عمليات المحفظة مع معلومات الترقيم (Pagination)
/// كما ترجعها `GET /api/wallet/transactions`، تُستخدم من
/// [WalletTransactionsCubit] لمعرفة ما إذا بقيت صفحات أخرى قابلة للجلب.
class WalletTransactionsPage extends Equatable {
  const WalletTransactionsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<WalletTransaction> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  @override
  List<Object?> get props => [items, total, page, limit];
}
