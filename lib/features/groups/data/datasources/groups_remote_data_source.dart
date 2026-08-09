import '../../../../core/network/api_result.dart';
import '../../../../core/session/session_storage.dart';
import '../models/group_models.dart';

/// استثناء مخصص لطبقة الـ Data يحمل رسالة عربية واضحة ونوع الخطأ المناسب،
/// ليتم تحويله لاحقاً إلى [ApiFailure] داخل الـ Repository.
class GroupsException implements Exception {
  const GroupsException(this.message, {this.type = ApiErrorType.badRequest});

  final String message;
  final ApiErrorType type;
}

/// مصدر بيانات الغروبات.
///
/// ==================================================================
/// **نقطة الربط مع الباك إند:** هذا التنفيذ وهمي بالكامل حالياً (بيانات
/// مشتركة (static) في الذاكرة + محاكاة زمن استجابة الشبكة) نظراً لعدم
/// جاهزية الباك إند بعد. عند الربط الحقيقي، يكفي استبدال محتوى هذا الملف
/// بطلبات HTTP فعلية دون أي تعديل على الـ Repository أو الـ Cubit أو
/// الشاشة، لأن جميعها تعتمد على العقد المجرّد [GroupsRepository] فقط.
/// ==================================================================
class GroupsRemoteDataSource {
  static const _networkDelay = Duration(milliseconds: 700);

  /// معرّف/اسم وهميان يُستخدَمان لبذر بيانات العرض التجريبي فقط (قبل معرفة
  /// هوية المستخدم الحقيقي المسجَّل دخوله)، ثم يُستبدَلان بالهوية الحقيقية
  /// في [_ensureCurrentUser] بمجرد توفرها، حتى تتطابق شاشة الغروبات مع
  /// المستخدم الفعلي بدل شخصية وهمية منفصلة تماماً عنه.
  static const _placeholderUserId = 'usr_1001';
  static const _placeholderUserName = 'أحمد محمد';

  static String? _currentUserId;
  static String? _currentUserName;
  static bool _seedPatched = false;
  static int _codeCounter = 1002;

  /// مخزّن وهمي مشترك (static) لكل الغروبات المعروفة، بما فيها غروب أخرى
  /// قابلة للانضمام إليها بالكود لأغراض الاختبار.
  static final Map<String, StudentGroupModel> _groups = {
    'grp_a204': const StudentGroupModel(
      id: 'grp_a204',
      code: 'GRP-2025-A204',
      maxMembers: 4,
      members: [
        GroupMemberModel(
          id: _placeholderUserId,
          name: _placeholderUserName,
          isLeader: true,
        ),
        GroupMemberModel(id: 'usr_2001', name: 'خالد سعيد', isLeader: false),
        GroupMemberModel(id: 'usr_2002', name: 'عمر فهد', isLeader: false),
        GroupMemberModel(id: 'usr_2003', name: 'يوسف علي', isLeader: false),
      ],
    ),
    'grp_b112': const StudentGroupModel(
      id: 'grp_b112',
      code: 'GRP-2025-B112',
      maxMembers: 4,
      members: [
        GroupMemberModel(id: 'usr_3001', name: 'محمد أحمد', isLeader: true),
        GroupMemberModel(id: 'usr_3002', name: 'سلطان ناصر', isLeader: false),
        GroupMemberModel(id: 'usr_3003', name: 'فيصل عبدالله', isLeader: false),
      ],
    ),
  };

  static String? _currentUserGroupId = 'grp_a204';

  static final List<GroupInviteModel> _invites = [
    const GroupInviteModel(
      id: 'inv_1',
      groupId: 'grp_b112',
      groupLabel: 'غروب الوحدة ب',
      fromUserName: 'محمد أحمد',
    ),
  ];

