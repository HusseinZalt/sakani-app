import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../housing_request/data/repositories/housing_request_repository_impl.dart';
import '../../../housing_request/domain/entities/housing_request.dart';

/// شاشة "المستندات": عرض المستندات المرتبطة بحساب المستخدم — الهوية
/// الوطنية المرفقة عند التسجيل، والمستندات الداعمة المرفقة مع طلب السكن
/// (إن وُجد).
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = true;
  HousingRequest? _housingRequest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await HousingRequestRepositoryImpl().fetchMyRequest();
    if (!mounted) return;
    setState(() {
      _housingRequest = result.dataOrNull;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserSessionCubit>().state;
    final documents = _housingRequest?.documents ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(title: 'المستندات', onBack: () => context.pop()),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          'مستندات الحساب',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildIdDocumentTile(theme, user?.verificationStatus),
                        const SizedBox(height: 24),
                        Text(
                          'مستندات طلب السكن',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (documents.isEmpty)
                          CustomCard(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'لا توجد مستندات مرفقة بطلب سكن حتى الآن.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          for (final document in documents) ...[
                            _DocumentTile(
                              icon: Icons.description_outlined,
                              title: document.name,
                              subtitle: 'مرفق بطلب السكن',
                              verified: true,
                            ),
                            const SizedBox(height: 8),
                          ],
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  /// حالة الهوية الوطنية تُبنى من [AuthUser.verificationStatus] (مراجعة
  /// الإدارة للمستندات)، وليس من وجود حقل `nationalId` — لأن خدمة
  /// المصادقة لا تُعيد هذا الحقل عبر `/login` أو `/me` رغم اشتراطها صورة
  /// الهوية كحقل إجباري عند التسجيل، فوجودها مؤكَّد دائماً لأي حساب فعلي.
  Widget _buildIdDocumentTile(ThemeData theme, String? verificationStatus) {
    final (
      String subtitle,
      Color color,
      Color background,
      IconData icon,
    ) = switch (verificationStatus) {
      'approved' => (
        'تمت الموافقة عليها من الإدارة',
        AppColors.success,
        AppColors.successBackground,
        Icons.check_circle_rounded,
      ),
      'rejected' => (
        'تم رفضها، يرجى التواصل مع إدارة السكن',
        AppColors.error,
        AppColors.errorBackground,
        Icons.error_rounded,
      ),
      'pending' => (
        'قيد المراجعة من الإدارة',
        AppColors.secondaryDark,
        AppColors.warningBackground,
        Icons.hourglass_top_rounded,
      ),
      _ => (
        'تم إرفاقها عند التسجيل',
        AppColors.textHint,
        AppColors.surfaceVariant,
        Icons.badge_outlined,
      ),
    };

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صورة الهوية الوطنية',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.verified,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  verified
                      ? AppColors.successBackground
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: verified ? AppColors.success : AppColors.textHint,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
}
