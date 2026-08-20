import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/ads_repository_impl.dart';
import '../../domain/entities/home_dashboard.dart';

/// شاشة تفاصيل إعلان واحد — يُصل إليها بالضغط على الإعلان من شريط
/// الرئيسية (يمرَّر جاهزاً عبر [announcement]، بلا حاجة لجلب إضافي) أو
/// من إشعار مرتبط (لا يحمل سوى [adId] فيُجلب الإعلان الكامل عبره).
class AdDetailScreen extends StatefulWidget {
  const AdDetailScreen({super.key, required this.adId, this.announcement});

  final String adId;
  final Announcement? announcement;

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  late Announcement? _announcement = widget.announcement;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_announcement == null) _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await AdsRepositoryImpl().fetchAdById(widget.adId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _announcement = result.dataOrNull;
      _errorMessage =
          result.dataOrNull == null ? result.failureOrNull!.message : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcement = _announcement;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: announcement?.title ?? 'الإعلان',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : announcement == null
                      ? _ErrorView(
                        message: _errorMessage ?? 'تعذّر تحميل الإعلان.',
                        onRetry: _fetch,
                      )
                      : _AdContent(announcement: announcement),
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

class _AdContent extends StatelessWidget {
  const _AdContent({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = announcement.colorVariant == 'warning';
    final imageUrl = announcement.imageUrl;
    final dateRange = _formatDateRange();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child:
                  imageUrl != null
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.surfaceVariant,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _ImagePlaceholder(isWarning: isWarning),
                      )
                      : _ImagePlaceholder(isWarning: isWarning),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            announcement.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (dateRange != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateRange,
                  // بلا هذا، السلسلة الرقمية (أرقام وشرطات فقط، بلا حرف
                  // عربي "قوي" الاتجاه) تُعاد ترتيبها بصرياً بالخطأ داخل
                  // سياق RTL المحيط (خوارزمية Unicode Bidi)، فيظهر تاريخ
                  // النهاية قبل البداية رغم صحة البيانات فعلياً.
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            announcement.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }

  String? _formatDateRange() {
    final start = announcement.startDate;
    final end = announcement.endDate;
    if (start == null && end == null) return null;

    final format = DateFormat('yyyy/MM/dd');
    if (start != null && end != null) {
      return '${format.format(start.toLocal())} — ${format.format(end.toLocal())}';
    }
    return format.format((start ?? end)!.toLocal());
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.isWarning});

  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isWarning ? AppColors.warningGradient : AppColors.accentGradient,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.campaign_outlined, size: 48, color: AppColors.white),
    );
  }
}
