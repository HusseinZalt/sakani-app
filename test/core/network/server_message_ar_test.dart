import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/core/network/server_message_ar.dart';

void main() {
  group('translateServerMessageAr', () {
    test('يترك النص العربي كما هو', () {
      const msg = 'لا يوجد غروب بهذا الكود.';
      expect(translateServerMessageAr(msg), msg);
    });

    test('يترجم عبارة إنجليزية معروفة إلى العربية', () {
      final result = translateServerMessageAr(
        'You must have an approved housing request to create a group.',
      );
      expect(result, contains('طلب سكن مقبول'));
      expect(RegExp(r'[a-zA-Z]').hasMatch(result), isFalse);
    });

    test('يطابق بغضّ النظر عن حالة الأحرف وبقية الصياغة', () {
      expect(
        translateServerMessageAr('ERROR: Insufficient balance for this payment'),
        contains('رصيد محفظتك غير كافٍ'),
      );
    });

    test('يعيد البديل الممرَّر عند نص إنجليزي غير معروف', () {
      const fallback = 'تعذّر تنفيذ العملية.';
      expect(
        translateServerMessageAr(
          'Some brand new server error',
          fallback: fallback,
        ),
        fallback,
      );
    });

    test('لا يُخرج أي حرف لاتيني مهما كان الدخل', () {
      for (final input in [
        null,
        '',
        '   ',
        'Totally unmapped english text',
        '42',
      ]) {
        final out = translateServerMessageAr(input);
        expect(out, isNotEmpty);
        expect(RegExp(r'[a-zA-Z]').hasMatch(out), isFalse, reason: 'input: $input');
      }
    });
  });
}
