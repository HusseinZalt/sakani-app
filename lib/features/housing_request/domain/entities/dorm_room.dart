import 'package:equatable/equatable.dart';

/// غرفة فعلية ضمن مبنى — لملء قائمة اختيار "رقم الغرفة" بقسم "سكنت
/// سابقاً"، بعد فلترتها حسب الطابق المختار (`GET
/// /api/buildings/{buildingId}/rooms`، خدمة السكن).
class DormRoom extends Equatable {
  const DormRoom({
    required this.id,
    required this.roomNumber,
    required this.floor,
  });

  final int id;
  final String roomNumber;
  final int floor;

  @override
  List<Object?> get props => [id, roomNumber, floor];
}
