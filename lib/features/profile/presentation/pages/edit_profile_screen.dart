import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/utils/avatar_image.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';

/// شاشة تعديل البيانات الشخصية — مطابقة للشاشة 17 من التصميم المعتمد.
///
/// تقرأ القيم الابتدائية من [UserSessionCubit] وتكتب التعديلات إليه فعلياً
/// عند الحفظ، بحيث تنعكس فوراً في كل شاشة أخرى تعرض بيانات المستخدم
/// (الرئيسية، الملف الشخصي) لأنها جميعاً تراقب نفس المصدر.
///
/// تفصل بين البيانات القابلة للتعديل والبيانات الثابتة (الرقم الجامعي
/// والهوية الوطنية) التي تتطلب التواصل مع إدارة السكن لتعديلها.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  bool _isSaving = false;

  final _imagePicker = ImagePicker();
  Uint8List? _newAvatarBytes;

  @override
  void initState() {
    super.initState();

    final user = context.read<UserSessionCubit>().state;
    final nameParts = (user?.fullName ?? '').trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  /// عرض خيارات مصدر الصورة (كاميرا/معرض) ثم اختيار الصورة، بنفس نمط شاشة
  /// إنشاء الحساب: يجب استدعاء `pickImage` من داخل معالج الضغط مباشرة حتى
  /// تسمح المتصفحات بفتح نافذة الاختيار.
  Future<void> _pickAvatar() async {
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
                onTap: () => _captureAvatar(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('اختيار من المعرض'),
                onTap: () => _captureAvatar(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureAvatar(
    BuildContext sheetContext,
    ImageSource source,
  ) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _newAvatarBytes = bytes);
    } catch (_) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر الوصول إلى الصورة، يرجى التحقق من صلاحيات الكاميرا/المعرض.',
              ),
            ),
          );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sessionCubit = context.read<UserSessionCubit>();
    final currentUser = sessionCubit.state;
    if (currentUser == null) return;

    setState(() => _isSaving = true);
    // TODO: استبدال هذا التأخير الوهمي باستدعاء فعلي لتحديث بيانات الملف
    // الشخصي عبر الباك إند عند ربطه.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isSaving = false);

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();
    sessionCubit.setUser(
      currentUser.copyWith(
        fullName: fullName,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        avatarUrl:
            _newAvatarBytes != null
                ? bytesToAvatarDataUri(_newAvatarBytes!)
                : currentUser.avatarUrl,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserSessionCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(title: 'تعديل البيانات', onBack: () => context.pop()),
          Expanded(
            child:
                user == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: _pickAvatar,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 42,
                                          backgroundColor:
                                              AppColors.primarySubtle,
                                          backgroundImage:
                                              _newAvatarBytes != null
                                                  ? MemoryImage(
                                                    _newAvatarBytes!,
                                                  )
                                                  : (user.avatarUrl != null
                                                      ? avatarImageProvider(
                                                        user.avatarUrl!,
                                                      )
                                                      : null),
                                          child:
                                              _newAvatarBytes == null &&
                                                      user.avatarUrl == null
                                                  ? const Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    color:
                                                        AppColors.primaryDark,
                                                    size: 34,
                                                  )
                                                  : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.surface,
                                                width: 3,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_rounded,
                                              color: AppColors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'تغيير الصورة الشخصية',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'البيانات القابلة للتعديل',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _firstNameController,
                              label: 'الاسم الأول',
                              prefixIcon: Icons.edit_outlined,
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'يرجى إدخال الاسم الأول'
                                          : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _lastNameController,
                              label: 'الاسم الأخير',
                              prefixIcon: Icons.edit_outlined,
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'يرجى إدخال الاسم الأخير'
                                          : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _phoneController,
                              label: 'رقم الجوال',
                              prefixIcon: Icons.phone_outlined,
                              enabled: !_isSaving,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              textInputAction: TextInputAction.next,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'يرجى إدخال رقم الجوال'
                                          : null,
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _emailController,
                              label: 'البريد الإلكتروني',
                              prefixIcon: Icons.email_outlined,
                              enabled: !_isSaving,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                final trimmed = v?.trim() ?? '';
                                if (trimmed.isEmpty) {
                                  return 'يرجى إدخال البريد الإلكتروني';
                                }
                                if (!trimmed.contains('@')) {
                                  return 'صيغة البريد الإلكتروني غير صحيحة';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              controller: _cityController,
                              label: 'مكان الإقامة',
                              prefixIcon: Icons.location_on_outlined,
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.done,
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'يرجى إدخال مكان الإقامة'
                                          : null,
                            ),
                            if (user.studentId != null ||
                                user.nationalId != null) ...[
                              const SizedBox(height: 22),
                              Text(
                                'بيانات ثابتة (غير قابلة للتعديل)',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  color: AppColors.textHint,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (user.studentId != null) ...[
                                _LockedField(
                                  label: 'الرقم الجامعي',
                                  value: user.studentId!,
                                  note: 'للتعديل تواصل مع إدارة السكن',
                                ),
                                if (user.nationalId != null)
                                  const SizedBox(height: 14),
                              ],
                              if (user.nationalId != null)
                                _LockedField(
                                  label: 'الرقم الوطني / الإقامة',
                                  value: user.nationalId!,
                                ),
                            ],
                            const SizedBox(height: 28),
                            CustomButton(
                              label: 'حفظ التغييرات',
                              icon: Icons.check_rounded,
                              isLoading: _isSaving,
                              onPressed: _save,
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                note!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
