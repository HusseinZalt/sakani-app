import 'package:equatable/equatable.dart';

/// طلب سكن جامعي قدّمه الطالب.
///
/// [requestType]: individual (طلب فردي) أو group (طلب كغروب كامل).
/// [roomType]: shared (غرفة مشتركة) أو private (غرفة فردية).
/// [preferredBuilding]: unit_a, unit_b, unit_c أو none (بدون تفضيل).
/// [status]: pending (قيد المراجعة)، accepted (مقبول)، rejected (مرفوض).
/// [groupCode]: كود الغروب عند [requestType] == group فقط.
/// [documentNames]: أسماء المستندات الداعمة المرفقة (سند الإقامة وغيره).
class HousingRequest extends Equatable {
  const HousingRequest({
    required this.id,
    required this.requestType,
    required this.roomType,
    required this.preferredBuilding,
    required this.status,
    required this.createdAt,
    this.groupCode,
    this.documentNames = const [],
    this.notes,
  });

  final String id;
  final String requestType;
  final String roomType;
  final String preferredBuilding;
  final String status;
  final DateTime createdAt;
  final String? groupCode;
  final List<String> documentNames;
  final String? notes;

  @override
  List<Object?> get props => [
    id,
    requestType,
    roomType,
    preferredBuilding,
    status,
    createdAt,
    groupCode,
    documentNames,
    notes,
  ];
}
