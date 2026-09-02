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

  group('HousingRequestModel.isPaid', () {
    Map<String, dynamic> baseJson({bool? isPaid}) => {
      'id': 1,
      'gender': 0,
      'governorateId': 1,
      'academicLevel': 2,
      'detailedAddress': 'عنوان',
      'hasSpecialNeeds': false,
      'isPreviousResident': false,
      'status': 2,
      'submittedAt': '2026-01-01T00:00:00Z',
      if (isPaid != null) 'isPaid': isPaid,
    };

    test('parses isPaid true from the server field', () {
      final model = HousingRequestModel.fromJson(baseJson(isPaid: true));

      expect(model.isPaid, isTrue);
    });

    test('parses isPaid false from the server field', () {
      final model = HousingRequestModel.fromJson(baseJson(isPaid: false));

      expect(model.isPaid, isFalse);
    });

    test('defaults isPaid to false when the field is absent', () {
      final model = HousingRequestModel.fromJson(baseJson());

      expect(model.isPaid, isFalse);
    });
  });

  group('HousingRequestModel.feeAmount', () {
    Map<String, dynamic> baseJson({num? feeAmount}) => {
      'id': 1,
      'gender': 0,
      'governorateId': 1,
      'academicLevel': 2,
      'detailedAddress': 'عنوان',
      'hasSpecialNeeds': false,
      'isPreviousResident': false,
      'status': 2,
      'submittedAt': '2026-01-01T00:00:00Z',
      if (feeAmount != null) 'feeAmount': feeAmount,
    };

    test('parses an integer feeAmount as double', () {
      final model = HousingRequestModel.fromJson(baseJson(feeAmount: 25));

      expect(model.feeAmount, 25.0);
    });

    test('parses a decimal feeAmount', () {
      final model = HousingRequestModel.fromJson(baseJson(feeAmount: 25.5));

      expect(model.feeAmount, 25.5);
    });

    test('leaves feeAmount null when the field is absent', () {
      final model = HousingRequestModel.fromJson(baseJson());

      expect(model.feeAmount, isNull);
    });
  });
}
