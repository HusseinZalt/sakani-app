import 'dart:typed_data';

/// البيانات المجمّعة من نموذج إنشاء الحساب على خطوتين، تُمرَّر دفعة واحدة
/// إلى [AuthRepository.register] عند إكمال الخطوة الثانية.
///
/// الحقول والأنواع هنا مطابقة تماماً لعقد خدمة المصادقة الحقيقية
/// (`POST /api/auth/register`, multipart/form-data).
class RegisterData {
  const RegisterData({
    required this.firstName,
    required this.secondName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.gender,
    required this.universityIndex,
    required this.nationalId,
    required this.studyYear,
    required this.personalPhoto,
    required this.idFrontPhoto,
    required this.idBackPhoto,
    this.studentNumber,
    this.nationality,
    this.residence,
  });

  final String firstName;
  final String secondName;
  final String email;
  final String phoneNumber;
  final String password;

  /// 'male' أو 'female'.
  final String gender;

  /// فهرس الجامعة (0-8) حسب القائمة المعتمدة من خدمة المصادقة.
  final int universityIndex;

  final String nationalId;

  /// سنة الدراسة (1-6).
  final int studyYear;

  final Uint8List personalPhoto;
  final Uint8List idFrontPhoto;
  final Uint8List idBackPhoto;

  final String? studentNumber;
  final String? nationality;
  final String? residence;

  String get fullName => '$firstName $secondName';
}
