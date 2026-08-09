import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/register_data.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';
import 'otp_verification_screen.dart';

// ⚠️ تحذير مهم غير محلول: تأكيد فعلي عبر الـ API (2026-08-09) أن الخادم
// يقبل `university` بقيم 0..15 (16 جامعة)، بينما هذه القائمة تحتوي 9 فقط.
// الجامعات 9-15 غير معروفة الاسم/الترتيب الصحيح من التوثيق المتاح، ولا يوجد
// endpoint يُرجع القائمة الكاملة. يجب الحصول على القائمة الكاملة الرسمية
// (بنفس ترتيب الفهرسة) من فريق الباك إند قبل اعتماد هذه القائمة كنهائية،
// وإلا فبعض الطلاب لن يجدوا جامعتهم، وربما تُسجَّل فهارس 0-8 الحالية بترتيب
// مختلف عمّا يتوقعه الخادم فعلياً.
const _kUniversities = [
  'جامعة دمشق',
  'جامعة حلب',
  'جامعة (اللاذقية)',
  'جامعة (حمص)',
  'جامعة الفرات',
  'جامعة حماة',
  'جامعة طرطوس',
  'الجامعة الافتراضية السورية',
  'جامعة إدلب',
];

const _kStudyYears = {
  'أولى': 1,
  'ثانية': 2,
  'ثالثة': 3,
  'رابعة': 4,
  'خامسة': 5,
  'سادسة': 6,
};

