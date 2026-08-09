import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// وصف تصنيف طلب الخدمة: التسمية العربية، الأيقونة، ولون الخلفية/الأيقونة،
/// مطابقة تماماً لشبكة التصنيفات في التصميم المعتمد.
class ServiceCategoryInfo {
  const ServiceCategoryInfo({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color background;
}

/// تسميات وتصنيفات طلبات الخدمة بالعربية، مشتركة بين شاشتي القائمة
/// والإضافة لتفادي تكرارها.
class MaintenanceLabels {
  const MaintenanceLabels._();

  /// تصنيفات طلب الخدمة بنفس ترتيب التصميم المعتمد.
  static Map<String, ServiceCategoryInfo> get categories => {
    'internet': ServiceCategoryInfo(
      label: 'إنترنت',
      icon: Icons.wifi_rounded,
      iconColor: AppColors.success,
      background: AppColors.successBackground,
    ),
    'plumbing': ServiceCategoryInfo(
      label: 'سباكة',
      icon: Icons.water_drop_outlined,
      iconColor: AppColors.primaryDark,
      background: AppColors.primarySubtle,
    ),
    'electrical': ServiceCategoryInfo(
      label: 'كهرباء',
      icon: Icons.bolt_rounded,
      iconColor: AppColors.secondaryDark,
      background: AppColors.secondaryLight,
    ),
    'other': ServiceCategoryInfo(
      label: 'أخرى',
      icon: Icons.build_outlined,
      iconColor: AppColors.gray600,
      background: AppColors.gray200,
    ),
    'cleaning': ServiceCategoryInfo(
      label: 'تنظيف',
      icon: Icons.cleaning_services_outlined,
      iconColor: AppColors.success,
      background: AppColors.successBackground,
    ),
    'keys': ServiceCategoryInfo(
      label: 'مفاتيح',
      icon: Icons.vpn_key_outlined,
      iconColor: AppColors.accentDark,
      background: AppColors.accentSubtle,
    ),
  };

  /// تسميات حالة الطلب.
  static const Map<String, String> statuses = {
    'pending': 'قيد الانتظار',
    'inProgress': 'قيد التنفيذ',
    'completed': 'مكتملة',
  };

  static String categoryLabel(String key) => categories[key]?.label ?? key;

  static String statusLabel(String key) => statuses[key] ?? key;
}
