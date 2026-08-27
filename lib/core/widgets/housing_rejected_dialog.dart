import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// يعرض نافذة "تم رفض طلب سكنك" بزرَّي إلغاء/إرسال طلب جديد — تُستخدم
/// بمكانين: عند فتح التطبيق وآخر طلب معروف مرفوض (الرئيسية)، وعند وصول
/// إشعار حي بالرفض والتطبيق مفتوح (فوق أي شاشة، `PushNotificationService`).
/// لا يُغلَق بالضغط خارجه عمداً — قرار يستحق اختياراً صريحاً من الطالب.
Future<void> showHousingRejectedDialog(
  BuildContext context, {
  String? reason,
  required VoidCallback onCancel,
  required VoidCallback onResubmit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('تم رفض طلب السكن'),
          content: Text(
            reason != null && reason.isNotEmpty
                ? 'تم رفض طلب السكن الخاص بك:\n$reason\n\nيمكنك تقديم طلب جديد إذا رغبت.'
                : 'تم رفض طلب السكن الخاص بك. يمكنك تقديم طلب جديد إذا رغبت.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onCancel();
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onResubmit();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('إرسال طلب جديد'),
            ),
          ],
        ),
  );
}
