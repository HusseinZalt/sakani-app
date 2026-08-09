import 'package:equatable/equatable.dart';

/// إشعار يظهر في شاشة الإشعارات.
///
/// [colorKey]: success, accent, info, warning أو neutral — يحدد لون
/// ونوع الأيقونة المعروضة.
/// [type]: يحدد الشاشة التي يُنقل إليها المستخدم عند الضغط على الإشعار
/// (housing, complaint, group, maintenance, profile) أو null إن لم يكن
/// مرتبطاً بشاشة محددة.
/// [relatedId]: معرّف العنصر المرتبط (مثال: معرّف الشكوى) لفتح تفاصيله
/// مباشرة إن أمكن.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.timeLabel,
    required this.colorKey,
    required this.isUnread,
    this.type,
    this.relatedId,
  });

  final String id;

  /// معرّف صاحب الإشعار، لضمان عدم ظهور إشعارات مستخدم آخر عند تبديل
  /// الحساب على نفس الجهاز.
  final String userId;
  final String title;
  final DateTime createdAt;

  /// نص الوقت الجاهز للعرض (مثال: "منذ ساعتين"، "أمس، 6:40 م").
  final String timeLabel;

  final String colorKey;
  final bool isUnread;
  final String? type;
  final String? relatedId;

  AppNotification copyWith({bool? isUnread}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      createdAt: createdAt,
      timeLabel: timeLabel,
      colorKey: colorKey,
      isUnread: isUnread ?? this.isUnread,
      type: type,
      relatedId: relatedId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    createdAt,
    timeLabel,
    colorKey,
    isUnread,
    type,
    relatedId,
  ];
}
