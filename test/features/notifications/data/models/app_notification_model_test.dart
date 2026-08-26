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

    test('falls back to now instead of throwing when createdAt is null', () {
      final json = {
        'notificationId': 56,
        'title': 'إشعار قديم',
        'isRead': true,
        'createdAt': null,
      };

      expect(() => AppNotificationModel.fromJson(json), returnsNormally);
      final model = AppNotificationModel.fromJson(json);
      expect(model.createdAt, isA<DateTime>());
    });

    test(
      'falls back to now instead of throwing when createdAt is malformed',
      () {
        final json = {
          'notificationId': 57,
          'title': 'إشعار بتاريخ غير صالح',
          'isRead': true,
          'createdAt': 'not-a-date',
        };

        expect(() => AppNotificationModel.fromJson(json), returnsNormally);
      },
    );
  });
}
