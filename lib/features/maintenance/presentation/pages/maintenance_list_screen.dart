import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/entities/maintenance_request.dart';
import '../cubit/maintenance_list_cubit.dart';
import '../cubit/maintenance_list_state.dart';
import '../maintenance_labels.dart';

/// شاشة طلب خدمة: زر طلب جديد، شبكة تصنيفات الخدمات، وقائمة "طلباتي
/// السابقة" — مطابقة للشاشة 5 من التصميم المعتمد.
class MaintenanceListScreen extends StatelessWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              MaintenanceListCubit(MaintenanceRepositoryImpl())
                ..fetchRequests(),
      child: const _MaintenanceListView(),
    );
  }
}

class _MaintenanceListView extends StatelessWidget {
  const _MaintenanceListView();

  Future<void> _openCreateScreen(BuildContext context) async {
    final created = await context.pushNamed<bool>(AppRoutes.createMaintenance);
    if (created == true && context.mounted) {
      context.read<MaintenanceListCubit>().fetchRequests();
    }
  }

  Future<void> _handleCancel(
    BuildContext context,
    MaintenanceRequest request,
  ) async {
    final cubit = context.read<MaintenanceListCubit>();
    final result = await cubit.cancelRequest(request.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess
                ? 'تم إلغاء الطلب بنجاح.'
                : result.failureOrNull!.message,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(
            title: 'طلب خدمة',
            subtitle: 'اطلب خدمات الصيانة والدعم',
          ),
          Expanded(
            child: BlocBuilder<MaintenanceListCubit, MaintenanceListState>(
              builder: (context, state) {
                return switch (state) {
                  MaintenanceListInitial() || MaintenanceListLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  MaintenanceListFailure(:final failure) => _ErrorView(
                    message: failure.message,
                    onRetry:
                        () =>
                            context
                                .read<MaintenanceListCubit>()
                                .fetchRequests(),
                  ),
                  MaintenanceListSuccess(:final requests) => RefreshIndicator(
                    onRefresh:
                        () =>
                            context
                                .read<MaintenanceListCubit>()
                                .fetchRequests(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        CustomButton(
                          label: 'طلب خدمة جديدة',
                          icon: Icons.add_rounded,
                          onPressed: () => _openCreateScreen(context),
                        ),
                        const SizedBox(height: 20),
                        const _CategoryGrid(),
                        const SizedBox(height: 24),
                        Text(
                          'طلباتي السابقة',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        if (requests.isEmpty)
                          const _EmptyView()
                        else
                          for (final request in requests) ...[
                            _RequestCard(
                              request: request,
                              onCancel:
                                  request.status == 'completed'
                                      ? null
                                      : () => _handleCancel(context, request),
                            ),
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children:
          MaintenanceLabels.categories.entries.map((entry) {
            final info = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap:
                  () => context
                      .pushNamed<bool>(
                        AppRoutes.createMaintenance,
                        extra: entry.key,
                      )
                      .then((created) {
                        if (created == true && context.mounted) {
                          context.read<MaintenanceListCubit>().fetchRequests();
                        }
                      }),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: info.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(info.icon, color: info.iconColor, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onCancel});

  final MaintenanceRequest request;
  final VoidCallback? onCancel;

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return 'منذ ${diff.inDays} ${diff.inDays == 1 ? 'يوم' : 'أيام'}';
    }
    if (diff.inHours >= 1) {
      return 'منذ ${diff.inHours} ${diff.inHours == 1 ? 'ساعة' : 'ساعات'}';
    }
    return 'منذ قليل';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = AppColors.statusColor(request.status);
    final categoryInfo = MaintenanceLabels.categories[request.category];

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (categoryInfo != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryInfo.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    categoryInfo.icon,
                    color: categoryInfo.iconColor,
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
                  MaintenanceLabels.statusLabel(request.status),
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
            request.description,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            _formatTime(request.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                label: const Text(
                  'إلغاء الطلب',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.build_outlined, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'لا توجد طلبات خدمة حتى الآن',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
