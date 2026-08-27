// اختبار تحقق أساسي (Smoke Test) للتأكد من أن التطبيق يقلع بنجاح، يعرض شاشة
// البداية (Splash)، ثم ينتقل تلقائياً إلى شاشة تسجيل الدخول دون أخطاء.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakani/core/constants/app_colors.dart';
import 'package:sakani/core/network/api_result.dart';
import 'package:sakani/core/theme/theme_controller.dart';
import 'package:sakani/features/groups/domain/entities/student_group.dart';
import 'package:sakani/features/groups/domain/repositories/groups_repository.dart';
import 'package:sakani/features/groups/presentation/cubit/groups_cubit.dart';
import 'package:sakani/features/groups/presentation/cubit/groups_state.dart';
import 'package:sakani/features/housing_request/domain/entities/building.dart';
import 'package:sakani/features/housing_request/domain/entities/dorm_room.dart';
import 'package:sakani/features/housing_request/domain/entities/governorate.dart';
import 'package:sakani/features/housing_request/domain/entities/housing_cycle.dart';
import 'package:sakani/features/housing_request/domain/entities/housing_document.dart';
import 'package:sakani/features/housing_request/domain/entities/housing_request.dart';
import 'package:sakani/features/housing_request/domain/repositories/housing_request_repository.dart';
import 'package:sakani/features/housing_request/presentation/cubit/housing_request_cubit.dart';
import 'package:sakani/features/housing_request/presentation/cubit/housing_request_state.dart';
import 'package:sakani/features/maintenance/domain/entities/maintenance_request.dart';
import 'package:sakani/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:sakani/features/maintenance/presentation/cubit/maintenance_list_cubit.dart';
import 'package:sakani/features/maintenance/presentation/cubit/maintenance_list_state.dart';
import 'package:sakani/features/notifications/domain/entities/app_notification.dart';
import 'package:sakani/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:sakani/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:sakani/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:sakani/main.dart';

class _FakeGroupsRepository implements GroupsRepository {
  _FakeGroupsRepository({this.group}) : fetchMyGroupCallCount = 0;

  StudentGroup? group;
  int fetchMyGroupCallCount;

  @override
  Future<ApiResult<StudentGroup?>> fetchMyGroup() async {
    fetchMyGroupCallCount += 1;
    return ApiResult.success(group);
  }

  @override
  Future<ApiResult<StudentGroup>> createGroup({String? description}) async {
    return ApiResult.success(
      group ??
          const StudentGroup(
            id: 1,
            code: 'GRP-001',
            leaderId: 'u1',
            maxMembers: 4,
            memberStudentIds: ['u1'],
            status: HousingGroupStatus.open,
          ),
    );
  }

