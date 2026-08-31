import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/app_refresh_bus.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/dorm_room.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_cycle.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';
import '../../domain/repositories/housing_request_repository.dart';
import 'housing_request_state.dart';

/// يدير حالة شاشة طلب السكن عبر [HousingRequestRepository].
///
/// التسلسل عند التحميل: تحقّق من وجود دورة سكن مفتوحة أولاً — إن لم توجد
/// فلا معنى لعرض نموذج تقديم أصلاً (`HousingRequestCycleClosed`)، بغض
/// النظر إن كان للطالب طلب قديم أو لا.
class HousingRequestCubit extends Cubit<HousingRequestState> {
  HousingRequestCubit(this._repository)
    : super(const HousingRequestLoading()) {
    // راجع توثيق [AppRefreshBus] — إشعار قرار سكن حي بينما المستخدم واقف
    // على هذا التبويب يحدّثه فوراً بدل بقائه على "قيد المراجعة" القديمة.
    _refreshSubscription = AppRefreshBus.stream
        .where((topic) => topic == RefreshTopic.housingRequest)
        .listen((_) => fetchMyRequest());
  }

  final HousingRequestRepository _repository;
  StreamSubscription<RefreshTopic>? _refreshSubscription;

  /// عند استدعاء متكرر (مثلاً عند العودة للتبويب) وسبق أن ظهرت بيانات
  /// محدَّدة، لا نُظهر شاشة تحميل كاملة من جديد — نُبقي المحتوى الحالي
  /// ونستبدله بهدوء فقط عند وصول النتيجة الجديدة.
  Future<void> fetchMyRequest() async {
    final hasContent = switch (state) {
      HousingRequestCycleClosed() ||
      HousingRequestEmpty() ||
      HousingRequestSubmitted() => true,
      _ => false,
    };
    if (!hasContent) emit(const HousingRequestLoading());

    final cycleResult = await _repository.fetchCurrentCycle();
    final HousingCycle? cycle;
    switch (cycleResult) {
      case ApiSuccess<HousingCycle?>(:final data):
        cycle = data;
      case ApiFailureResult<HousingCycle?>(:final failure):
        emit(HousingRequestFailure(failure));
        return;
    }
    if (cycle == null || !cycle.isOpen) {
      emit(const HousingRequestCycleClosed());
      return;
    }

    final requestResult = await _repository.fetchMyRequest();
    switch (requestResult) {
      case ApiSuccess<HousingRequest?>(:final data):
        // نجلب المحافظات والأبنية دائماً هون (وليس فقط لما ما يكون في
        // طلب بعد): طلب موجود بحالة NeedsRevision لازم يعيد عرض نفس
        // نموذج التعديل بقائمة المحافظات معبّأة، وإلا يبقى منتقي
        // المحافظة فارغاً بدون أي خيارات — وهو تحديداً ما كان يحصل قبل
        // هذا الإصلاح.
        final governoratesResult = await _repository.fetchGovernorates();
        final governorates = switch (governoratesResult) {
          ApiSuccess<List<Governorate>>(:final data) => data,
          ApiFailureResult<List<Governorate>>() => const <Governorate>[],
        };
        final buildingsResult = await _repository.fetchBuildings();
        final buildings = switch (buildingsResult) {
          ApiSuccess<List<Building>>(:final data) => data,
          ApiFailureResult<List<Building>>() => const <Building>[],
        };
        final buildingsLoadFailed = buildingsResult is ApiFailureResult;
        if (data != null) {
          emit(
            HousingRequestSubmitted(
              data,
              governorates: governorates,
              buildings: buildings,
              buildingsLoadFailed: buildingsLoadFailed,
            ),
          );
          return;
        }
        emit(
          HousingRequestEmpty(
            governorates: governorates,
            buildings: buildings,
            buildingsLoadFailed: buildingsLoadFailed,
          ),
        );
      case ApiFailureResult<HousingRequest?>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  /// يحذف طلب السكن المرفوض الحالي ثم يعرض نموذج تقديم فارغاً — الحذف
  /// ضروري وليس تجميلاً فقط: `/mine` قد ترجع أكثر من طلب، والتطبيق يعرض
  /// أولها فقط، فبدون حذف الطلب المرفوض قد يستمر ظهوره بدل الطلب الجديد
  /// المُقدَّم فعلاً. يبقى المستخدم على حالة "مرفوض" الحالية إن فشل الحذف
  /// (نادراً — يُرفض الحذف فقط إن كان الطالب مُسكّناً فعلياً، وهو مستبعَد
  /// لطلب مرفوض) حتى لا يظهر نموذج تقديم فارغ بينما الطلب القديم لا يزال
  /// موجوداً فعلياً على الخادم.
  Future<ApiResult<void>> startNewRequestAfterRejection() async {
    final current = state;
    if (current is! HousingRequestSubmitted) {
      return ApiResult.success(null);
    }

    final result = await _repository.deleteRequest(current.request.id);
    if (result.isSuccess) {
      emit(
        HousingRequestEmpty(
          governorates: current.governorates,
          buildings: current.buildings,
        ),
      );
    }
    return result;
  }

  /// يعيد جلب قائمة الأبنية فقط دون إعادة تحميل الشاشة كاملة — تُستدعى من
  /// زر "إعادة المحاولة" الذي يظهر فقط عند فشل النداء فعلياً (راجع
  /// [HousingRequestEmpty.buildingsLoadFailed]).
  Future<void> retryLoadBuildings() async {
    final current = state;
    final buildingsResult = await _repository.fetchBuildings();
    final buildingsLoadFailed = buildingsResult is ApiFailureResult;
    final buildings = switch (buildingsResult) {
      ApiSuccess<List<Building>>(:final data) => data,
      ApiFailureResult<List<Building>>() => const <Building>[],
    };

    switch (current) {
      case HousingRequestEmpty(:final governorates):
        emit(
          HousingRequestEmpty(
            governorates: governorates,
            buildings: buildings,
            buildingsLoadFailed: buildingsLoadFailed,
          ),
        );
      case HousingRequestSubmitted(:final request, :final governorates):
        emit(
          HousingRequestSubmitted(
            request,
            governorates: governorates,
            buildings: buildings,
            buildingsLoadFailed: buildingsLoadFailed,
          ),
        );
      default:
        // حالات أخرى (تحميل/إرسال/فشل عام) لا معنى لتحديث الأبنية فيها.
        break;
    }
  }

  /// غرف مبنى واحد، لملء اختيار "رقم الغرفة" بعد اختيار المبنى والطابق —
  /// لا تؤثر على [state] الرئيسية (مجرد نداء بيانات يستخدمه النموذج
  /// مباشرة)، بنفس نمط الوصول للبيانات دائماً عبر الكيوبت لا المستودع
  /// مباشرة من الواجهة.
  Future<ApiResult<List<DormRoom>>> fetchRoomsForBuilding(int buildingId) {
    return _repository.fetchRoomsForBuilding(buildingId);
  }

  /// دفع رسوم طلب سكن مقبول من رصيد المحفظة. لا تُغيّر [state] الرئيسية —
  /// الشاشة تستدعيها مباشرة وتدير مؤشر التحميل محلياً (بنفس نمط
  /// [fetchRoomsForBuilding]/إلغاء طلب الصيانة)، ثم تعيد جلب الطلب بعد
  /// النجاح عبر [fetchMyRequest] حتى تنعكس أي حقول محدَّثة من الخادم.
  Future<ApiResult<double?>> payForRequest(int requestId) {
    return _repository.payForRequest(requestId);
  }

  Future<void> submitRequest({
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> documents,
  }) async {
    emit(const HousingRequestSubmitting());

    final result = await _repository.submitRequest(
      gender: gender,
      governorateId: governorateId,
      academicLevel: academicLevel,
      detailedAddress: detailedAddress,
      hasSpecialNeeds: hasSpecialNeeds,
      isPreviousResident: isPreviousResident,
      previousBuildingId: previousBuildingId,
      previousFloor: previousFloor,
      previousRoomNumber: previousRoomNumber,
      specialNotes: specialNotes,
      documents: documents,
    );

    switch (result) {
      case ApiSuccess<HousingRequest>(:final data):
        emit(HousingRequestSubmitted(data));
      case ApiFailureResult<HousingRequest>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  Future<void> updateRequest({
    required int requestId,
    required int gender,
    required int governorateId,
    required int academicLevel,
    required String detailedAddress,
    required bool hasSpecialNeeds,
    required bool isPreviousResident,
    int? previousBuildingId,
    int? previousFloor,
    String? previousRoomNumber,
    String? specialNotes,
    required List<HousingDocument> replacedDocuments,
  }) async {
    emit(const HousingRequestSubmitting());

    final result = await _repository.updateRequest(
      requestId: requestId,
      gender: gender,
      governorateId: governorateId,
      academicLevel: academicLevel,
      detailedAddress: detailedAddress,
      hasSpecialNeeds: hasSpecialNeeds,
      isPreviousResident: isPreviousResident,
      previousBuildingId: previousBuildingId,
      previousFloor: previousFloor,
      previousRoomNumber: previousRoomNumber,
      specialNotes: specialNotes,
      replacedDocuments: replacedDocuments,
    );

    switch (result) {
      case ApiSuccess<HousingRequest>(:final data):
        emit(HousingRequestSubmitted(data));
      case ApiFailureResult<HousingRequest>(:final failure):
        emit(HousingRequestFailure(failure));
    }
  }

  @override
  Future<void> close() {
    _refreshSubscription?.cancel();
    return super.close();
  }
}
