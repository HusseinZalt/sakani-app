import 'package:equatable/equatable.dart';

/// محافظة — تُستخدم لملء قائمة اختيار المحافظة بنموذج تقديم طلب السكن.
class Governorate extends Equatable {
  const Governorate({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
