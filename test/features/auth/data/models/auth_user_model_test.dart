import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/features/auth/data/models/auth_user_model.dart';

void main() {
  group('AuthUserModel', () {
    Map<String, dynamic> baseJson() => {
      '_id': 'u1',
      'firstName': 'أحمد',
      'secondName': 'علي',
      'email': 'ahmad@example.com',
      'phoneNumber': '0999999999',
    };

    test('defaults notificationsEnabled to true when absent', () {
      final model = AuthUserModel.fromJson(baseJson());

      expect(model.notificationsEnabled, isTrue);
    });

    test('parses an explicit false notificationsEnabled', () {
      final json = baseJson()..['notificationsEnabled'] = false;

      final model = AuthUserModel.fromJson(json);

      expect(model.notificationsEnabled, isFalse);
    });
  });
}
