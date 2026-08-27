import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/features/groups/data/pending_join_request_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PendingJoinRequestStorage', () {
    test('round-trips a saved code with its send time', () async {
      await PendingJoinRequestStorage.save('ABC123');

      final loaded = await PendingJoinRequestStorage.load();

      expect(loaded, isNotNull);
      expect(loaded!.code, 'ABC123');
      expect(loaded.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('returns null when nothing was saved', () async {
      final loaded = await PendingJoinRequestStorage.load();

      expect(loaded, isNull);
    });

    test('clear removes the saved request', () async {
      await PendingJoinRequestStorage.save('ABC123');
      await PendingJoinRequestStorage.clear();

      final loaded = await PendingJoinRequestStorage.load();

      expect(loaded, isNull);
    });
  });

  group('PendingJoinRequest', () {
    test('elapsed reflects how long ago sentAt was', () {
      final request = PendingJoinRequest(
        code: 'ABC123',
        sentAt: DateTime.now().subtract(const Duration(hours: 50)),
      );

      expect(request.elapsed, greaterThan(const Duration(hours: 48)));
    });
  });
}
