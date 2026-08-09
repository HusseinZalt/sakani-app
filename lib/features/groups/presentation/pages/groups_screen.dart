import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/student_group.dart';
import '../cubit/groups_cubit.dart';
import '../cubit/groups_state.dart';

/// شاشة الغروبات: عرض غروب المستخدم الحالي (إن وُجد)، الانضمام بكود،
/// ودعوات الانضمام المعلّقة — مطابقة للشاشتين 3 و15 من التصميم المعتمد.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupsCubit(GroupsRepositoryImpl())..fetchGroupsData(),
      child: const _GroupsView(),
    );
  }
}

class _GroupsView extends StatefulWidget {
  const _GroupsView();

  @override
  State<_GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<_GroupsView> {
  final _joinCodeController = TextEditingController();

  // يمنع الضغط المزدوج على "إنشاء غروب" أو "انضمام" أثناء تنفيذ الطلب
  // (700ms محاكاة شبكة)، والذي كان يسمح بإرسال الطلب مرتين فيظهر خطأ
  // مربك للمستخدم رغم نجاح المحاولة الأولى فعلياً.
  bool _isSubmitting = false;

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCreateGroup(GroupsCubit cubit) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await cubit.createGroup();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showMessage(
      result.isSuccess
          ? 'تم إنشاء الغروب بنجاح.'
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleJoinByCode(GroupsCubit cubit) async {
    if (_isSubmitting) return;
    final code = _joinCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    final result = await cubit.joinGroupByCode(code);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result.isSuccess) _joinCodeController.clear();
    _showMessage(
      result.isSuccess
          ? 'تم الانضمام إلى الغروب بنجاح.'
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleInviteMember(GroupsCubit cubit) async {
    final controller = TextEditingController();
    final identifier = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'دعوة عضو جديد',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: controller,
                  label: 'البريد الإلكتروني أو رقم الجوال',
                  hint: 'example@university.edu',
                  prefixIcon: Icons.person_add_alt_1_outlined,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'إرسال الدعوة',
                  onPressed:
                      () => Navigator.of(
                        sheetContext,
                      ).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (identifier == null || identifier.isEmpty || !mounted) return;
    final result = await cubit.inviteMember(identifier);
    if (!mounted) return;
    _showMessage(
      result.isSuccess
          ? 'تم إرسال الدعوة بنجاح.'
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleAcceptInvite(
    GroupsCubit cubit,
    GroupInvite invite,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmJoinDialog(invite: invite),
    );
    if (confirmed != true || !mounted) return;

    final result = await cubit.acceptInvite(invite.id);
    if (!mounted) return;
    _showMessage(
      result.isSuccess
          ? 'تم الانضمام إلى ${invite.groupLabel} بنجاح.'
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleDeclineInvite(
    GroupsCubit cubit,
    GroupInvite invite,
  ) async {
    final result = await cubit.declineInvite(invite.id);
    if (!mounted) return;
    _showMessage(
      result.isSuccess ? 'تم رفض الدعوة.' : result.failureOrNull!.message,
    );
  }

  Future<void> _handleLeaveGroup(GroupsCubit cubit, StudentGroup group) async {
    final myId = context.read<UserSessionCubit>().state?.id;
    final isLeader = group.members.any((m) => m.id == myId && m.isLeader);
    final otherMembers = group.members.where((m) => m.id != myId).toList();

    if (isLeader && otherMembers.isNotEmpty) {
      final newLeaderId = await showDialog<String>(
        context: context,
        builder:
            (dialogContext) => _TransferLeadershipDialog(members: otherMembers),
      );
      if (newLeaderId == null || !mounted) return;

      final transferResult = await cubit.transferLeadership(newLeaderId);
      if (!mounted) return;
      if (!transferResult.isSuccess) {
        _showMessage(transferResult.failureOrNull!.message);
        return;
      }

      final leaveResult = await cubit.leaveGroup();
      if (!mounted) return;
      _showMessage(
        leaveResult.isSuccess
            ? 'تم نقل القيادة ومغادرة الغروب بنجاح.'
            : leaveResult.failureOrNull!.message,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('مغادرة الغروب'),
            content: const Text('هل أنت متأكد أنك تريد مغادرة الغروب؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'مغادرة',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final result = await cubit.leaveGroup();
    if (!mounted) return;
    _showMessage(
      result.isSuccess ? 'تم مغادرة الغروب.' : result.failureOrNull!.message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const GradientHeader(
            title: 'الغروبات',
            subtitle: 'إدارة غروبك ودعوات الانضمام',
          ),
          Expanded(
            child: BlocBuilder<GroupsCubit, GroupsState>(
              builder: (context, state) {
                final cubit = context.read<GroupsCubit>();

                return switch (state) {
                  GroupsInitial() || GroupsLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  GroupsFailure(:final failure) => _ErrorView(
                    message: failure.message,
                    onRetry: cubit.fetchGroupsData,
                  ),
                  GroupsSuccess(:final data) => RefreshIndicator(
                    onRefresh: cubit.fetchGroupsData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        if (data.myGroup != null)
                          _MyGroupCard(
                            group: data.myGroup!,
                            onInvite: () => _handleInviteMember(cubit),
                            onLeave:
                                () => _handleLeaveGroup(cubit, data.myGroup!),
                          )
                        else
                          _NoGroupCard(
                            isLoading: _isSubmitting,
                            onCreate: () => _handleCreateGroup(cubit),
                          ),
                        const SizedBox(height: 16),
                        _JoinByCodeCard(
                          controller: _joinCodeController,
                          isLoading: _isSubmitting,
                          onJoin: () => _handleJoinByCode(cubit),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'دعوات الانضمام',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (data.invites.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                ),
                                child: Text(
                                  '${data.invites.length}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (data.invites.isEmpty)
                          Text(
                            'لا توجد دعوات معلّقة حالياً.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          )
                        else
                          for (final invite in data.invites) ...[
                            _InviteCard(
                              invite: invite,
                              onAccept:
                                  () => _handleAcceptInvite(cubit, invite),
                              onDecline:
                                  () => _handleDeclineInvite(cubit, invite),
                            ),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ),
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

class _MyGroupCard extends StatelessWidget {
  const _MyGroupCard({
    required this.group,
    required this.onInvite,
    required this.onLeave,
  });

  final StudentGroup group;
  final VoidCallback onInvite;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFull = group.isFull;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (isFull ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 14,
                      color: isFull ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFull
                          ? '${group.memberCount} / ${group.maxMembers} أعضاء — مكتمل'
                          : '${group.memberCount} / ${group.maxMembers} أعضاء',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isFull ? AppColors.success : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'غروبي الحالي',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: group.code));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('تم نسخ كود الغروب.')),
                      );
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'نسخ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      group.code,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'كود الغروب',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'الأعضاء',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final member in group.members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primarySubtle,
                    child: Text(
                      member.initials,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (member.isLeader) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_outlined,
                              size: 12,
                              color: AppColors.secondaryDark,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'قائد الغروب',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.secondaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          CustomButton(
            label:
                isFull
                    ? 'اكتمل عدد الأعضاء (${group.memberCount}/${group.maxMembers})'
                    : 'دعوة عضو جديد',
            icon: Icons.person_add_alt_1_outlined,
            onPressed: isFull ? null : onInvite,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onLeave,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('مغادرة الغروب'),
          ),
        ],
      ),
    );
  }
}

class _NoGroupCard extends StatelessWidget {
  const _NoGroupCard({required this.onCreate, this.isLoading = false});

  final VoidCallback onCreate;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 10),
          Text(
            'لست منضماً إلى أي غروب حالياً',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'أنشئ غروباً جديداً وشارك الكود مع زملائك، أو انضم بكود غروب موجود.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'إنشاء غروب جديد',
            icon: Icons.add_rounded,
            isLoading: isLoading,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _JoinByCodeCard extends StatelessWidget {
  const _JoinByCodeCard({
    required this.controller,
    required this.onJoin,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final VoidCallback onJoin;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الانضمام بكود',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller,
                  hint: 'أدخل كود الغروب',
                  prefixIcon: Icons.search_rounded,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: CustomButton(
                  label: 'انضمام',
                  width: 100,
                  isLoading: isLoading,
                  onPressed: onJoin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.check_rounded,
            color: AppColors.success,
            background: AppColors.successBackground,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.close_rounded,
            color: AppColors.error,
            background: AppColors.errorBackground,
            onTap: onDecline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دعوة من ${invite.fromUserName}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invite.groupLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.successBackground,
            child: Text(
              invite.fromUserName.isNotEmpty
                  ? invite.fromUserName.substring(0, 1)
                  : '',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _TransferLeadershipDialog extends StatelessWidget {
  const _TransferLeadershipDialog({required this.members});

  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'نقل القيادة',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بما أنك قائد الغروب، يجب اختيار قائد جديد قبل مغادرتك.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            for (final member in members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySubtle,
                  child: Text(
                    member.initials,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  member.name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_left,
                  color: AppColors.textHint,
                ),
                onTap: () => Navigator.of(context).pop(member.id),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmJoinDialog extends StatelessWidget {
  const _ConfirmJoinDialog({required this.invite});

  final GroupInvite invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'تأكيد قبول الدعوة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'هل أنت متأكد أنك تريد الانضمام إلى ${invite.groupLabel} بدعوة من ${invite.fromUserName}؟ سيتم إخراجك من أي غروب حالي.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomButton(
                    label: 'تأكيد',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
