import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../domain/entities/complaint.dart';

/// شاشة تفاصيل شكوى/اقتراح: عرض الرسالة الأصلية للطالب ورد الإدارة (إن
/// وُجد) على شكل خيط محادثة — مطابقة لنموذج "تفاصيل" في الشاشة 6 من
/// التصميم المعتمد.
class ComplaintDetailScreen extends StatelessWidget {
  const ComplaintDetailScreen({super.key, required this.complaint});

  final Complaint complaint;

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 14) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: 'تفاصيل: ${complaint.title}',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
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
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 48),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatTime(complaint.createdAt),
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
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
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
                            _formatTime(complaint.adminReply!.createdAt),
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
            ),
          ),
        ],
      ),
    );
  }
}
