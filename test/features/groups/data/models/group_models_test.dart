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
}
