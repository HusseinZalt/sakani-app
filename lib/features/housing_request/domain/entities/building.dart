import 'package:equatable/equatable.dart';

/// مبنى سكني — لملء قائمة اختيار "المبنى" بقسم "سكنت سابقاً" بنموذج
/// تقديم طلب السكن (`GET /api/buildings`، خدمة السكن).
class Building extends Equatable {
  const Building({required this.id, required this.name, this.floorsCount});

  final int id;
  final String name;

  /// null إن لم يُسجَّل عدد الطوابق بعد من جهة الإدارة.
  final int? floorsCount;

  @override
  List<Object?> get props => [id, name, floorsCount];
}
