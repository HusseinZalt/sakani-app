import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// نوع المستند حسب `DocumentType` بخدمة السكن الحقيقية — القيم الرقمية
/// مؤكَّدة عبر Swagger الخدمة (`personalPhoto`(0) ... `residencyProof`(6)).
enum HousingDocumentType {
  personalPhoto(0, 'الصورة الشخصية', mandatory: true),
  nationalIdFront(1, 'الهوية الوطنية (الوجه)', mandatory: true),
  nationalIdBack(2, 'الهوية الوطنية (الظهر)', mandatory: true),
  universityIdFront(3, 'الهوية الجامعية (الوجه)', mandatory: true),
  universityIdBack(4, 'الهوية الجامعية (الظهر)', mandatory: true),
  departureReceipt(5, 'إيصال المغادرة', mandatory: false),
  residencyProof(6, 'سند الإقامة', mandatory: false);

  const HousingDocumentType(
    this.apiValue,
    this.label, {
    required this.mandatory,
  });

  final int apiValue;
  final String label;
  final bool mandatory;

  static HousingDocumentType fromApiValue(int value) {
    return HousingDocumentType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => HousingDocumentType.residencyProof,
    );
  }
}

/// حالة مراجعة الإدارة لمستند واحد ضمن طلب السكن.
enum DocumentReviewStatus {
  pending(0, 'قيد المراجعة'),
  approved(1, 'مقبول'),
  rejected(2, 'مرفوض');

  const DocumentReviewStatus(this.apiValue, this.label);

  final int apiValue;
  final String label;

  static DocumentReviewStatus fromApiValue(int value) {
    return DocumentReviewStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => DocumentReviewStatus.pending,
    );
  }
}

/// مستند داعم مرفق بطلب السكن.
///
/// [bytes] محتوى الملف محلياً — متوفر فقط عند اختياره حديثاً من الجهاز
/// (قبل الإرسال، أو عند استبداله لطلب `NeedsRevision`)، بينما [url] هو
/// رابط الملف المرفوع فعلياً كما تُرجعه الخدمة بعد الإرسال.
class HousingDocument extends Equatable {
  const HousingDocument({
    required this.type,
    this.bytes,
    this.fileName,
    this.id,
    this.url,
    this.reviewStatus,
    this.reviewNotes,
  });

  final HousingDocumentType type;
  final Uint8List? bytes;
  final String? fileName;

  /// معرّف المستند بالخادم — متوفر فقط للمستندات المُرسَلة فعلياً.
  final int? id;
  final String? url;
  final DocumentReviewStatus? reviewStatus;
  final String? reviewNotes;

  @override
  List<Object?> get props => [
    type,
    bytes,
    fileName,
    id,
    url,
    reviewStatus,
    reviewNotes,
  ];
}
