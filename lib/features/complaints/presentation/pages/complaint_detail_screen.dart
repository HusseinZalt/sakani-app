import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/complaints_repository_impl.dart';
import '../../domain/entities/complaint.dart';

/// شاشة تفاصيل شكوى/اقتراح: عرض الرسالة الأصلية للطالب ورد الإدارة (إن
/// وُجد) على شكل خيط محادثة — مطابقة لنموذج "تفاصيل" في الشاشة 6 من
/// التصميم المعتمد.
///
/// يُمرَّر [complaint] جاهزاً عند القدوم من شاشة القائمة (لا حاجة لجلب
/// إضافي)، أما عند الوصول المباشر (رابط/إشعار بدون حالة تنقّل، مثل تحديث
/// المتصفح أو فتح رابط عميق) فتُجلب البيانات عبر [complaintId] بدلاً من
/// الافتراض الخاطئ أن `extra` سيكون متوفراً دائماً.
class ComplaintDetailScreen extends StatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    this.complaint,
  });

  final String complaintId;
  final Complaint? complaint;

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late Complaint? _complaint = widget.complaint;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_complaint == null) _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await ComplaintsRepositoryImpl().fetchComplaintById(
      widget.complaintId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _complaint = result.dataOrNull;
      _errorMessage =
          result.dataOrNull == null ? result.failureOrNull!.message : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;

    return Scaffold(
      backgroundColor: AppColors.background,
      // top: false لأن GradientHeader يتولى أعلى الشاشة بنفسه؛ الشريط
      // السفلي (أزرار/حركات نظام أندرويد) يحتاج هذا الحد الآمن هنا لأن
      // هذه الشاشة تُدفَع فوق الجذر (rootNavigatorKey) بدون شريط تنقل
      // سفلي يمتص المساحة تلقائياً كما بشاشات التبويبات الخمس.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title:
                  complaint != null ? 'تفاصيل: ${complaint.title}' : 'تفاصيل',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : complaint == null
                      ? _ErrorView(
                        message: _errorMessage ?? 'تعذّر تحميل الشكوى.',
                        onRetry: _fetch,
                      )
                      : _ComplaintThread(complaint: complaint),
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

class _ComplaintThread extends StatelessWidget {
  const _ComplaintThread({required this.complaint});

  final Complaint complaint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CustomCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Text(
                      complaint.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (complaint.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: complaint.imageUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.network(
                          complaint.imageUrls[i],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Container(
                                width: 72,
                                height: 72,
                                color: AppColors.surfaceVariant,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 48),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatRelativeTime(complaint.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
            if (complaint.adminReply != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.successBackground,
                    child: const Icon(
                      Icons.verified_outlined,
                      color: AppColors.success,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successBackground,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رد الإدارة',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.successText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint.adminReply!.text,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRelativeTime(complaint.adminReply!.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                'لم يتم الرد على هذا الطلب بعد.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
