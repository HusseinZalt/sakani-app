import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/features/groups/data/models/group_models.dart';
import 'package:sakani/features/groups/domain/entities/group_invitation.dart';

void main() {
  group('GroupInvitationModel', () {
    test('parses invitedStudentName into studentName', () {
      final json = {
        'id': 101,
        'invitedStudentId': 'std-123',
        'status': 0,
        'sentAt': '2026-08-24T12:00:00Z',
        'invitedStudentName': 'أحمد علي',
      };

      final model = GroupInvitationModel.fromJson(json);

      expect(model.id, equals(101));
      expect(model.invitedStudentId, equals('std-123'));
      expect(model.status, equals(InvitationStatus.pending));
      expect(model.studentName, equals('أحمد علي'));
    });

    test('handles missing invitedStudentName as null', () {
      final json = {
        'id': 102,
        'invitedStudentId': 'std-456',
        'status': 1,
        'sentAt': '2026-08-24T12:00:00Z',
      };

      final model = GroupInvitationModel.fromJson(json);

      expect(model.id, equals(102));
      expect(model.invitedStudentId, equals('std-456'));
      expect(model.status, equals(InvitationStatus.accepted));
      expect(model.studentName, isNull);
    });
  });

  group('StudentGroupModel', () {
    test('parses members into memberNames keyed by studentId', () {
      final json = {
        'id': 5,
        'code': 'GRP-001',
        'leaderId': 'std-1',
        'maxMembers': 4,
        'memberStudentIds': ['std-1', 'std-2'],
        'status': 0,
        'members': [
          {'studentId': 'std-1', 'name': 'خالد يوسف'},
          {'studentId': 'std-2', 'name': 'أحمد علي'},
        ],
      };

      final model = StudentGroupModel.fromJson(json);

      expect(model.memberNames, {
        'std-1': 'خالد يوسف',
        'std-2': 'أحمد علي',
      });
    });

    test('handles a missing members field as an empty map', () {
      final json = {
        'id': 6,
        'code': 'GRP-002',
        'leaderId': 'std-1',
        'maxMembers': 4,
        'memberStudentIds': ['std-1'],
        'status': 0,
      };

      final model = StudentGroupModel.fromJson(json);

      expect(model.memberNames, isEmpty);
    });
  });
}
