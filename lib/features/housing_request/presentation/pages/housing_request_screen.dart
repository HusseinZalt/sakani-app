import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/image_resize.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/refresh_on_tab_visible.dart';
import '../../data/repositories/housing_request_repository_impl.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/dorm_room.dart';
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';
import '../cubit/housing_request_cubit.dart';
import '../cubit/housing_request_reset_signal.dart';
import '../cubit/housing_request_state.dart';
import '../housing_request_labels.dart';

/// شاشة طلب السكن الجامعي: نموذج تقديم الطلب الحقيقي (المحافظة، المستوى
/// الدراسي، العنوان التفصيلي، المستندات السبعة المحدَّدة...) قبل التقديم،
/// ومتابعة حالته (المراجعة/يحتاج تعديل/القرار) بعد التقديم.
class HousingRequestScreen extends StatelessWidget {
  const HousingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              HousingRequestCubit(HousingRequestRepositoryImpl())
                ..fetchMyRequest(),
      child: const _HousingRequestView(),
    );
  }
}

class _HousingRequestView extends StatelessWidget {
  const _HousingRequestView();

  @override
  Widget build(BuildContext context) {
    // يفرض إعادة بناء هذه الشاشة عند تبديل الوضع الليلي/النهاري — راجع
    // الشرح المفصَّل بـ home_screen.dart._HomeView حول سبب عدم كفاية
    // آلية إعادة البناء الكاملة بـ main.dart لفروع StatefulShellRoute.
    context.watch<ThemeController>();

    // نافذة "طلبك انرفض" (راجع home_screen.dart وpush_notification_service)
    // تطلب هذه الإشارة عند اختيار "إرسال طلب جديد" حتى تعرض هذه الشاشة
    // نموذج تقديم فارغاً فوراً بدل حالة "مرفوض" العالقة.
    if (HousingRequestResetSignal.consume()) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final result =
            await context
                .read<HousingRequestCubit>()
                .startNewRequestAfterRejection();
        if (!context.mounted || result.isSuccess) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(result.failureOrNull!.message)),
          );
      });
    }

    return RefreshOnTabVisible(
      onVisible: () => context.read<HousingRequestCubit>().fetchMyRequest(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const GradientHeader(
              title: 'طلب السكن',
              subtitle: 'تقديم ومتابعة طلب السكن الجامعي',
            ),
            Expanded(
              child: BlocConsumer<HousingRequestCubit, HousingRequestState>(
                listenWhen: (previous, current) {
                  if (current is HousingRequestFailure) return true;
                  return current is HousingRequestSubmitted &&
                      current.request.decision?.status ==
                          AdmissionDecisionStatus.accepted &&
                      !(previous is HousingRequestSubmitted &&
                          previous.request.decision?.status ==
                              AdmissionDecisionStatus.accepted);
                },
                listener: (context, state) {
                  if (state is HousingRequestFailure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(state.failure.message)),
                      );
                  } else if (state is HousingRequestSubmitted) {
                    // لحظة القبول تستأهل اهتزازاً لطيفاً بدل ما تمر بهدوء
                    // متل أي تحديث حالة عادي.
                    HapticFeedback.mediumImpact();
                  }
                },
                builder: (context, state) {
                  return switch (state) {
                    HousingRequestLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    HousingRequestFailure() => Center(
                      child: OutlinedButton(
                        onPressed:
                            () =>
                                context
                                    .read<HousingRequestCubit>()
                                    .fetchMyRequest(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ),
                    HousingRequestCycleClosed() => const _CycleClosedView(),
                    HousingRequestEmpty(
                      :final governorates,
                      :final buildings,
                      :final buildingsLoadFailed,
                    ) =>
                      _RequestFormView(
                        governorates: governorates,
                        buildings: buildings,
                        buildingsLoadFailed: buildingsLoadFailed,
                      ),
                    HousingRequestSubmitting() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    HousingRequestSubmitted(
                      :final request,
                      :final governorates,
                      :final buildings,
                      :final buildingsLoadFailed,
                    ) =>
                      request.status == HousingRequestStatus.needsRevision
                          ? _RequestFormView(
                            governorates: governorates,
                            buildings: buildings,
                            buildingsLoadFailed: buildingsLoadFailed,
                            existingRequest: request,
                          )
                          : _StatusView(request: request),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleClosedView extends StatelessWidget {
  const _CycleClosedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'التقديم لطلبات السكن مغلق حالياً',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'ستُفتَح دورة سكن جديدة قريباً، تابع الإشعارات.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// نموذج تقديم/تعديل الطلب — نفس النموذج يُستخدم للحالتين: [existingRequest]
/// null لطلب جديد، أو معبَّأ مسبقاً لتعديل طلب بحالة `NeedsRevision`.
class _RequestFormView extends StatefulWidget {
  const _RequestFormView({
    required this.governorates,
    required this.buildings,
    this.buildingsLoadFailed = false,
    this.existingRequest,
  });

  final List<Governorate> governorates;
  final List<Building> buildings;

  /// راجع توثيق [HousingRequestEmpty.buildingsLoadFailed].
  final bool buildingsLoadFailed;
  final HousingRequest? existingRequest;

  @override
  State<_RequestFormView> createState() => _RequestFormViewState();
}

class _RequestFormViewState extends State<_RequestFormView> {
  final _imagePicker = ImagePicker();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  // احتياطي فقط: يُستخدم لإدخال رقم الغرفة يدوياً حين يتعذّر جلب غرف
  // المبنى الفعلية (فشل الطلب، أو لم تُسجَّل غرف لهذا الطابق بعد).
  final _previousRoomFallbackController = TextEditingController();
  // احتياطي فقط: `floorsCount` بـ `GET /api/buildings/lookup` (راجع
  // توثيق `fetchBuildings` بمصدر البيانات) قد يكون `null` لبعض المباني
  // تحديداً — إدخال يدوي فقط لتلك الحالة، لا كل مبنى.
  final _previousFloorFallbackController = TextEditingController();

  int? _governorateId;
  int _academicLevel = 1;
  bool _hasSpecialNeeds = false;
  bool _isPreviousResident = false;
  final Map<HousingDocumentType, HousingDocument> _documents = {};

  int? _previousBuildingId;
  int? _previousFloor;
  String? _previousRoomNumber;
  List<DormRoom> _roomsForSelectedBuilding = [];
  bool _isLoadingRooms = false;
  bool _roomsLoadFailed = false;

  bool get _isEditMode => widget.existingRequest != null;

  Building? get _selectedBuilding => widget.buildings
      .cast<Building?>()
      .firstWhere((b) => b?.id == _previousBuildingId, orElse: () => null);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRequest;
    if (existing != null) {
      _governorateId = existing.governorateId;
      _academicLevel = existing.academicLevel;
      _addressController.text = existing.detailedAddress;
      _notesController.text = existing.specialNotes ?? '';
      _hasSpecialNeeds = existing.hasSpecialNeeds;
      _isPreviousResident = existing.isPreviousResident;
      _previousBuildingId = existing.previousBuildingId;
      _previousFloor = existing.previousFloor;
      _previousRoomNumber = existing.previousRoomNumber;
      _previousRoomFallbackController.text = existing.previousRoomNumber ?? '';
      _previousFloorFallbackController.text =
          existing.previousFloor?.toString() ?? '';
      if (_previousBuildingId != null) _loadRoomsForBuilding();
      for (final doc in existing.documents) {
        _documents[doc.type] = doc;
      }
    } else {
      final gender = context.read<UserSessionCubit>().state?.gender;
      // لا حقل جنس بالنموذج — يُشتق تلقائياً من حساب الطالب نفسه.
      _prefilledGender = switch (gender) {
        'female' => 1,
        _ => 0,
      };
    }
  }

  int _prefilledGender = 0;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _previousRoomFallbackController.dispose();
    _previousFloorFallbackController.dispose();
    super.dispose();
  }

  Future<void> _loadRoomsForBuilding() async {
    final buildingId = _previousBuildingId;
    if (buildingId == null) return;

    setState(() {
      _isLoadingRooms = true;
      _roomsLoadFailed = false;
    });

    final result = await context
        .read<HousingRequestCubit>()
        .fetchRoomsForBuilding(buildingId);
    if (!mounted) return;

    setState(() {
      _isLoadingRooms = false;
      switch (result) {
        case ApiSuccess<List<DormRoom>>(:final data):
          _roomsForSelectedBuilding = data;
          _roomsLoadFailed = false;
        case ApiFailureResult<List<DormRoom>>():
          _roomsForSelectedBuilding = [];
          _roomsLoadFailed = true;
      }
    });
  }

  Future<void> _pickDocument(HousingDocumentType type) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () => _pickFrom(sheetContext, type, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('اختيار من المعرض'),
                onTap: () => _pickFrom(sheetContext, type, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFrom(
    BuildContext sheetContext,
    HousingDocumentType type,
    ImageSource source,
  ) async {
    try {
      final file = await _imagePicker.pickImage(source: source);
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (file == null) return;
      final bytes = await compressImageBytes(await file.readAsBytes());
      if (!mounted) return;
      setState(() {
        _documents[type] = HousingDocument(
          type: type,
          bytes: bytes,
          fileName: file.name,
        );
      });
    } catch (_) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذر إرفاق المستند، يرجى المحاولة مرة أخرى.'),
          ),
        );
    }
  }

  void _submit() {
    if (_governorateId == null) {
      _showMessage('يرجى اختيار المحافظة.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showMessage('يرجى إدخال العنوان التفصيلي.');
      return;
    }
    final missingMandatory = HousingDocumentType.values.where(
      (type) => type.mandatory && !_documents.containsKey(type),
    );
    if (missingMandatory.isNotEmpty) {
      _showMessage(
        'يرجى إرفاق كل المستندات الإلزامية: ${missingMandatory.map((t) => t.label).join('، ')}.',
      );
      return;
    }
    if (_isPreviousResident) {
      if (_previousBuildingId == null) {
        _showMessage('يرجى اختيار المبنى السابق، أو إلغاء "سكنت سابقاً".');
        return;
      }
      final floorsCount = _selectedBuilding?.floorsCount;
      if (floorsCount != null && floorsCount > 0 && _previousFloor == null) {
        _showMessage('يرجى اختيار الطابق السابق.');
        return;
      }
      if (_previousFloor != null &&
          (_previousRoomNumber == null || _previousRoomNumber!.isEmpty)) {
        _showMessage('يرجى اختيار رقم الغرفة السابقة.');
        return;
      }
    }

    final cubit = context.read<HousingRequestCubit>();
    final gender = widget.existingRequest?.gender ?? _prefilledGender;
    final previousBuildingId = _previousBuildingId;
    final previousFloor = _previousFloor;
    final previousRoom = _previousRoomNumber?.trim() ?? '';
    final notes = _notesController.text.trim();

    if (_isEditMode) {
      cubit.updateRequest(
        requestId: widget.existingRequest!.id,
        gender: gender,
        governorateId: _governorateId!,
        academicLevel: _academicLevel,
        detailedAddress: _addressController.text.trim(),
        hasSpecialNeeds: _hasSpecialNeeds,
        isPreviousResident: _isPreviousResident,
        previousBuildingId: _isPreviousResident ? previousBuildingId : null,
        previousFloor: _isPreviousResident ? previousFloor : null,
        previousRoomNumber:
            _isPreviousResident && previousRoom.isNotEmpty
                ? previousRoom
                : null,
        specialNotes: notes.isEmpty ? null : notes,
        // فقط المستندات يلي معها بايتات محلية جديدة (استُبدلت فعلياً).
        replacedDocuments:
            _documents.values.where((d) => d.bytes != null).toList(),
      );
    } else {
      cubit.submitRequest(
        gender: gender,
        governorateId: _governorateId!,
        academicLevel: _academicLevel,
        detailedAddress: _addressController.text.trim(),
        hasSpecialNeeds: _hasSpecialNeeds,
        isPreviousResident: _isPreviousResident,
        previousBuildingId: _isPreviousResident ? previousBuildingId : null,
        previousFloor: _isPreviousResident ? previousFloor : null,
        previousRoomNumber:
            _isPreviousResident && previousRoom.isNotEmpty
                ? previousRoom
                : null,
        specialNotes: notes.isEmpty ? null : notes,
        documents: _documents.values.toList(),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditMode) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'طلبك يحتاج تعديل — راجع ملاحظات كل مستند مرفوض أدناه واستبدله، ثم أعد الإرسال.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'المحافظة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      widget.governorates.map((gov) {
                        return CustomChip(
                          label: gov.name,
                          selected: _governorateId == gov.id,
                          onTap: () => setState(() => _governorateId = gov.id),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'المستوى الدراسي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      List.generate(7, (i) => i + 1).map((level) {
                        return CustomChip(
                          label: HousingRequestLabels.academicLevelLabel(level),
                          selected: _academicLevel == level,
                          onTap: () => setState(() => _academicLevel = level),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _addressController,
            label: 'العنوان التفصيلي',
            hint: 'مثال: حلب - حي الشهباء - شارع...',
            maxLines: 2,
            minLines: 1,
          ),
          const SizedBox(height: 16),
          CustomCard(
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                SwitchListTile(
                  value: _hasSpecialNeeds,
                  onChanged:
                      (value) => setState(() => _hasSpecialNeeds = value),
                  title: const Text('لدي احتياجات خاصة'),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _isPreviousResident,
                  onChanged:
                      (value) => setState(() => _isPreviousResident = value),
                  title: const Text('سكنت بالسكن الجامعي سابقاً'),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          if (_isPreviousResident) ...[
            const SizedBox(height: 16),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'بيانات السكن السابق',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'المبنى',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.buildings.isEmpty && widget.buildingsLoadFailed)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تعذّر تحميل قائمة الأبنية.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () =>
                                  context
                                      .read<HousingRequestCubit>()
                                      .retryLoadBuildings(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    )
                  else if (widget.buildings.isEmpty)
                    Text(
                      'لا توجد مبانٍ مسجَّلة حالياً.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.buildings.map((building) {
                            return CustomChip(
                              label: building.name,
                              selected: _previousBuildingId == building.id,
                              onTap: () {
                                if (_previousBuildingId == building.id) return;
                                setState(() {
                                  _previousBuildingId = building.id;
                                  _previousFloor = null;
                                  _previousRoomNumber = null;
                                  _previousRoomFallbackController.clear();
                                  _previousFloorFallbackController.clear();
                                  _roomsForSelectedBuilding = [];
                                });
                                _loadRoomsForBuilding();
                              },
                            );
                          }).toList(),
                    ),
                  if (_previousBuildingId != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'الطابق',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedBuilding?.floorsCount == null ||
                        _selectedBuilding!.floorsCount! <= 0)
                      CustomTextField(
                        controller: _previousFloorFallbackController,
                        label: 'رقم الطابق',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = int.tryParse(value.trim());
                          setState(() {
                            _previousFloor = parsed;
                            _previousRoomNumber = null;
                            _previousRoomFallbackController.clear();
                          });
                        },
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            List.generate(
                              _selectedBuilding!.floorsCount!,
                              (i) => i + 1,
                            ).map((floor) {
                              return CustomChip(
                                label: 'الطابق $floor',
                                selected: _previousFloor == floor,
                                onTap: () {
                                  if (_previousFloor == floor) return;
                                  setState(() {
                                    _previousFloor = floor;
                                    _previousRoomNumber = null;
                                    _previousRoomFallbackController.clear();
                                  });
                                },
                              );
                            }).toList(),
                      ),
                  ],
                  if (_previousFloor != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'رقم الغرفة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        if (_isLoadingRooms) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final roomsOnFloor =
                            _roomsForSelectedBuilding
                                .where((r) => r.floor == _previousFloor)
                                .toList();
                        if (roomsOnFloor.isEmpty) {
                          // احتياطي: فشل جلب الغرف، أو لا غرف مسجَّلة لهذا
                          // الطابق بعد — إدخال يدوي بدل تعطيل القسم كاملاً.
                          return CustomTextField(
                            controller: _previousRoomFallbackController,
                            label:
                                _roomsLoadFailed
                                    ? 'رقم الغرفة (تعذّر تحميل قائمة الغرف)'
                                    : 'رقم الغرفة (لا توجد غرف مسجَّلة لهذا الطابق)',
                            onChanged:
                                (value) => setState(
                                  () =>
                                      _previousRoomNumber =
                                          value.trim().isEmpty
                                              ? null
                                              : value.trim(),
                                ),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              roomsOnFloor.map((room) {
                                return CustomChip(
                                  label: room.roomNumber,
                                  selected:
                                      _previousRoomNumber == room.roomNumber,
                                  onTap:
                                      () => setState(
                                        () =>
                                            _previousRoomNumber =
                                                room.roomNumber,
                                      ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'المستندات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الخمسة الأولى إلزامية، والأخيرتان اختياريتان',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (final type in HousingDocumentType.values) ...[
                  if (type != HousingDocumentType.values.first)
                    const SizedBox(height: 10),
                  _DocumentSlot(
                    type: type,
                    document: _documents[type],
                    editable:
                        !_isEditMode || _documents[type] == null
                            ? true
                            : _documents[type]!.reviewStatus !=
                                DocumentReviewStatus.approved,
                    onTap: () => _pickDocument(type),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _notesController,
            label: 'ملاحظات إضافية (اختياري)',
            hint: 'أي معلومة إضافية تودّ إخبارنا بها',
            maxLines: 4,
            minLines: 3,
          ),
          const SizedBox(height: 22),
          BlocBuilder<HousingRequestCubit, HousingRequestState>(
            builder: (context, state) {
              return CustomButton(
                label: _isEditMode ? 'إعادة إرسال الطلب' : 'إرسال الطلب',
                icon: Icons.send_rounded,
                isLoading: state is HousingRequestSubmitting,
                onPressed: _submit,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.type,
    required this.document,
    required this.editable,
    required this.onTap,
  });

  final HousingDocumentType type;
  final HousingDocument? document;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocalBytes = document?.bytes != null;
    final reviewStatus = document?.reviewStatus;

    final (Color statusColor, String? statusLabel) = switch (reviewStatus) {
      DocumentReviewStatus.approved => (AppColors.success, 'مقبول'),
      DocumentReviewStatus.rejected => (AppColors.error, 'مرفوض'),
      DocumentReviewStatus.pending => (AppColors.secondaryDark, 'قيد المراجعة'),
      null => (AppColors.textHint, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color:
              reviewStatus == DocumentReviewStatus.rejected
                  ? AppColors.error
                  : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (hasLocalBytes && document?.bytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    document!.bytes!,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Icon(
                  document != null
                      ? Icons.check_circle_outline_rounded
                      : Icons.description_outlined,
                  color: document != null ? statusColor : AppColors.primary,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label + (type.mandatory ? ' *' : ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (statusLabel != null)
                      Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (editable)
                TextButton(
                  onPressed: onTap,
                  child: Text(document != null ? 'استبدال' : 'إرفاق'),
                ),
            ],
          ),
          if (reviewStatus == DocumentReviewStatus.rejected &&
              document?.reviewNotes != null &&
              document!.reviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              document!.reviewNotes!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// يعرض المبلغ بلا كسور إن كان عدداً صحيحاً، وإلا بمنزلتين عشريتين
/// (نفس تنسيق شاشة المحفظة).
String _formatAmount(double amount) {
  return amount == amount.truncateToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
}

class _StatusView extends StatefulWidget {
  const _StatusView({required this.request});

  final HousingRequest request;

  @override
  State<_StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<_StatusView> {
  bool _isPaying = false;

  /// حوار تأكيد وسط الشاشة قبل تنفيذ الدفع فعلياً — الدفع عملية مالية لا
  /// رجعة فيها، فلا نخصم بمجرد لمسة زر واحدة. [feeAmount] هو الرسم
  /// المتوجّب على الطلب (`HousingRequest.feeAmount`، قيمة مجمَّدة من
  /// الخادم لا يختارها الطالب)، يُعرض مع الرصيد الحالي والرصيد بعد الدفع،
  /// ويُرسَل كما هو كـ `amount` لنداء `/pay`.
  Future<void> _confirmAndPay(
    BuildContext context,
    int requestId,
    double feeAmount,
  ) async {
    if (_isPaying) return;
    final theme = Theme.of(context);
    final balance = context.read<UserSessionCubit>().state?.balance ?? 0;
    final remaining = balance - feeAmount;
    final insufficient = remaining < 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('تأكيد دفع رسوم السكن'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'راجع التفاصيل قبل التأكيد — الخصم من رصيد محفظتك مباشر '
                  'ولا يمكن التراجع عنه بعد التأكيد.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      _PayDetailRow(
                        label: 'رسوم السكن المطلوبة',
                        value: _formatAmount(feeAmount),
                        emphasize: true,
                      ),
                      const SizedBox(height: 8),
                      _PayDetailRow(
                        label: 'رصيد محفظتك الحالي',
                        value: _formatAmount(balance),
                      ),
                      const SizedBox(height: 8),
                      _PayDetailRow(
                        label:
                            insufficient
                                ? 'المبلغ الناقص'
                                : 'رصيدك بعد الدفع',
                        value: _formatAmount(
                          insufficient ? -remaining : remaining,
                        ),
                        danger: insufficient,
                      ),
                    ],
                  ),
                ),
                if (insufficient) ...[
                  const SizedBox(height: 12),
                  Text(
                    'رصيدك لا يكفي لدفع الرسوم، يرجى شحن محفظتك أولاً ثم '
                    'إعادة المحاولة.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed:
                    insufficient
                        ? null
                        : () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(dialogContext).pop(true);
                        },
                child: const Text('تأكيد الدفع'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      await _handlePay(context, requestId, feeAmount);
    }
  }

  Future<void> _handlePay(
    BuildContext context,
    int requestId,
    double amount,
  ) async {
    if (_isPaying) return;
    setState(() => _isPaying = true);

    final cubit = context.read<HousingRequestCubit>();
    final result = await cubit.payForRequest(requestId, amount);

    if (result.isSuccess) {
      final newBalance = result.dataOrNull;
      if (newBalance != null && context.mounted) {
        final sessionCubit = context.read<UserSessionCubit>();
        final user = sessionCubit.state;
        if (user != null) {
          sessionCubit.setUser(user.copyWith(balance: newBalance));
        }
      }
    }

    // نعتمد `isPaid` الحقيقي من الخادم لا نجاح النداء وحده لإخفاء الزر
    // (راجع [HousingRequest.isPaid])، فنعيد جلب الطلب دائماً بعد محاولة
    // الدفع — نجحت أم فشلت. عند 409 تحديداً هذا ضروري وليس مجرد تحديث:
    // الخطأ غامض المعنى (مدفوع مسبقاً أو رسم الدورة = 0)، ولا سبيل
    // للتمييز إلا بفحص `isPaid` الفعلي بعد إعادة الجلب هذه (راجع توثيق
    // `_mapPayException` بمصدر البيانات).
    final failure = result.failureOrNull;
    await cubit.fetchMyRequest();
    if (!context.mounted) return;

    String message;
    if (result.isSuccess) {
      message = 'تم دفع رسوم السكن بنجاح.';
    } else if (failure?.statusCode == 409) {
      final freshState = cubit.state;
      final isPaidNow =
          freshState is HousingRequestSubmitted && freshState.request.isPaid;
      message =
          isPaidNow
              ? 'تم دفع رسوم هذا الطلب مسبقاً.'
              : 'لم يتم تحديد رسوم السكن لهذه الدورة بعد، يرجى المحاولة لاحقاً أو التواصل مع الإدارة.';
    } else {
      message = failure!.message;
    }

    setState(() => _isPaying = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = widget.request;
    final decision = request.decision;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (decision?.status == AdmissionDecisionStatus.accepted) ...[
            const _AcceptedCelebrationBanner(),
            const SizedBox(height: 16),
          ],
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'حالة الطلب',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        request.status.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'المستوى الدراسي',
                  value: HousingRequestLabels.academicLevelLabel(
                    request.academicLevel,
                  ),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: 'العنوان', value: request.detailedAddress),
                if (request.specialNotes != null &&
                    request.specialNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(label: 'ملاحظات', value: request.specialNotes!),
                ],
              ],
            ),
          ),
          if (decision != null) ...[
            const SizedBox(height: 16),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'القرار',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.statusColor(
                            decision.status.name,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          decision.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.statusColor(decision.status.name),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (decision.decisionReason != null &&
                      decision.decisionReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      decision.decisionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (decision?.status == AdmissionDecisionStatus.accepted) ...[
            const SizedBox(height: 16),
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'رسوم السكن',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.isPaid
                        ? 'تم دفع رسوم السكن بنجاح من رصيد محفظتك.'
                        : (request.feeAmount != null && request.feeAmount! > 0)
                        ? 'رسوم السكن لهذه الدورة ${_formatAmount(request.feeAmount!)}، تُدفع من رصيد محفظتك مباشرة داخل التطبيق.'
                        : 'ستتمكّن من دفع رسوم السكن من محفظتك بمجرد تحديد رسوم هذه الدورة.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (request.isPaid)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'مدفوع',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else if (request.feeAmount != null && request.feeAmount! > 0)
                    CustomButton(
                      label:
                          'ادفع رسوم السكن (${_formatAmount(request.feeAmount!)})',
                      icon: Icons.payments_outlined,
                      isLoading: _isPaying,
                      onPressed:
                          () => _confirmAndPay(
                            context,
                            request.id,
                            request.feeAmount!,
                          ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لم تُحدَّد رسوم السكن لهذه الدورة بعد.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'المستندات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < request.documents.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _DocumentSlot(
                    type: request.documents[i].type,
                    document: request.documents[i],
                    editable: false,
                    onTap: () {},
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// بانر احتفالي يظهر فوق حالة الطلب فقط عند القبول — لحظة سعيدة تستحق
/// أكثر من مجرد شارة نصية رمادية بين باقي التفاصيل.
class _AcceptedCelebrationBanner extends StatelessWidget {
  const _AcceptedCelebrationBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: AppColors.successGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            'مبروك! تم قبول طلب سكنك',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'نتمنى لك إقامة موفقة، تابع الإشعارات لمعرفة تفاصيل التسكين.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// صف "تسمية ← قيمة" داخل حوار تأكيد الدفع. [emphasize] للرسم المطلوب،
/// [danger] للمبلغ الناقص عند عدم كفاية الرصيد.
class _PayDetailRow extends StatelessWidget {
  const _PayDetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.danger = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor =
        danger
            ? AppColors.error
            : (emphasize ? AppColors.primaryDark : null);

    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight:
                emphasize || danger ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
