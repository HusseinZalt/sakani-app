import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/complaints_repository_impl.dart';
import '../cubit/create_complaint_cubit.dart';
import '../cubit/create_complaint_state.dart';
import '../complaints_labels.dart';

/// شاشة تقديم شكوى أو اقتراح جديد — مطابقة للشاشة 14 من التصميم المعتمد.
class AddComplaintScreen extends StatelessWidget {
  const AddComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateComplaintCubit(ComplaintsRepositoryImpl()),
      child: const _AddComplaintView(),
    );
  }
}

class _AddComplaintView extends StatefulWidget {
  const _AddComplaintView();

  @override
  State<_AddComplaintView> createState() => _AddComplaintViewState();
}

class _AddComplaintViewState extends State<_AddComplaintView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  String _type = 'complaint';
  bool _isAnonymous = false;
  final List<Uint8List> _images = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addImages() async {
    try {
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (files.isEmpty) return;
      final bytesList = await Future.wait(files.map((f) => f.readAsBytes()));
      if (!mounted) return;
      setState(() => _images.addAll(bytesList));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذر الوصول إلى معرض الصور.')),
        );
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateComplaintCubit>().submit(
      type: _type,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      isAnonymous: _isAnonymous,
      images: _images,
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
              title: 'شكوى أو اقتراح جديد',
              subtitle: 'شاركنا رأيك أو مشكلتك',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocConsumer<CreateComplaintCubit, CreateComplaintState>(
                listener: (context, state) {
                  switch (state) {
                    case CreateComplaintSuccess():
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('تم الإرسال بنجاح.')),
                        );
                      context.pop(true);
                    case CreateComplaintFailure(:final failure):
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        );
                    case CreateComplaintIdle():
                    case CreateComplaintSubmitting():
                      break;
                  }
                },
                builder: (context, state) {
                  final isSubmitting = state is CreateComplaintSubmitting;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'النوع',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children:
                                ComplaintsLabels.types.entries.map((entry) {
                                  return CustomChip(
                                    label: entry.value,
                                    selected: _type == entry.key,
                                    onTap:
                                        isSubmitting
                                            ? null
                                            : () => setState(
                                              () => _type = entry.key,
                                            ),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _titleController,
                            label: 'العنوان',
                            hint: 'مثال: مشكلة في التكييف',
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            validator:
                                (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'يرجى إدخال العنوان'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _descriptionController,
                            label: 'الوصف',
                            hint: 'اشرح المشكلة أو الاقتراح بالتفصيل...',
                            enabled: !isSubmitting,
                            maxLines: 7,
                            minLines: 5,
                            validator:
                                (value) =>
                                    (value == null || value.trim().length < 10)
                                        ? 'يرجى كتابة وصف لا يقل عن 10 أحرف'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _isAnonymous,
                            onChanged:
                                isSubmitting
                                    ? null
                                    : (value) =>
                                        setState(() => _isAnonymous = value),
                            title: const Text('تقديم بشكل مجهول'),
                            subtitle: const Text(
                              'لن يظهر اسمك للإدارة عند مراجعة هذا الطلب',
                            ),
                            activeColor: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'صور مرفقة (اختياري)',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var i = 0; i < _images.length; i++)
                                _AttachedImageThumb(
                                  bytes: _images[i],
                                  onRemove:
                                      isSubmitting
                                          ? null
                                          : () => setState(
                                            () => _images.removeAt(i),
                                          ),
                                ),
                              _AddImageTile(
                                onTap: isSubmitting ? null : _addImages,
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          CustomButton(
                            label: 'إرسال',
                            icon: Icons.outlined_flag_rounded,
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
}

class _AttachedImageThumb extends StatelessWidget {
  const _AttachedImageThumb({required this.bytes, required this.onRemove});

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.memory(bytes, width: 72, height: 72, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          left: -6,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
