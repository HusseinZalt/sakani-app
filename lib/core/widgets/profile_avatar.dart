import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/avatar_image.dart';

/// صورة بروفايل دائرية موحّدة: تعرض [avatarUrl] الفعلية إن وُجدت، وإلا
/// أيقونة شخص عامة كحل احتياطي — نفس النمط المستخدم أصلاً بشاشة الملف
/// الشخصي، بس بشكل قابل لإعادة الاستخدام بأي مكان يعرض صورة المستخدم
/// (هيدر الرئيسية، أيقونة تبويب "الملف" بالشريط السفلي...).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primarySubtle,
      backgroundImage:
          avatarUrl != null ? avatarImageProvider(avatarUrl!) : null,
      child:
          avatarUrl == null
              ? Icon(
                Icons.person_outline_rounded,
                color: iconColor ?? AppColors.primaryDark,
                size: radius * 0.8,
              )
              : null,
    );
  }
}
