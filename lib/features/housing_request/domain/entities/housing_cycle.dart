import 'package:equatable/equatable.dart';

/// دورة سكن سنوية (مثل "2026-2027") — يُتحقَّق من وجود دورة `Open` قبل
/// عرض نموذج تقديم الطلب.
class HousingCycle extends Equatable {
  const HousingCycle({
    required this.id,
    required this.name,
    required this.isOpen,
  });

  final int id;
  final String name;
  final bool isOpen;

  @override
  List<Object?> get props => [id, name, isOpen];
}