/// شاشة إنشاء حساب جديد على خطوتين، مطابقة للشاشتين 9 و10 من التصميم
/// المعتمد في مجلد `UI/`: بيانات أساسية، ثم معلومات جامعية وهوية.
///
/// عند إكمال الخطوة الثانية يتم إرسال رمز تأكيد (OTP) والانتقال إلى شاشة
/// التحقق، بنفس تدفق شاشة تسجيل الدخول.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterCubit(AuthRepositoryImpl()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  int _step = 0;
  final _scrollController = ScrollController();

  // خطوة 1
  final _step1FormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // خطوة 2
  final _step2FormKey = GlobalKey<FormState>();
  final _universityIdController = TextEditingController();
  final _universityController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _cityController = TextEditingController();
  String _studyYear = 'ثانية';
  String _gender = 'male';
  int? _selectedUniversityIndex;

  final _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  Uint8List? _idFrontBytes;
  Uint8List? _idBackBytes;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _universityIdController.dispose();
    _universityController.dispose();
    _nationalIdController.dispose();
    _nationalityController.dispose();
    _cityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// إعادة الشاشة لأعلى فور تبديل الخطوة، حتى لا يبقى القارئ عند موضع
  /// التمرير الذي وصلت إليه الخطوة السابقة (بما أن الخطوتين تشتركان بنفس
  /// عنصر التمرير).
  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('كلمتا المرور غير متطابقتين.')),
        );
      return;
    }
    setState(() => _step = 1);
    _resetScroll();
  }

  void _goToStep1() {
    setState(() => _step = 0);
    _resetScroll();
  }

  /// عرض خيارات مصدر الصورة (كاميرا/معرض) عبر قائمة سفلية، ثم اختيار الصورة.
  ///
  /// ملاحظة: يجب استدعاء `pickImage` من داخل معالج ضغط (tap handler) مباشر
  /// حتى تسمح المتصفحات بفتح نافذة اختيار الملف؛ لذلك يتم استدعاؤها من
  /// onTap الخاص بعنصر القائمة السفلية نفسه، وليس بعد إغلاقها.
  Future<void> _pickImage(ValueChanged<Uint8List> onPicked) async {
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
                onTap:
                    () => _capture(sheetContext, ImageSource.camera, onPicked),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('اختيار من المعرض'),
                onTap:
                    () => _capture(sheetContext, ImageSource.gallery, onPicked),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capture(
    BuildContext sheetContext,
    ImageSource source,
    ValueChanged<Uint8List> onPicked,
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
      onPicked(bytes);
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

  Future<void> _pickUniversity() async {
    final selectedIndex = await showModalBottomSheet<int>(
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
              Text(
                'اختر الجامعة',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < _kUniversities.length; i++)
                      ListTile(
                        title: Text(_kUniversities[i]),
                        onTap: () => Navigator.of(sheetContext).pop(i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (selectedIndex != null) {
      setState(() {
        _selectedUniversityIndex = selectedIndex;
        _universityController.text = _kUniversities[selectedIndex];
      });
    }
  }

  void _submit() {
    if (!_step2FormKey.currentState!.validate()) return;

    if (_avatarBytes == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('يرجى إرفاق صورة شخصية.')));
      return;
    }
    if (_idFrontBytes == null || _idBackBytes == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('يرجى إرفاق صورة الهوية من الوجهين (الوجه والظهر).'),
          ),
        );
      return;
    }
    if (_selectedUniversityIndex == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('يرجى اختيار الجامعة.')));
      return;
    }

    final data = RegisterData(
      firstName: _firstNameController.text.trim(),
      secondName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      gender: _gender,
      universityIndex: _selectedUniversityIndex!,
      nationalId: _nationalIdController.text.trim(),
      studyYear: _kStudyYears[_studyYear]!,
      personalPhoto: _avatarBytes!,
      idFrontPhoto: _idFrontBytes!,
      idBackPhoto: _idBackBytes!,
      studentNumber: _universityIdController.text.trim(),
      nationality: _nationalityController.text.trim(),
      residence: _cityController.text.trim(),
    );

    context.read<RegisterCubit>().register(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<RegisterCubit, RegisterState>(
        listener: (context, state) {
          switch (state) {
            case RegisterOtpSent(:final identifier):
              context.pushReplacementNamed(
                AppRoutes.otp,
                extra: OtpRouteArgs(
                  identifier: identifier,
                  password: _passwordController.text,
                ),
              );
            case RegisterFailureState(:final failure):
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(failure.message)));
            case RegisterInitial():
            case RegisterLoading():
              break;
          }
        },
        builder: (context, state) {
          final isLoading = state is RegisterLoading;

          return Column(
            children: [
              GradientHeader(
                title: _step == 0 ? 'إنشاء حساب جديد' : 'إكمال المعلومات',
                subtitle:
                    _step == 0
                        ? 'أدخل بياناتك الأساسية للبدء'
                        : 'معلومات جامعتك وهويتك',
                onBack: _step == 1 ? _goToStep1 : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StepperLine(currentStep: _step),
                      const SizedBox(height: 18),
                      if (_step == 0)
                        _buildStep1(isLoading)
                      else
                        _buildStep2(isLoading),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStep1(bool isLoading) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _firstNameController,
            label: 'الاسم الأول',
            hint: 'أحمد',
            prefixIcon: Icons.person_outline_rounded,
            enabled: !isLoading,
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
            hint: 'محمد',
            prefixIcon: Icons.person_outline_rounded,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال الاسم الأخير'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@university.edu',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
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
            controller: _phoneController,
            label: 'رقم الجوال',
            hint: '+963xxxxxxxxx',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || !RegExp(r'^\+?\d{9,13}$').hasMatch(v.trim()))
                        ? 'يرجى إدخال رقم جوال صحيح'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _passwordController,
            label: 'كلمة المرور',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            enabled: !isLoading,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
              if (v.length < 6) return 'يجب ألا تقل كلمة المرور عن 6 أحرف';
              return null;
            },
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'تأكيد كلمة المرور',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            enabled: !isLoading,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _goToStep2(),
            validator:
                (v) =>
                    (v == null || v.isEmpty) ? 'يرجى تأكيد كلمة المرور' : null,
          ),
          const SizedBox(height: 22),
          CustomButton(
            label: 'التالي',
            icon: Icons.arrow_forward_rounded,
            onPressed: _goToStep2,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لديك حساب؟',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(bool isLoading) {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _AvatarPicker(
              imageBytes: _avatarBytes,
              onTap:
                  () => _pickImage(
                    (bytes) => setState(() => _avatarBytes = bytes),
                  ),
            ),
          ),
          const SizedBox(height: 22),
          Text('الجنس', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomChip(
                  label: 'ذكر',
                  selected: _gender == 'male',
                  onTap:
                      isLoading ? null : () => setState(() => _gender = 'male'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomChip(
                  label: 'أنثى',
                  selected: _gender == 'female',
                  onTap:
                      isLoading
                          ? null
                          : () => setState(() => _gender = 'female'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _universityIdController,
            label: 'الرقم الجامعي',
            hint: '442100',
            prefixIcon: Icons.badge_outlined,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال الرقم الجامعي'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _universityController,
            label: 'الجامعة',
            hint: 'اختر الجامعة',
            prefixIcon: Icons.keyboard_arrow_down_rounded,
            readOnly: true,
            enabled: !isLoading,
            onTap: _pickUniversity,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى اختيار الجامعة'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _nationalIdController,
            label: 'رقم الهوية الوطنية / الإقامة',
            hint: '02xxxxxxxxx',
            enabled: !isLoading,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال رقم الهوية'
                        : null,
          ),
          const SizedBox(height: 16),
          Text('سنة الدراسة', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _kStudyYears.keys.map((year) {
                  return CustomChip(
                    label: year,
                    selected: _studyYear == year,
                    onTap:
                        isLoading
                            ? null
                            : () => setState(() => _studyYear = year),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _nationalityController,
            label: 'الجنسية',
            hint: 'سوري',
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال الجنسية'
                        : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _cityController,
            label: 'مكان الإقامة',
            hint: 'المدينة',
            prefixIcon: Icons.location_on_outlined,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            validator:
                (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال مكان الإقامة'
                        : null,
          ),
          const SizedBox(height: 18),
          Text('صورة الهوية', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _IdPhotoBox(
                  label: 'الوجه',
                  imageBytes: _idFrontBytes,
                  onTap:
                      () => _pickImage(
                        (bytes) => setState(() => _idFrontBytes = bytes),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IdPhotoBox(
                  label: 'الظهر',
                  imageBytes: _idBackBytes,
                  onTap:
                      () => _pickImage(
                        (bytes) => setState(() => _idBackBytes = bytes),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          CustomButton(
            label: 'إكمال التسجيل',
            icon: Icons.check_rounded,
            isLoading: isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _StepperLine extends StatelessWidget {
  const _StepperLine({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _segment(done: true)),
        const SizedBox(width: 6),
        Expanded(child: _segment(done: currentStep >= 1)),
      ],
    );
  }

  Widget _segment({required bool done}) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: done ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.onTap, this.imageBytes});

  final VoidCallback onTap;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Stack(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(
                color: AppColors.border,
                width: 1.5,
                style: BorderStyle.solid,
              ),
              image:
                  imageBytes != null
                      ? DecorationImage(
                        image: MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                imageBytes == null
                    ? Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textHint,
                      size: 30,
                    )
                    : null,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2.5),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdPhotoBox extends StatelessWidget {
  const _IdPhotoBox({
    required this.label,
    required this.onTap,
    this.imageBytes,
  });

  final String label;
  final VoidCallback onTap;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border, width: 1.5),
          image:
              imageBytes != null
                  ? DecorationImage(
                    image: MemoryImage(imageBytes!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            imageBytes == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined, color: AppColors.textHint),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
                : null,
      ),
    );
  }
}
