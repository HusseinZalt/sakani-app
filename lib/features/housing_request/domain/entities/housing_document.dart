import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// مستند داعم مرفق بطلب السكن (سند إقامة أو ما شابه).
///
/// [bytes] محتوى الملف محلياً — متوفر دائماً حالياً بما أن الرفع وهمي، لكنه
/// سيكون null لاحقاً عند القراءة من استجابة API حقيقية تُرجع رابط الملف
/// بعد رفعه فعلياً بدل بايتاته الخام.
class HousingDocument extends Equatable {
  const HousingDocument({required this.name, this.bytes, this.url});

  final String name;
  final Uint8List? bytes;
  final String? url;

  @override
  List<Object?> get props => [name, bytes, url];
}
