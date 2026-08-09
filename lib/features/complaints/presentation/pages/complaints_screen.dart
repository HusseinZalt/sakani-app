import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/complaints_repository_impl.dart';
import '../../domain/entities/complaint.dart';
import '../cubit/complaints_list_cubit.dart';
import '../cubit/complaints_list_state.dart';
import '../complaints_labels.dart';

/// شاشة الشكاوى والاقتراحات: زر تقديم جديد وقائمة "السابقة" — مطابقة
/// للشاشة 6 من التصميم المعتمد.
class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              ComplaintsListCubit(ComplaintsRepositoryImpl())
                ..fetchComplaints(),
      child: const _ComplaintsView(),
    );
  }
}

class _ComplaintsView extends StatelessWidget {
  const _ComplaintsView();

  Future<void> _openCreateScreen(BuildContext context) async {
    final created = await context.pushNamed<bool>(AppRoutes.addComplaint);
    if (created == true && context.mounted) {
      context.read<ComplaintsListCubit>().fetchComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(
            title: 'الشكاوى والاقتراحات',
            subtitle: 'أرسل شكواك أو اقتراحك',
          ),
          Expanded(
            child: BlocBuilder<ComplaintsListCubit, ComplaintsListState>(
              builder: (context, state) {
                return switch (state) {
                  ComplaintsListInitial() || ComplaintsListLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  ComplaintsListFailure(:final failure) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(failure.message, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed:
                                () =>
                                    context
                                        .read<ComplaintsListCubit>()
                                        .fetchComplaints(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ComplaintsListSuccess(:final complaints) => RefreshIndicator(
                    onRefresh:
                        () =>
                            context
                                .read<ComplaintsListCubit>()
                                .fetchComplaints(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        CustomButton(
                          label: 'شكوى أو اقتراح جديد',
                          icon: Icons.outlined_flag_rounded,
                          onPressed: () => _openCreateScreen(context),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'السابقة',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (complaints.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'لا توجد شكاوى أو اقتراحات حتى الآن',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          for (final complaint in complaints) ...[
                            _ComplaintCard(complaint: complaint),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(complaint.status);
    final isSuggestion = complaint.type == 'suggestion';

    return CustomCard(
      padding: const EdgeInsets.all(16),
      onTap:
          () => context.pushNamed(
            AppRoutes.complaintDetails,
            pathParameters: {'id': complaint.id},
            extra: complaint,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isSuggestion
                          ? AppColors.infoBackground
                          : AppColors.accentSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isSuggestion
                      ? Icons.lightbulb_outline_rounded
                      : Icons.outlined_flag_rounded,
                  color:
                      isSuggestion
                          ? AppColors.primaryDark
                          : AppColors.accentDark,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  ComplaintsLabels.statusLabel(complaint.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            complaint.title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            complaint.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formatRelativeTime(complaint.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
