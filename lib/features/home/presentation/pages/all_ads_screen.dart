import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/ads_repository_impl.dart';
import '../../domain/entities/home_dashboard.dart';
import '../cubit/all_ads_cubit.dart';
import '../cubit/all_ads_state.dart';

/// شاشة "كل الإعلانات" — قائمة كاملة بكل الإعلانات النشطة (بانرات ونصوص
/// معاً)، بترتيب قابل للتبديل بين الأحدث والأقدم. يُصل إليها من السهم
/// أعلى شريط الإعلانات بالرئيسية.
class AllAdsScreen extends StatelessWidget {
  const AllAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AllAdsCubit(AdsRepositoryImpl())..fetchAds(),
      child: const _AllAdsView(),
    );
  }
}

class _AllAdsView extends StatelessWidget {
  const _AllAdsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            BlocBuilder<AllAdsCubit, AllAdsState>(
              builder: (context, state) {
                final newestFirst =
                    state is AllAdsSuccess ? state.newestFirst : true;
                return GradientHeader(
                  title: 'كل الإعلانات',
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing:
                      state is AllAdsSuccess
                          ? _SortToggleButton(
                            newestFirst: newestFirst,
                            onTap:
                                () =>
                                    context
                                        .read<AllAdsCubit>()
                                        .toggleSortOrder(),
                          )
                          : null,
                );
              },
            ),
            Expanded(
              child: BlocBuilder<AllAdsCubit, AllAdsState>(
                builder: (context, state) {
                  return switch (state) {
                    AllAdsInitial() ||
                    AllAdsLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    AllAdsFailure(:final failure) => _ErrorView(
                      message: failure.message,
                      onRetry: () => context.read<AllAdsCubit>().fetchAds(),
                    ),
                    AllAdsSuccess(:final sorted) =>
                      sorted.isEmpty
                          ? const _EmptyView()
                          : RefreshIndicator(
                            onRefresh:
                                () => context.read<AllAdsCubit>().fetchAds(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                32,
                              ),
                              itemCount: sorted.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 12),
                              itemBuilder:
                                  (context, index) =>
                                      _AdListTile(ad: sorted[index]),
                            ),
                          ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortToggleButton extends StatelessWidget {
  const _SortToggleButton({required this.newestFirst, required this.onTap});

  final bool newestFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              newestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: AppColors.white,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              newestFirst ? 'الأحدث' : 'الأقدم',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdListTile extends StatelessWidget {
  const _AdListTile({required this.ad});

  final Announcement ad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = ad.imageUrl;

    return CustomCard(
      padding: const EdgeInsets.all(12),
      onTap:
          () => context.pushNamed(
            AppRoutes.adDetails,
            pathParameters: {'id': ad.id},
            extra: ad,
          ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 64,
              height: 64,
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const _ThumbnailPlaceholder(),
                      )
                      : const _ThumbnailPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ad.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (ad.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    formatRelativeTime(ad.createdAt!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      alignment: Alignment.center,
      child: const Icon(
        Icons.campaign_outlined,
        size: 24,
        color: AppColors.white,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد إعلانات حالياً',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
            Text(message, textAlign: TextAlign.center),
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
