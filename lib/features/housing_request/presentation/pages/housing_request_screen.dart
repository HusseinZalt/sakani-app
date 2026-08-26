import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
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
import '../../domain/entities/governorate.dart';
import '../../domain/entities/housing_document.dart';
import '../../domain/entities/housing_request.dart';
import '../cubit/housing_request_cubit.dart';
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
                    HousingRequestEmpty(:final governorates) =>
                      _RequestFormView(governorates: governorates),
                    HousingRequestSubmitting() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    HousingRequestSubmitted(
                      :final request,
                      :final governorates,
                    ) =>
                      request.status == HousingRequestStatus.needsRevision
                          ? _RequestFormView(
                            governorates: governorates,
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
  const _RequestFormView({required this.governorates, this.existingRequest});

  final List<Governorate> governorates;
  final HousingRequest? existingRequest;

  @override
  State<_RequestFormView> createState() => _RequestFormViewState();
}

class _RequestFormViewState extends State<_RequestFormView> {
  final _imagePicker = ImagePicker();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _previousFloorController = TextEditingController();
  final _previousRoomController = TextEditingController();
  final _previousBuildingIdController = TextEditingController();

  int? _governorateId;
  int _academicLevel = 1;
  bool _hasSpecialNeeds = false;
  bool _isPreviousResident = false;
  final Map<HousingDocumentType, HousingDocument> _documents = {};

  bool get _isEditMode => widget.existingRequest != null;

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
      _previousFloorController.text = existing.previousFloor?.toString() ?? '';
      _previousRoomController.text = existing.previousRoomNumber ?? '';
      _previousBuildingIdController.text =
          existing.previousBuildingId?.toString() ?? '';
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
    _previousFloorController.dispose();
    _previousRoomController.dispose();
    _previousBuildingIdController.dispose();
    super.dispose();
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
    if (_isPreviousResident &&
        _previousBuildingIdController.text.trim().isEmpty) {
      _showMessage('يرجى إدخال رقم المبنى السابق، أو إلغاء "سكنت سابقاً".');
      return;
    }

    final cubit = context.read<HousingRequestCubit>();
    final gender = widget.existingRequest?.gender ?? _prefilledGender;
    final previousBuildingId = int.tryParse(
      _previousBuildingIdController.text.trim(),
    );
    final previousFloor = int.tryParse(_previousFloorController.text.trim());
    final previousRoom = _previousRoomController.text.trim();
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
                      List.generate(5, (i) => i + 1).map((level) {
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
                    'رقم المبنى كما هو مسجَّل بإدارة السكن',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _previousBuildingIdController,
                    label: 'رقم المبنى',
                    hint: 'مثال: 3',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _previousFloorController,
                    label: 'الطابق (اختياري)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _previousRoomController,
                    label: 'رقم الغرفة (اختياري)',
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

class _StatusView extends StatelessWidget {
  const _StatusView({required this.request});

  final HousingRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
