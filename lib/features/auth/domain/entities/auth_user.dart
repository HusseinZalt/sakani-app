import 'package:equatable/equatable.dart';

/// الكيان (Entity) الذي يمثل المستخدم المصادق عليه ضمن طبقة الـ Domain.
///
/// لا يحتوي على أي منطق تحويل JSON، فهذا من مسؤولية النموذج (Model) في
/// طبقة الـ Data. يبقى هذا الكيان مستقلاً تماماً عن مصدر البيانات
/// (سواء كانت وهمية حالياً أو من API حقيقي مستقبلاً).
///
/// هذا الكيان هو المصدر الوحيد لبيانات "المستخدم الحالي" عبر التطبيق —
/// يُخزَّن داخل `UserSessionCubit` عند نجاح تسجيل الدخول/التسجيل، وتقرأ
/// منه كل الشاشات التي تعرض بيانات المستخدم (الرئيسية، الملف الشخصي...)
/// بدل قراءة بيانات وهمية منفصلة في كل شاشة.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.university,
    this.studentId,
    this.college,
    this.city,
    this.nationalId,
    this.isVerified = true,
    this.role,
    this.verificationStatus,
    this.gender,
    this.notificationsEnabled = true,
    this.balance = 0,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? university;
  final String? studentId;
  final String? college;
  final String? city;
  final String? nationalId;

  /// 'male' أو 'female' كما تُرجعها خدمة المصادقة — تُستخدم لاستهداف
  /// الإعلانات حسب الجنس (`TargetGender` بخدمة الإعلانات).
  final String? gender;

  /// هل أكمل المستخدم تأكيد بريده الإلكتروني عبر رمز الـ OTP بعد التسجيل.
  final bool isVerified;

  /// دور المستخدم (student, admin, super_admin).
  final String? role;

  /// حالة مراجعة الإدارة لمستندات الهوية (pending, approved, rejected) —
  /// منفصلة تماماً عن [isVerified] ولا تمنع تسجيل الدخول.
  final String? verificationStatus;

  /// تفضيل شخصي على مستوى الحساب (خدمة المصادقة): يوقف إرسال إشعارات
  /// الدفع (Push) لهذا المستخدم بالكامل من جهة الخادم — منفصل تماماً عن
  /// تفضيلات فئات الإشعارات المحلية (`NotificationPreferences`) وعن رمز
  /// الجهاز (FCM)، الذي يستمر تسجيله بشكل طبيعي بغض النظر عن هذه القيمة.
  final bool notificationsEnabled;

  /// رصيد المحفظة الحالي (خدمة المصادقة، راجع `wallet_repository.dart`) —
  /// يصل جاهزاً ضمن استجابات تسجيل الدخول/بيانات المستخدم دون الحاجة لأي
  /// نداء API منفصل لعرضه، ويُحدَّث محلياً فقط بعد نجاح شحن رصيد جديد
  /// (راجع [WalletRedeemCubit]) دون إعادة تسجيل الدخول.
  final double balance;

  /// نسخة معدّلة من المستخدم، تُستخدم عند حفظ تعديلات الملف الشخصي.
  AuthUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? university,
    String? studentId,
    String? college,
    String? city,
    String? nationalId,
    bool? isVerified,
    String? role,
    String? verificationStatus,
    String? gender,
    bool? notificationsEnabled,
    double? balance,
  }) {
    return AuthUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      university: university ?? this.university,
      studentId: studentId ?? this.studentId,
      college: college ?? this.college,
      city: city ?? this.city,
      nationalId: nationalId ?? this.nationalId,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      gender: gender ?? this.gender,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      balance: balance ?? this.balance,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    avatarUrl,
    university,
    studentId,
    college,
    city,
    nationalId,
    gender,
    isVerified,
    role,
    notificationsEnabled,
    verificationStatus,
    balance,
  ];
}
