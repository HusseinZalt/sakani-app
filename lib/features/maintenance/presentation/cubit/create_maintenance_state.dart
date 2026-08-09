import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../domain/entities/maintenance_request.dart';

/// حالة عملية إرسال طلب الصيانة الحالية.
enum CreateMaintenanceStatus {
  /// بانتظار إدخال المستخدم للبيانات.
  idle,

  /// جارٍ إرسال الطلب.
  submitting,

  /// تم إرسال الطلب بنجاح.
  success,

  /// فشل إرسال الطلب.
  failure,
}

/// حالة شاشة إضافة طلب صيانة جديد، تجمع بين حالة الإرسال وحالة الصورة
/// المُرفقة معاً لأن كلتيهما تتغيران بشكل مستقل أثناء تعبئة النموذج.
class CreateMaintenanceState extends Equatable {
  const CreateMaintenanceState({
    this.status = CreateMaintenanceStatus.idle,
    this.pickedImageBytes,
    this.pickedImageName,
    this.errorMessage,
    this.createdRequest,
  });

  final CreateMaintenanceStatus status;

  /// بايتات الصورة المُختارة، تُستخدم لعرض معاينة فورية عبر [Image.memory]
  /// بطريقة تعمل على جميع المنصات (بما فيها الويب) دون الحاجة لـ dart:io.
  final Uint8List? pickedImageBytes;

  final String? pickedImageName;
  final String? errorMessage;
  final MaintenanceRequest? createdRequest;

  bool get hasImage => pickedImageBytes != null;

  CreateMaintenanceState copyWith({
    CreateMaintenanceStatus? status,
    Uint8List? pickedImageBytes,
    String? pickedImageName,
    bool clearImage = false,
    String? errorMessage,
    bool clearError = false,
    MaintenanceRequest? createdRequest,
  }) {
    return CreateMaintenanceState(
      status: status ?? this.status,
      pickedImageBytes:
          clearImage ? null : (pickedImageBytes ?? this.pickedImageBytes),
      pickedImageName:
          clearImage ? null : (pickedImageName ?? this.pickedImageName),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdRequest: createdRequest ?? this.createdRequest,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pickedImageBytes,
    pickedImageName,
    errorMessage,
    createdRequest,
  ];
}