  @override
  Future<ApiResult<void>> joinGroupByCode(String code) async {
    return ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> respondToInvitation({
    required int invitationId,
    required bool approve,
  }) async {
    return ApiResult.success(null);
  }

  @override
  Future<ApiResult<void>> leaveGroup() async {
    return ApiResult.success(null);
  }
}

class _FakeNotificationsRepository implements NotificationsRepository {
  const _FakeNotificationsRepository({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<ApiResult<List<AppNotification>>> fetchNotifications() async {
    return ApiResult.success([
      AppNotification(
        id: 'n1',
        title: 'إشعار تجريبي',
        createdAt: DateTime.now(),
        timeLabel: 'الآن',
        colorKey: 'info',
        isUnread: true,
      ),
    ]);
  }

  @override
  Future<ApiResult<void>> markAsRead(String id) async {
    return shouldFail
        ? ApiResult.failure(ApiFailure.unknown('فشل تحديث الإشعار'))
        : ApiResult.success(null);
  }
}

class _FakeHousingRequestRepository implements HousingRequestRepository {
  const _FakeHousingRequestRepository({this.shouldFailDelete = false});

  final bool shouldFailDelete;

  @override
  Future<ApiResult<HousingCycle?>> fetchCurrentCycle() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<List<Governorate>>> fetchGovernorates() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<HousingRequest?>> fetchMyRequest() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<HousingRequest>> submitRequest({
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
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<HousingRequest>> updateRequest({
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
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<void>> deleteRequest(int requestId) async {
    return shouldFailDelete
        ? ApiResult.failure(ApiFailure.unknown('فشل حذف طلب السكن'))
        : ApiResult.success(null);
  }

  @override
  Future<ApiResult<List<Building>>> fetchBuildings() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<List<DormRoom>>> fetchRoomsForBuilding(int buildingId) =>
      throw UnimplementedError();
}

class _FakeMaintenanceRepository implements MaintenanceRepository {
  const _FakeMaintenanceRepository({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<ApiResult<List<MaintenanceRequest>>> fetchRequests() async {
    return ApiResult.success([
      MaintenanceRequest(
        id: 'm1',
        userId: 'u1',
        description: 'تسرب في السباكة',
        category: 'plumbing',
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<ApiResult<MaintenanceRequest>> submitRequest({
    required String description,
    required String category,
    dynamic imageBytes,
  }) async {
    return ApiResult.success(
      MaintenanceRequest(
        id: 'm2',
        userId: 'u1',
        description: description,
        category: category,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<ApiResult<void>> cancelRequest(String requestId) async {
    return shouldFail
        ? ApiResult.failure(ApiFailure.unknown('فشل إلغاء طلب الصيانة'))
        : ApiResult.success(null);
  }
}

void main() {
  // بدون هذا، تعليق حقيقي (وليس فشل سريع) داخل `testWidgets` عند أول نداء
  // SharedPreferences.getInstance() (مثال: ThemeController.load) — يختلف
  // سلوك القناة غير المُهيّأة هون عن اختبار Dart عادي (test بدون testWidgets)
  // الذي يفشل بسرعة بـ MissingPluginException. القيم الوهمية هون تُغني عن أي
  // قناة منصّة حقيقية إطلاقاً.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('التطبيق يقلع ويعرض شاشة البداية ثم ينتقل لتسجيل الدخول', (
    WidgetTester tester,
  ) async {
    final themeController = await ThemeController.load();
    await tester.pumpWidget(MyApp(themeController: themeController));
    await tester.pump();

    expect(find.text('سكني'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // تفريغ مؤقت الانتقال التلقائي في شاشة البداية (2 ثانية) ثم انتظار
    // استقرار التنقل عبر GoRouter.
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('تسجيل الدخول'), findsWidgets);
  });

  test('تحميل الثيم لا يسبب أخطاء ويحتفظ بقيم الألوان الأساسية', () async {
    final controller = await ThemeController.load();

    expect(controller.mode, isA<ThemeMode>());
    expect(AppColors.primary, const Color(0xFF0EA5E9));
    expect(AppColors.background, isA<Color>());
    expect(AppColors.textPrimary, isA<Color>());
  });

  test(
    'تنشيط عملية إنشاء أو انضمام غروب يؤدي إلى تحديث الحالة الحالية',
    () async {
      final repository = _FakeGroupsRepository(
        group: const StudentGroup(
          id: 1,
          code: 'GRP-001',
          leaderId: 'u1',
          maxMembers: 4,
          memberStudentIds: ['u1'],
          status: HousingGroupStatus.open,
        ),
      );
      final cubit = GroupsCubit(repository);

      await cubit.createGroup();
      await cubit.joinGroupByCode('ABC123');

      expect(repository.fetchMyGroupCallCount, 2);
      expect(cubit.state, isA<GroupsSuccess>());
    },
  );

  test('إرسال طلب انضمام يعرض حالة الانتظار، والإلغاء يوقفها محلياً', () async {
    final repository = _FakeGroupsRepository();
    final cubit = GroupsCubit(repository);

    await cubit.joinGroupByCode('ABC123');
    var state = cubit.state as GroupsSuccess;
    expect(state.myGroup, isNull);
    expect(state.pendingJoinRequest?.code, 'ABC123');

    await cubit.cancelPendingJoinRequest();
    state = cubit.state as GroupsSuccess;
    expect(state.pendingJoinRequest, isNull);
  });

  test('الانضمام الفعلي لغروب يمسح حالة الانتظار المحلية تلقائياً', () async {
    final repository = _FakeGroupsRepository();
    final cubit = GroupsCubit(repository);
    await cubit.joinGroupByCode('ABC123');

    repository.group = const StudentGroup(
      id: 1,
      code: 'GRP-001',
      leaderId: 'other',
      maxMembers: 4,
      memberStudentIds: ['other', 'me'],
      status: HousingGroupStatus.open,
    );
    await cubit.fetchMyGroup();

    final state = cubit.state as GroupsSuccess;
    expect(state.myGroup, isNotNull);
    expect(state.pendingJoinRequest, isNull);
  });

  test('إذا فشل تعليم الإشعار كمقروء، تعود الحالة إلى ما كانت عليه', () async {
    final notification = AppNotification(
      id: 'n1',
      title: 'إشعار تجريبي',
      createdAt: DateTime.now(),
      timeLabel: 'الآن',
      colorKey: 'info',
      isUnread: true,
    );

    final cubit = NotificationsCubit(
      const _FakeNotificationsRepository(shouldFail: true),
    );

    cubit.emit(NotificationsSuccess([notification]));
    await cubit.markAsRead('n1');

    expect(cubit.state, isA<NotificationsSuccess>());
    final state = cubit.state as NotificationsSuccess;
    expect(state.notifications.first.isUnread, isTrue);
  });

  test('إذا فشل إلغاء طلب صيانة، تعود القائمة إلى الحالة الأصلية', () async {
    final request = MaintenanceRequest(
      id: 'm1',
      userId: 'u1',
      description: 'تسرب في السباكة',
      category: 'plumbing',
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final cubit = MaintenanceListCubit(
      const _FakeMaintenanceRepository(shouldFail: true),
    );

    cubit.emit(MaintenanceListSuccess([request]));
    final result = await cubit.cancelRequest('m1');

    expect(result.isFailure, isTrue);
    final state = cubit.state as MaintenanceListSuccess;
    expect(state.requests, hasLength(1));
    expect(state.requests.first.id, 'm1');
  });

  test(
    'بعد رفض طلب السكن، يعرض نموذج تقديم فارغاً بدل حالة الرفض العالقة',
    () async {
      final rejected = HousingRequest(
        id: 1,
        gender: 0,
        governorateId: 1,
        academicLevel: 1,
        detailedAddress: 'عنوان تجريبي',
        hasSpecialNeeds: false,
        isPreviousResident: false,
        status: HousingRequestStatus.locked,
        submittedAt: DateTime.now(),
        decision: const AdmissionDecision(
          status: AdmissionDecisionStatus.rejected,
          decisionReason: 'عدم استيفاء الشروط',
        ),
      );
      const governorates = [Governorate(id: 1, name: 'دمشق')];

      final cubit = HousingRequestCubit(const _FakeHousingRequestRepository());
      cubit.emit(HousingRequestSubmitted(rejected, governorates: governorates));

      final result = await cubit.startNewRequestAfterRejection();

      expect(result.isSuccess, isTrue);
      expect(cubit.state, isA<HousingRequestEmpty>());
      final state = cubit.state as HousingRequestEmpty;
      expect(state.governorates, governorates);
    },
  );

  test('إذا فشل حذف الطلب المرفوض، تبقى حالة الرفض كما هي', () async {
    final rejected = HousingRequest(
      id: 1,
      gender: 0,
      governorateId: 1,
      academicLevel: 1,
      detailedAddress: 'عنوان تجريبي',
      hasSpecialNeeds: false,
      isPreviousResident: false,
      status: HousingRequestStatus.locked,
      submittedAt: DateTime.now(),
      decision: const AdmissionDecision(
        status: AdmissionDecisionStatus.rejected,
      ),
    );
    const governorates = [Governorate(id: 1, name: 'دمشق')];

    final cubit = HousingRequestCubit(
      const _FakeHousingRequestRepository(shouldFailDelete: true),
    );
    final submitted = HousingRequestSubmitted(
      rejected,
      governorates: governorates,
    );
    cubit.emit(submitted);

    final result = await cubit.startNewRequestAfterRejection();

    expect(result.isFailure, isTrue);
    expect(cubit.state, submitted);
  });
}