  /// يحمّل هوية المستخدم الحقيقي الحالي (مرة واحدة فقط) من الجلسة، ويستبدل
  /// بها عضو البذر الوهمي في الغروب التجريبي، حتى تتوافق مقارنات "هل أنا
  /// القائد؟" ضمن هذا المصدر الوهمي مع المستخدم المسجَّل دخوله فعلياً بدل
  /// شخصية وهمية منفصلة تماماً عنه (كانت تمنع القائد من مغادرة الغروب أبداً
  /// وتُظهر اسماً وهمياً بدل اسم المستخدم الحقيقي).
  Future<void> _ensureCurrentUser() async {
    if (_currentUserId != null) return;

    final user = await SessionStorage.loadUser();
    _currentUserId = user?.id ?? _placeholderUserId;
    _currentUserName = user?.fullName ?? _placeholderUserName;

    if (_seedPatched || user == null) return;
    _seedPatched = true;

    final seedGroup = _groups['grp_a204'];
    if (seedGroup == null) return;
    _groups['grp_a204'] = StudentGroupModel(
      id: seedGroup.id,
      code: seedGroup.code,
      maxMembers: seedGroup.maxMembers,
      members: [
        for (final member in seedGroup.members)
          member.id == _placeholderUserId
              ? GroupMemberModel(
                id: _currentUserId!,
                name: _currentUserName!,
                isLeader: member.isLeader,
              )
              : member,
      ],
    );
  }

