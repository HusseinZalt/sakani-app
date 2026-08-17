import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../cubit/create_maintenance_cubit.dart';
import '../cubit/create_maintenance_state.dart';
import '../maintenance_labels.dart';

/// شاشة إضافة طلب خدمة جديد: اختيار نوع الخدمة، وصف المشكلة، وإرفاق صورة
/// اختيارية — مطابقة للشاشة 13 من التصميم المعتمد.
class CreateMaintenanceScreen extends StatelessWidget {
  const CreateMaintenanceScreen({super.key, this.initialCategory});

  /// تصنيف مبدئي يُمرَّر عند الضغط على إحدى بطاقات الشبكة في شاشة القائمة.
  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateMaintenanceCubit(MaintenanceRepositoryImpl()),
      child: _CreateMaintenanceView(initialCategory: initialCategory),
    );
  }
}

class _CreateMaintenanceView extends StatefulWidget {
  const _CreateMaintenanceView({this.initialCategory});

  final String? initialCategory;

  @override
  State<_CreateMaintenanceView> createState() => _CreateMaintenanceViewState();
}

class _CreateMaintenanceViewState extends State<_CreateMaintenanceView> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late String _category =
      widget.initialCategory ?? MaintenanceLabels.categories.keys.first;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateMaintenanceCubit>().submit(
      description: _descriptionController.text.trim(),
      category: _category,
    );
  }

  Future<void> _showImageSourceSheet(BuildContext context) async {
    final cubit = context.read<CreateMaintenanceCubit>();

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
                  await cubit.pickImage(ImageSource.camera);
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
                  await cubit.pickImage(ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GradientHeader(
              title: 'طلب خدمة جديدة',
              subtitle: 'اختر نوع الخدمة واكتب التفاصيل',
              onBack: () => context.pop(),
            ),
            Expanded(
              child:
                  BlocConsumer<CreateMaintenanceCubit, CreateMaintenanceState>(
                    listener: (context, state) {
                      switch (state.status) {
                        case CreateMaintenanceStatus.success:
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('تم إرسال طلب الخدمة بنجاح.'),
                              ),
                            );
                          context.pop(true);
                        case CreateMaintenanceStatus.failure:
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.errorMessage ?? 'حدث خطأ غير متوقع',
                                ),
                              ),
                            );
                        case CreateMaintenanceStatus.idle:
                        case CreateMaintenanceStatus.submitting:
                          break;
                      }
                    },
                    builder: (context, state) {
                      final isSubmitting =
                          state.status == CreateMaintenanceStatus.submitting;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'نوع الخدمة',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              _buildCategoryGrid(isSubmitting),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _descriptionController,
                                label: 'وصف المشكلة',
                                hint: 'اشرح المشكلة بالتفصيل...',
                                enabled: !isSubmitting,
                                maxLines: 6,
                                minLines: 4,
                                validator:
                                    (value) =>
                                        (value == null ||
                                                value.trim().length < 10)
                                            ? 'يرجى كتابة وصف لا يقل عن 10 أحرف'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'إرفاق صورة (اختياري)',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              _buildImagePicker(context, state, isSubmitting),
                              const SizedBox(height: 28),
                              CustomButton(
                                label: 'إرسال الطلب',
                                icon: Icons.build_outlined,
                                isLoading: isSubmitting,
                                onPressed: () => _submit(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isSubmitting) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.95,
      children:
          MaintenanceLabels.categories.entries.map((entry) {
            final info = entry.value;
            final selected = _category == entry.key;

            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap:
                  isSubmitting
                      ? null
                      : () => setState(() => _category = entry.key),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySubtle : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.borderSubtle,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: info.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(info.icon, color: info.iconColor, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      info.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildImagePicker(
    BuildContext context,
    CreateMaintenanceState state,
    bool isSubmitting,
  ) {
    if (state.hasImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.memory(
              state.pickedImageBytes!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: InkWell(
              onTap:
                  isSubmitting
                      ? null
                      : () =>
                          context.read<CreateMaintenanceCubit>().removeImage(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.overlay,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: isSubmitting ? null : () => _showImageSourceSheet(context),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.textHint),
            const SizedBox(height: 6),
            Text('إضافة صورة', style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
