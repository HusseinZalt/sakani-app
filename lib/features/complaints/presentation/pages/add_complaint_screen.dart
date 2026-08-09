import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
  String _type = 'complaint';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<CreateComplaintCubit>().submit(
      type: _type,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                      ..showSnackBar(SnackBar(content: Text(failure.message)));
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
                                          : () =>
                                              setState(() => _type = entry.key),
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
    );
  }
}