  Future<GroupsDataModel> fetchGroupsData() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final myGroup =
        _currentUserGroupId != null ? _groups[_currentUserGroupId] : null;
    return GroupsDataModel(
      myGroup: myGroup,
      invites: List.unmodifiable(_invites),
    );
  }

  Future<StudentGroupModel> createGroup() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    if (_currentUserGroupId != null) {
      throw const GroupsException(
        'أنت منضم بالفعل إلى غروب. يجب مغادرته أولاً.',
      );
    }

    final id = 'grp_${DateTime.now().millisecondsSinceEpoch}';
    final group = StudentGroupModel(
      id: id,
      code: 'GRP-2025-${_codeCounter++}',
      maxMembers: 4,
      members: [
        GroupMemberModel(
          id: _currentUserId!,
          name: _currentUserName!,
          isLeader: true,
        ),
      ],
    );

    _groups[id] = group;
    _currentUserGroupId = id;
    return group;
  }

  Future<StudentGroupModel> joinGroupByCode(String code) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final match = _groups.values.where((g) => g.code == code.trim()).toList();
    if (match.isEmpty) {
      throw const GroupsException(
        'كود الغروب غير صحيح.',
        type: ApiErrorType.notFound,
      );
    }

    final target = match.first;
    if (target.isFull) {
      throw const GroupsException('اكتمل عدد أعضاء هذا الغروب بالفعل.');
    }
    if (target.id == _currentUserGroupId) {
      throw const GroupsException('أنت منضم بالفعل إلى هذا الغروب.');
    }

    _removeCurrentUserFromCurrentGroup();

    final updated = StudentGroupModel(
      id: target.id,
      code: target.code,
      maxMembers: target.maxMembers,
      members: [
        ...target.members,
        GroupMemberModel(
          id: _currentUserId!,
          name: _currentUserName!,
          isLeader: false,
        ),
      ],
    );
    _groups[target.id] = updated;
    _currentUserGroupId = target.id;
    return updated;
  }

  Future<void> inviteMember(String identifier) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    if (identifier.trim().isEmpty) {
      throw const GroupsException('يرجى إدخال بريد إلكتروني أو رقم جوال صحيح.');
    }

    final myGroup =
        _currentUserGroupId != null ? _groups[_currentUserGroupId] : null;
    if (myGroup == null) {
      throw const GroupsException('يجب الانضمام إلى غروب أو إنشاء واحد أولاً.');
    }
    if (myGroup.isFull) {
      throw const GroupsException('اكتمل عدد أعضاء الغروب بالفعل.');
    }
    // محاكاة إرسال الدعوة فقط، دون إضافة عضو فعلي (لا يوجد دليل مستخدمين حقيقي).
  }

  Future<StudentGroupModel> acceptInvite(String inviteId) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final invite = _invites.where((i) => i.id == inviteId).toList();
    if (invite.isEmpty) {
      throw const GroupsException(
        'لم يتم العثور على الدعوة.',
        type: ApiErrorType.notFound,
      );
    }

    final target = _groups[invite.first.groupId];
    if (target == null || target.isFull) {
      throw const GroupsException('لم يعد بالإمكان الانضمام إلى هذا الغروب.');
    }

    _removeCurrentUserFromCurrentGroup();

    final updated = StudentGroupModel(
      id: target.id,
      code: target.code,
      maxMembers: target.maxMembers,
      members: [
        ...target.members,
        GroupMemberModel(
          id: _currentUserId!,
          name: _currentUserName!,
          isLeader: false,
        ),
      ],
    );
    _groups[target.id] = updated;
    _currentUserGroupId = target.id;
    _invites.removeWhere((i) => i.id == inviteId);
    return updated;
  }

  Future<void> declineInvite(String inviteId) async {
    await Future.delayed(_networkDelay);
    _invites.removeWhere((i) => i.id == inviteId);
  }

  /// مغادرة الغروب الحالي. إن كان المستخدم هو القائد وهناك أعضاء آخرون،
  /// يجب نقل القيادة إليهم أولاً عبر [transferLeadership] قبل المغادرة.
  Future<void> leaveGroup() async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final group =
        _currentUserGroupId != null ? _groups[_currentUserGroupId] : null;
    if (group == null) {
      throw const GroupsException('أنت لست منضماً إلى أي غروب.');
    }

    final isLeader = group.members.any(
      (m) => m.id == _currentUserId && m.isLeader,
    );
    if (isLeader && group.members.length > 1) {
      throw const GroupsException(
        'يجب نقل القيادة إلى عضو آخر أولاً قبل مغادرة الغروب.',
      );
    }

    final wasLastMember = group.members.length <= 1;
    _removeCurrentUserFromCurrentGroup();
    if (wasLastMember) {
      _groups.remove(group.id);
    }
  }

  /// نقل قيادة الغروب الحالي إلى عضو آخر (متاح فقط للقائد الحالي).
  Future<StudentGroupModel> transferLeadership(String newLeaderId) async {
    await _ensureCurrentUser();
    await Future.delayed(_networkDelay);

    final group =
        _currentUserGroupId != null ? _groups[_currentUserGroupId] : null;
    if (group == null) {
      throw const GroupsException('أنت لست منضماً إلى أي غروب.');
    }

    final isLeader = group.members.any(
      (m) => m.id == _currentUserId && m.isLeader,
    );
    if (!isLeader) {
      throw const GroupsException('فقط قائد الغروب يمكنه نقل القيادة.');
    }
    if (!group.members.any((m) => m.id == newLeaderId)) {
      throw const GroupsException('العضو المحدد غير موجود ضمن الغروب.');
    }

    final updated = StudentGroupModel(
      id: group.id,
      code: group.code,
      maxMembers: group.maxMembers,
      members: [
        for (final member in group.members)
          GroupMemberModel(
            id: member.id,
            name: member.name,
            isLeader: member.id == newLeaderId,
          ),
      ],
    );
    _groups[group.id] = updated;
    return updated;
  }

  void _removeCurrentUserFromCurrentGroup() {
    if (_currentUserGroupId == null) return;
    final current = _groups[_currentUserGroupId];
    if (current == null) return;

    final remainingMembers =
        current.members.where((m) => m.id != _currentUserId).toList();
    _groups[current.id] = StudentGroupModel(
      id: current.id,
      code: current.code,
      maxMembers: current.maxMembers,
      members: remainingMembers,
    );
    _currentUserGroupId = null;
  }
}
