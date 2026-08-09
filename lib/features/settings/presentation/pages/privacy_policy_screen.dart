import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/gradient_header.dart';

/// شاشة سياسة الخصوصية.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    (
      'البيانات التي نجمعها',
      'نقوم بجمع بياناتك الشخصية الأساسية عند إنشاء الحساب (الاسم، البريد الإلكتروني، رقم الجوال)، بيانات التحقق الجامعي (الرقم الجامعي، صورة الهوية الوطنية)، وبيانات الاستخدام المتعلقة بطلبات السكن والصيانة والشكاوى التي تقدّمها عبر التطبيق.',
    ),
    (
      'كيفية استخدام بياناتك',
      'تُستخدم بياناتك حصراً لتقديم خدمات المدينة الجامعية: معالجة طلبات السكن، التواصل بشأن حالة طلباتك، وتحسين جودة الخدمات المقدَّمة لك. لا تُستخدم بياناتك لأي غرض تسويقي دون موافقتك الصريحة.',
    ),
    (
      'مشاركة البيانات',
      'لا تتم مشاركة بياناتك الشخصية مع أي جهة خارجية، باستثناء الجهات الإدارية داخل الجامعة المسؤولة عن السكن الجامعي، وفقط بالقدر اللازم لمعالجة طلباتك.',
    ),
    (
      'أمان البيانات',
      'نتخذ إجراءات تقنية وتنظيمية معقولة لحماية بياناتك من الوصول غير المصرح به أو الفقدان أو سوء الاستخدام، بما في ذلك تشفير الاتصال وتقييد الوصول للبيانات على الموظفين المخوّلين فقط.',
    ),
    (
      'حقوقك',
      'يحق لك في أي وقت طلب الاطلاع على بياناتك المخزَّنة لدينا، تصحيحها، أو طلب حذف حسابك، من خلال التواصل مع إدارة السكن الجامعي.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(title: 'سياسة الخصوصية', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'آخر تحديث: 2026',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                for (final section in _sections) ...[
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.$1,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.$2,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
