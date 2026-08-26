import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/refresh_on_tab_visible.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_dashboard.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// شاشة الرئيسية: شريط إعلانات دوّار، بطاقة حالة السكن، الوصول السريع،
/// وآخر النشاطات — مطابقة للشاشتين 2 و16 (المحدّثة) من التصميم المعتمد.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(HomeRepositoryImpl())..fetchDashboard(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return RefreshOnTabVisible(
      onVisible: () => context.read<HomeCubit>().fetchDashboard(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return switch (state) {
              HomeInitial() || HomeLoading() => const _HomeSkeleton(),
              HomeFailure(:final failure) => _HomeErrorView(
                message: failure.message,
                onRetry: () => context.read<HomeCubit>().fetchDashboard(),
              ),
              HomeSuccess(:final dashboard) => _HomeContent(
                dashboard: dashboard,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _HomeHeader(),
        Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: Center(
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
          ),
        ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().fetchDashboard(),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HomeHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList.list(
              children: [
                _AnnouncementsSection(announcements: dashboard.announcements),
                const SizedBox(height: 20),
                _HousingStatusCard(status: dashboard.housingStatus),
                const SizedBox(height: 24),
                Text(
                  'الوصول السريع',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const _QuickAccessGrid(),
                const SizedBox(height: 24),
                Text(
                  'آخر النشاطات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _ActivityList(activities: dashboard.activities),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserSessionCubit>().state;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(AppRadius.xxl),
        bottomRight: Radius.circular(AppRadius.xxl),
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Row(
              children: [
                ProfileAvatar(
                  avatarUrl: user?.avatarUrl,
                  radius: 26,
                  backgroundColor: AppColors.white.withValues(alpha: 0.18),
                  iconColor: AppColors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.fullName ?? '...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  const _AnnouncementsSection({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'آخر الإعلانات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => context.pushNamed(AppRoutes.allAds),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _AnnouncementsSwiper(announcements: announcements),
      ],
    );
  }
}

class _AnnouncementsSwiper extends StatefulWidget {
  const _AnnouncementsSwiper({required this.announcements});

  final List<Announcement> announcements;

  @override
  State<_AnnouncementsSwiper> createState() => _AnnouncementsSwiperState();
}

class _AnnouncementsSwiperState extends State<_AnnouncementsSwiper> {
  // عدد "صفحات وهمية" كبير جداً لكل دورة كاملة عبر الإعلانات، حتى يبقى
  // التقليب التلقائي يتحرك بنفس الاتجاه دائماً (يساراً) عند إكمال دورة
  // والعودة للإعلان الأول، بدل ما يقفز animateToPage للخلف بصرياً (من
  // آخر إعلان مباشرة لأول واحد) لأن الفهرس الفعلي كان يرجع لـ 0 بدل
  // الاستمرار بالتزايد.
  static const _cyclesBeforeWrap = 5000;

  late final PageController _controller = PageController(
    viewportFraction: 0.86,
    initialPage: _cyclesBeforeWrap * widget.announcements.length,
  );
  late int _virtualPage = _cyclesBeforeWrap * widget.announcements.length;
  Timer? _autoPlayTimer;

  int get _currentPage =>
      widget.announcements.isEmpty
          ? 0
          : _virtualPage % widget.announcements.length;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _AnnouncementsSwiper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة التشغيل عند تغيّر عدد الإعلانات (مثلاً بعد سحب-للتحديث)، أهم
    // شي حتى يتوقف المؤقّت لو صار في إعلان واحد بس بعد ما كان أكثر.
    if (oldWidget.announcements.length != widget.announcements.length) {
      _startAutoPlay();
    }
  }

  /// تقليب تلقائي بين الإعلانات كل 3 ثوانٍ، بالترتيب، ويرجع للأول بعد
  /// الأخير — بلا داعٍ لو كان في إعلان واحد بس.
  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.announcements.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        _virtualPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _controller,
            itemCount: _cyclesBeforeWrap * 2 * widget.announcements.length,
            onPageChanged: (index) => setState(() => _virtualPage = index),
            itemBuilder: (context, index) {
              final announcement =
                  widget.announcements[index % widget.announcements.length];
              final isWarning = announcement.colorVariant == 'warning';
              final imageUrl = announcement.imageUrl;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap:
                      () => context.pushNamed(
                        AppRoutes.adDetails,
                        pathParameters: {'id': announcement.id},
                        extra: announcement,
                      ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            isWarning
                                ? AppColors.warningGradient
                                : AppColors.accentGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (isWarning
                                    ? AppColors.amber500
                                    : AppColors.violet500)
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const SizedBox.shrink(),
                              errorWidget:
                                  (context, url, error) =>
                                      const SizedBox.shrink(),
                            ),
                          if (imageUrl != null)
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                  stops: [0.4, 1],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  announcement.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  announcement.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.announcements.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HousingStatusCard extends StatelessWidget {
  const _HousingStatusCard({required this.status});

  final HousingStatus status;

  static const _labels = {
    'pending': 'قيد المراجعة',
    'accepted': 'مقبول',
    'rejected': 'مرفوض',
  };

  static const _icons = {
    'pending': Icons.hourglass_top_rounded,
    'accepted': Icons.check_circle_outline_rounded,
    'rejected': Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.statusColor(status.status);
    final label = _labels[status.status] ?? 'لا يوجد طلب';
    final icon = _icons[status.status] ?? Icons.info_outline_rounded;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      showBorder: true,
      onTap: () => context.goNamed(AppRoutes.housingRequest),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'حالة السكن',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (status.status == 'accepted') ...[
            const SizedBox(height: 18),
            Row(
              children: [
                _StatusValue(
                  label: 'المبنى / الوحدة',
                  value: status.buildingUnit ?? '—',
                ),
                const Spacer(),
                _StatusValue(
                  label: 'رقم الغرفة',
                  value: status.roomNumber ?? '—',
                  alignEnd: true,
                ),
              ],
            ),
            if (status.daysUntilPayment != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningBackground,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.warningText,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${status.daysUntilPayment} يوم متبقي على الدفع',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.warningText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            status.paymentReference ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: AppColors.secondaryDark,
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 10),
            Text(
              status.status == 'pending'
                  ? 'طلبك قيد المراجعة حالياً، سيتم إشعارك فور صدور القرار.'
                  : status.status == 'rejected'
                  ? 'للأسف تم رفض طلبك. اضغط لمزيد من التفاصيل أو تقديم طلب جديد.'
                  : 'لم تقدّم طلب سكن بعد. اضغط هنا للبدء.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusValue extends StatelessWidget {
  const _StatusValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.people_outline_rounded,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successBackground,
                  label: 'إنشاء / الانضمام لغروب',
                  onTap: () => context.goNamed(AppRoutes.groups),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.apartment_outlined,
                  iconColor: AppColors.primaryDark,
                  iconBackground: AppColors.primarySubtle,
                  label: 'تقديم طلب سكن',
                  onTap: () => context.goNamed(AppRoutes.housingRequest),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.outlined_flag_rounded,
                  iconColor: AppColors.accentDark,
                  iconBackground: AppColors.accentSubtle,
                  label: 'شكوى أو اقتراح',
                  onTap: () => context.pushNamed(AppRoutes.complaints),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAccessCard(
                  icon: Icons.build_outlined,
                  iconColor: AppColors.secondaryDark,
                  iconBackground: AppColors.secondaryLight,
                  label: 'طلب خدمة',
                  onTap: () => context.pushNamed(AppRoutes.maintenanceList),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});

  final List<ActivityLogItem> activities;

  static Map<String, Color> get _colors => {
    'success': AppColors.success,
    'celebration': AppColors.success,
    'error': AppColors.error,
    'info': AppColors.primary,
    'neutral': AppColors.textDisabled,
  };

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return CustomCard(
        child: Center(
          child: Text(
            'لا توجد نشاطات حديثة',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          _colors[activities[i].colorKey] ??
                          AppColors.textDisabled,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activities[i].text,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activities[i].time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
