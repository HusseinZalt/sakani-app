import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_redeem_result.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../cubit/wallet_transactions_cubit.dart';
import '../cubit/wallet_transactions_state.dart';

/// شاشة المحفظة: الرصيد الحالي، زر شحن عبر مسح QR، وسجل العمليات
/// (شحن + دفع). يُصل إليها بالدفع (push) من شاشة الملف الشخصي.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              WalletTransactionsCubit(WalletRepositoryImpl())
                ..fetchTransactions(),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  Future<void> _openScanner(BuildContext context) async {
    final result = await context.pushNamed<WalletRedeemResult>(
      AppRoutes.walletScan,
    );
    if (result == null || !context.mounted) return;

    // تحديث الرصيد المعروض بكل مكان بالتطبيق فوراً (الملف الشخصي، هذه
    // الشاشة...) دون الحاجة لتسجيل دخول جديد أو نداء API إضافي — الخادم
    // يُرجع الرصيد الجديد جاهزاً ضمن استجابة الشحن نفسها.
    final sessionCubit = context.read<UserSessionCubit>();
    final user = sessionCubit.state;
    if (user != null) {
      sessionCubit.setUser(user.copyWith(balance: result.balance));
    }

    context.read<WalletTransactionsCubit>().fetchTransactions();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'تم شحن ${_formatAmount(result.amount)} بنجاح، رصيدك الآن ${_formatAmount(result.balance)}.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<UserSessionCubit>().state?.balance ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: 'المحفظة',
              subtitle: 'رصيدك وسجل عمليات الشحن والدفع',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh:
                    () => context.read<WalletTransactionsCubit>().fetchTransactions(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    _BalanceCard(
                      balance: balance,
                      onScanPressed: () => _openScanner(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'سجل العمليات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<WalletTransactionsCubit, WalletTransactionsState>(
                      builder: (context, state) {
                        return switch (state) {
                          WalletTransactionsInitial() ||
                          WalletTransactionsLoading() => const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          WalletTransactionsFailure(:final failure) => Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _ErrorView(
                              message: failure.message,
                              onRetry:
                                  () =>
                                      context
                                          .read<WalletTransactionsCubit>()
                                          .fetchTransactions(),
                            ),
                          ),
                          WalletTransactionsSuccess(
                            :final transactions,
                            :final hasMore,
                            :final isLoadingMore,
                          ) =>
                            transactions.isEmpty
                                ? const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: _EmptyTransactionsView(),
                                )
                                : Column(
                                  children: [
                                    CustomCard(
                                      padding: EdgeInsets.zero,
                                      child: Column(
                                        children: [
                                          for (
                                            var i = 0;
                                            i < transactions.length;
                                            i++
                                          ) ...[
                                            if (i > 0)
                                              const Divider(height: 1),
                                            _TransactionRow(
                                              transaction: transactions[i],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (hasMore) ...[
                                      const SizedBox(height: 12),
                                      Center(
                                        child:
                                            isLoadingMore
                                                ? const Padding(
                                                  padding: EdgeInsets.all(8),
                                                  child: SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.4,
                                                        ),
                                                  ),
                                                )
                                                : TextButton(
                                                  onPressed:
                                                      () =>
                                                          context
                                                              .read<
                                                                WalletTransactionsCubit
                                                              >()
                                                              .loadMore(),
                                                  child: const Text(
                                                    'تحميل المزيد',
                                                  ),
                                                ),
                                      ),
                                    ],
                                  ],
                                ),
                        };
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يعرض المبلغ بلا كسور إن كان عدداً صحيحاً، وإلا بمنزلتين عشريتين.
String _formatAmount(double amount) {
  return amount == amount.truncateToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onScanPressed});

  final double balance;
  final VoidCallback onScanPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'رصيد المحفظة',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(balance),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            label: 'مسح QR لشحن الرصيد',
            icon: Icons.qr_code_scanner_rounded,
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primaryDark,
            onPressed: onScanPressed,
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopup = transaction.isTopup;
    final color = isTopup ? AppColors.success : AppColors.error;
    final background = isTopup ? AppColors.successBackground : AppColors.errorBackground;
    final sign = isTopup ? '+' : '-';
    final title =
        isTopup ? 'شحن رصيد' : (transaction.reference ?? 'عملية دفع');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isTopup
                  ? Icons.add_circle_outline_rounded
                  : Icons.remove_circle_outline_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRelativeTime(transaction.createdAt.toLocal()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${_formatAmount(transaction.amount)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsView extends StatelessWidget {
  const _EmptyTransactionsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا توجد عمليات حتى الآن',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
