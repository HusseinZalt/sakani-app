import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// يعرض حوار تأكيد قبل تنفيذ إجراء حسّاس (تسجيل خروج، حذف...)، ويُرجع
/// `true` فقط إذا اختار المستخدم زر التأكيد صراحةً.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}
