import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/features/notifications/data/models/app_notification_model.dart';

void main() {
  group('AppNotificationModel', () {
    test('parses group_join_request notification type and assigns info colorKey', () {
      final json = {
        'notificationId': 55,
        'title': 'طلب انضمام جديد',
        'body': 'يرغب طالب بالانضمام إلى مجموعتك السكنية',
        'createdAt': '2026-08-24T10:00:00Z',
        'isRead': false,
        'data': '{"type": "group_join_request", "relatedId": "grp-1"}',
      };

      final model = AppNotificationModel.fromJson(json);

      expect(model.id, equals('55'));
      expect(model.type, equals('group_join_request'));
      expect(model.colorKey, equals('info'));
      expect(model.relatedId, equals('grp-1'));
      expect(model.isUnread, isTrue);
    });
  });
}
