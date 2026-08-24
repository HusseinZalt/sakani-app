import 'package:equatable/equatable.dart';

/// تخصيص غرفة فعلي للطالب بعد قبول طلب السكن — منفصل عن قرار القبول
/// نفسه (`AdmissionDecision`)، إذ التخصيص إجراء إداري لاحق قد يتأخر عن
/// صدور القرار.
class Allocation extends Equatable {
  const Allocation({
    required this.roomNumber,
    required this.buildingName,
    required this.allocatedAt,
  });

  final String roomNumber;
  final String buildingName;
  final DateTime allocatedAt;

  @override
  List<Object?> get props => [roomNumber, buildingName, allocatedAt];
}
