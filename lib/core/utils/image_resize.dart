import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// يضغط/يصغّر صورة إلى حد أقصى للأبعاد وجودة معيّنة داخل isolate منفصل
/// (عبر [compute]) بدل تمرير `maxWidth`/`maxHeight`/`imageQuality` مباشرة
/// لـ `ImagePicker.pickImage`.
///
/// السبب: على بعض الأجهزة (خصوصاً كاميرات عالية الدقة)، إجراء أندرويد
/// الأصلي لتصغير الصورة داخل `image_picker` يُعلّق التطبيق بالكامل بعد
/// التقاط الصورة مباشرة (مشكلة معروفة بالمكتبة، تظهر أحياناً فقط حسب
/// دقة كاميرا الجهاز — وهو بالضبط ما أبلغ عنه المستخدم: تجميد متكرر لكن
/// غير دائم بعد التقاط صورة، بشاشات مختلفة). الحل: نطلب من `pickImage`
/// الصورة الأصلية بلا أي تصغير (`ImageSource` فقط)، ثم نصغّرها نحن يدوياً
/// بكود Dart خالص هنا — بمعزل عن كل من الـ UI isolate وأي كود أصلي
/// للمنصة.
Future<Uint8List> compressImageBytes(
  Uint8List bytes, {
  int maxDimension = 1600,
  int quality = 80,
}) {
  return compute(_compress, _CompressArgs(bytes, maxDimension, quality));
}

class _CompressArgs {
  const _CompressArgs(this.bytes, this.maxDimension, this.quality);

  final Uint8List bytes;
  final int maxDimension;
  final int quality;
}

Uint8List _compress(_CompressArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;

  final isWide = decoded.width >= decoded.height;
  final needsResize =
      decoded.width > args.maxDimension || decoded.height > args.maxDimension;
  final resized =
      needsResize
          ? img.copyResize(
            decoded,
            width: isWide ? args.maxDimension : null,
            height: isWide ? null : args.maxDimension,
          )
          : decoded;

  return Uint8List.fromList(img.encodeJpg(resized, quality: args.quality));
}
