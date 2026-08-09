import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../groups/data/repositories/groups_repository_impl.dart';
import '../../../groups/domain/entities/student_group.dart';
import '../../data/repositories/housing_request_repository_impl.dart';
import '../../domain/entities/housing_request.dart';
import '../cubit/housing_request_cubit.dart';
import '../cubit/housing_request_state.dart';
import '../housing_request_labels.dart';

/// شاشة طلب السكن الجامعي: نموذج تقديم الطلب (نوع الطلب، نوع الغرفة،
/// المبنى المفضل، المستندات الداعمة، ملاحظات) قبل التقديم، ومتابعة حالته
/// (الإرسال/المراجعة/القرار) بعد التقديم — مطابقة للشاشة 4 من التصميم
/// المعتمد.
class HousingRequestScreen extends StatelessWidget {
  const HousingRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) => HousingRequestCubit(
            HousingRequestRepositoryImpl(),
            GroupsRepositoryImpl(),
          )..fetchMyRequest(),
      child: const _HousingRequestView(),
    );
  }
}

class _HousingRequestView extends StatefulWidget {
  const _HousingRequestView();

  @override
  State<_HousingRequestView> createState() => _HousingRequestViewState();
}

class _HousingRequestViewState extends State<_HousingRequestView> {
  final _imagePicker = ImagePicker();

