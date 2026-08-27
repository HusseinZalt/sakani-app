import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/features/housing_request/data/models/housing_request_model.dart';

void main() {
  group('BuildingModel', () {
    test('parses id, name and floorsCount', () {
      final json = {'id': 3, 'name': 'مبنى C', 'floorsCount': 5};

      final model = BuildingModel.fromJson(json);

      expect(model.id, 3);
      expect(model.name, 'مبنى C');
      expect(model.floorsCount, 5);
    });

    test('handles a missing floorsCount as null', () {
      final json = {'id': 1, 'name': 'مبنى A'};

      final model = BuildingModel.fromJson(json);

      expect(model.floorsCount, isNull);
    });
  });

  group('DormRoomModel', () {
    test('parses id, roomNumber and floor', () {
      final json = {'id': 42, 'roomNumber': '304', 'floor': 3};

      final model = DormRoomModel.fromJson(json);

      expect(model.id, 42);
      expect(model.roomNumber, '304');
      expect(model.floor, 3);
    });
  });

  group('AllocationModel', () {
    test('parses vacatedAt when present', () {
      final json = {
        'roomNumber': '304',
        'buildingName': 'مبنى C',
        'allocatedAt': '2026-01-01T00:00:00Z',
        'vacatedAt': '2026-06-01T00:00:00Z',
      };

      final model = AllocationModel.fromJson(json);

      expect(model.vacatedAt, isNotNull);
    });

    test('leaves vacatedAt null when absent', () {
      final json = {
        'roomNumber': '304',
        'buildingName': 'مبنى C',
        'allocatedAt': '2026-01-01T00:00:00Z',
      };

      final model = AllocationModel.fromJson(json);

      expect(model.vacatedAt, isNull);
    });
  });
}
