import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/session/user_session_cubit.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/refresh_on_tab_visible.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../domain/entities/group_invitation.dart';
import '../../domain/entities/student_group.dart';
import '../cubit/groups_cubit.dart';
import '../cubit/groups_state.dart';

/// شاشة الغروبات: عرض غروب المستخدم الحالي (إن وُجد)، إنشاء/الانضمام
/// بكود، وطلبات الانضمام المعلّقة (تظهر فقط لقائد الغروب).
///
/// ملاحظة مهمة عن الفرق عن التصميم الوهمي القديم: الانضمام هنا "سحب"
/// وليس "دفعاً" — الطالب هو من يطلب الانضمام بالكود، والقائد هو من
/// يوافق أو يرفض، وليس العكس. كما لا يوجد "نقل قيادة يدوي": لو غادر
/// القائد وبقي أعضاء، تُنقل القيادة تلقائياً لأقدم عضو من جهة الباك إند.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupsCubit(GroupsRepositoryImpl())..fetchMyGroup(),
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

    final confirmed = await confirmAction(
      context,
      title: 'إرسال طلب انضمام',
      message: 'هل تريد إرسال طلب انضمام للغروب بالكود "$code"؟',
      confirmLabel: 'إرسال',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSubmitting = true);
    final result = await cubit.joinGroupByCode(code);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (result.isSuccess) _joinCodeController.clear();
    _showMessage(
      result.isSuccess
          ? 'تم إرسال طلب الانضمام، بانتظار موافقة قائد الغروب.'
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleRespond(
    GroupsCubit cubit,
    GroupInvitation invitation,
    bool approve,
  ) async {
    final result = await cubit.respondToInvitation(
      invitationId: invitation.id,
      approve: approve,
    );
    if (!mounted) return;
    _showMessage(
      result.isSuccess
          ? (approve ? 'تم قبول طلب الانضمام.' : 'تم رفض طلب الانضمام.')
          : result.failureOrNull!.message,
    );
  }

  Future<void> _handleLeaveGroup(GroupsCubit cubit) async {
    final confirmed = await confirmAction(
      context,
      title: 'مغادرة الغروب',
      message: 'هل أنت متأكد أنك تريد مغادرة الغروب؟',
      confirmLabel: 'مغادرة',
    );
    if (!confirmed || !mounted) return;

    final result = await cubit.leaveGroup();
    if (!mounted) return;
    _showMessage(
      result.isSuccess ? 'تم مغادرة الغروب.' : result.failureOrNull!.message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<UserSessionCubit>().state?.id;

    return RefreshOnTabVisible(
      onVisible: () => context.read<GroupsCubit>().fetchMyGroup(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const GradientHeader(
              title: 'الغروبات',
              subtitle: 'إدارة غروبك وطلبات الانضمام',
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
                      onRetry: cubit.fetchMyGroup,
                    ),
                    GroupsSuccess(:final myGroup) => RefreshIndicator(
                      onRefresh: cubit.fetchMyGroup,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        children: [
                          if (myGroup != null) ...[
                            _MyGroupCard(
                              group: myGroup,
                              myId: myId,
                              onLeave: () => _handleLeaveGroup(cubit),
                            ),
                            if (myGroup.isLeader(myId)) ...[
                              const SizedBox(height: 24),
                              _PendingInvitationsSection(
                                invitations:
                                    myGroup.pendingInvitations
                                        .where(
                                          (i) =>
                                              i.status ==
                                              InvitationStatus.pending,
                                        )
                                        .toList(),
                                onRespond:
                                    (invitation, approve) => _handleRespond(
                                      cubit,
                                      invitation,
                                      approve,
                                    ),
                              ),
                            ],
                          ] else ...[
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
      ),
    );
  }
}

class _MyGroupCard extends StatelessWidget {
  const _MyGroupCard({
    required this.group,
    required this.myId,
    required this.onLeave,
  });

  final StudentGroup group;
  final String? myId;
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
                group.status.label,
                style: theme.textTheme.bodySmall?.copyWith(
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
                      'كود الغروب — شاركه لدعوة زملائك',
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
          for (var i = 0; i < group.memberStudentIds.length; i++)
            _MemberRow(
              index: i,
              isMe: group.memberStudentIds[i] == myId,
              isLeader: group.memberStudentIds[i] == group.leaderId,
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

/// صف عضو واحد — لا تُرجع الخدمة أسماء الأعضاء إطلاقاً (معرّفات فقط،
/// ولا نقطة نهاية متاحة للتطبيق لتحويلها لأسماء)، فنعرض "أنت"/"عضو" بدل
/// اسم حقيقي.
class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.index,
    required this.isMe,
    required this.isLeader,
  });

  final int index;
  final bool isMe;
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isMe ? 'أنت' : 'عضو ${index + 1}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySubtle,
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isLeader) ...[
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
    );
  }
}

class _PendingInvitationsSection extends StatelessWidget {
  const _PendingInvitationsSection({
    required this.invitations,
    required this.onRespond,
  });

  final List<GroupInvitation> invitations;
  final void Function(GroupInvitation invitation, bool approve) onRespond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'طلبات انضمام معلّقة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (invitations.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${invitations.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (invitations.isEmpty)
          Text(
            'لا توجد طلبات انضمام معلّقة حالياً.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          for (final invitation in invitations) ...[
            _InvitationCard(
              invitation: invitation,
              onAccept: () => onRespond(invitation, true),
              onDecline: () => onRespond(invitation, false),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  final GroupInvitation invitation;
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
                  'طلب انضمام طالب',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'رقم الطلب #${invitation.id}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySubtle,
            child: Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.primaryDark,
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
            'أنشئ غروباً جديداً وشارك الكود مع زملائك، أو أرسل طلب انضمام بكود غروب موجود.',
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
            'إرسال طلب انضمام بكود',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'سيبقى طلبك بانتظار موافقة قائد الغروب.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
                  label: 'إرسال',
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