  String _requestType = 'individual';
  String _roomType = 'shared';
  String _building = 'unit_a';
  final List<String> _documentNames = [];
  StudentGroup? _myGroup;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addDocument(BuildContext context) async {
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
                onTap: () async {
                  await _pickDocument(ImageSource.camera);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('اختيار من المعرض'),
                onTap: () async {
                  await _pickDocument(ImageSource.gallery);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null) return;
      setState(() => _documentNames.add(file.name));
    } catch (_) {
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

  void _removeDocument(int index) {
    setState(() => _documentNames.removeAt(index));
  }

  void _submit(BuildContext context) {
    if (_requestType == 'group' && _myGroup == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'يجب الانضمام إلى غروب أو إنشاء واحد أولاً لتقديم طلب كغروب.',
            ),
          ),
        );
      return;
    }
    if (_documentNames.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'يرجى إرفاق المستندات الداعمة المطلوبة (مثل سند الإقامة).',
            ),
          ),
        );
      return;
    }

    context.read<HousingRequestCubit>().submitRequest(
      requestType: _requestType,
      roomType: _roomType,
      preferredBuilding: _building,
      groupCode: _myGroup?.code,
      documentNames: List.unmodifiable(_documentNames),
      notes: _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(
            title: 'تقديم طلب سكن',
            subtitle: 'أكمل بياناتك لتقديم طلب سكن جديد',
          ),
          Expanded(
            child: BlocConsumer<HousingRequestCubit, HousingRequestState>(
              listener: (context, state) {
                if (state is HousingRequestFailure) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text(state.failure.message)),
                    );
                }
                if (state is HousingRequestEmpty) {
                  setState(() => _myGroup = state.myGroup);
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
                  HousingRequestSubmitted(:final request) => _SubmittedView(
                    request: request,
                  ),
                  HousingRequestEmpty() ||
                  HousingRequestSubmitting() => _RequestForm(
                    requestType: _requestType,
                    roomType: _roomType,
                    building: _building,
                    documentNames: _documentNames,
                    myGroup: _myGroup,
                    notesController: _notesController,
                    isSubmitting: state is HousingRequestSubmitting,
                    onRequestTypeChanged:
                        (value) => setState(() => _requestType = value),
                    onRoomTypeChanged:
                        (value) => setState(() => _roomType = value),
                    onBuildingChanged:
                        (value) => setState(() => _building = value),
                    onAddDocument: () => _addDocument(context),
                    onRemoveDocument: _removeDocument,
                    onSubmit: () => _submit(context),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestForm extends StatelessWidget {
  const _RequestForm({
    required this.requestType,
    required this.roomType,
    required this.building,
    required this.documentNames,
    required this.myGroup,
    required this.notesController,
    required this.isSubmitting,
    required this.onRequestTypeChanged,
    required this.onRoomTypeChanged,
    required this.onBuildingChanged,
    required this.onAddDocument,
    required this.onRemoveDocument,
    required this.onSubmit,
  });

  final String requestType;
  final String roomType;
  final String building;
  final List<String> documentNames;
  final StudentGroup? myGroup;
  final TextEditingController notesController;
  final bool isSubmitting;
  final ValueChanged<String> onRequestTypeChanged;
  final ValueChanged<String> onRoomTypeChanged;
  final ValueChanged<String> onBuildingChanged;
  final VoidCallback onAddDocument;
  final ValueChanged<int> onRemoveDocument;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroupRequest = requestType == 'group';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'نوع الطلب',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      HousingRequestLabels.requestTypes.entries.map((entry) {
                        return CustomChip(
                          label: entry.value,
                          selected: requestType == entry.key,
                          onTap:
                              isSubmitting
                                  ? null
                                  : () => onRequestTypeChanged(entry.key),
                        );
                      }).toList(),
                ),
                if (isGroupRequest) ...[
                  const SizedBox(height: 14),
                  if (myGroup != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'سيُقدَّم الطلب باسم غروبك (${myGroup!.code}) — ${myGroup!.memberCount} أعضاء.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'يجب الانضمام إلى غروب أو إنشاء واحد أولاً لتقديم طلب كغروب.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                  'نوع السكن',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      HousingRequestLabels.roomTypes.entries.map((entry) {
                        return CustomChip(
                          label: entry.value,
                          selected: roomType == entry.key,
                          onTap:
                              isSubmitting
                                  ? null
                                  : () => onRoomTypeChanged(entry.key),
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
                  'المبنى المفضل',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      HousingRequestLabels.buildings.entries.map((entry) {
                        return CustomChip(
                          label: entry.value,
                          selected: building == entry.key,
                          onTap:
                              isSubmitting
                                  ? null
                                  : () => onBuildingChanged(entry.key),
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
                  'المستندات الداعمة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مثل سند الإقامة أو أي مستند رسمي مشابه',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < documentNames.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            documentNames[i],
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap:
                              isSubmitting ? null : () => onRemoveDocument(i),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (documentNames.isNotEmpty) const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onAddDocument,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إرفاق مستند'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: notesController,
            label: 'ملاحظات إضافية (اختياري)',
            hint: 'مثال: أفضل السكن قرب أصدقائي بالغروب...',
            enabled: !isSubmitting,
            maxLines: 4,
            minLines: 3,
          ),
          const SizedBox(height: 22),
          CustomButton(
            label: 'إرسال الطلب',
            icon: Icons.send_rounded,
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.request});

  final HousingRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusStepper(status: request.status),
          const SizedBox(height: 24),
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'تفاصيل الطلب',
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
                          request.status,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        HousingRequestLabels.statusLabel(request.status),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.statusColor(request.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'نوع الطلب',
                  value: HousingRequestLabels.requestTypeLabel(
                    request.requestType,
                  ),
                ),
                if (request.groupCode != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(label: 'كود الغروب', value: request.groupCode!),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'نوع السكن',
                  value: HousingRequestLabels.roomTypeLabel(request.roomType),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'المبنى المفضل',
                  value: HousingRequestLabels.buildingLabel(
                    request.preferredBuilding,
                  ),
                ),
                if (request.documentNames.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'المستندات',
                    value: '${request.documentNames.length} مرفق',
                  ),
                ],
                if (request.notes != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(label: 'ملاحظات', value: request.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            request.status == 'pending'
                ? 'سيتم إشعارك فور مراجعة طلبك من إدارة السكن الجامعي.'
                : request.status == 'accepted'
                ? 'تهانينا! تم قبول طلبك. راجع الرئيسية لمتابعة تفاصيل السكن.'
                : 'للأسف تم رفض الطلب. تواصل مع إدارة السكن لمزيد من التفاصيل.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
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

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';
    final isAccepted = status == 'accepted';
    final decided = isRejected || isAccepted;

    return Row(
      children: [
        Expanded(child: _Step(label: 'الإرسال', state: _StepState.done)),
        _StepLine(active: true),
        Expanded(
          child: _Step(
            label: 'المراجعة',
            state: decided ? _StepState.done : _StepState.current,
          ),
        ),
        _StepLine(active: decided),
        Expanded(
          child: _Step(
            label: 'القرار',
            state:
                isAccepted
                    ? _StepState.done
                    : isRejected
                    ? _StepState.rejected
                    : _StepState.pending,
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, current, pending, rejected }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state});

  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Widget child) = switch (state) {
      _StepState.done => (
        AppColors.success,
        const Icon(Icons.check_rounded, color: AppColors.white, size: 16),
      ),
      _StepState.rejected => (
        AppColors.error,
        const Icon(Icons.close_rounded, color: AppColors.white, size: 16),
      ),
      _StepState.current => (
        AppColors.primary,
        Text(
          '2',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      _StepState.pending => (
        AppColors.border,
        Text(
          '3',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    };

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: active ? AppColors.success : AppColors.border,
    );
  }
}
