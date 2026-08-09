import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// يحوّل بايتات صورة مُلتقطة محلياً إلى Data URI (base64)، لتخزينها مؤقتاً
/// ضمن حقل [avatarUrl] بانتظار جاهزية رفع الصور إلى الباك إند الحقيقي —
/// عندها يكفي أن يعيد الباك إند رابط شبكة عادي فيعمل [avatarImageProvider]
/// معه دون أي تعديل.
String bytesToAvatarDataUri(Uint8List bytes) =>
    'data:image/jpeg;base64,${base64Encode(bytes)}';

/// يبني [ImageProvider] مناسباً لقيمة [avatarUrl]: صورة من الذاكرة إذا كانت
/// Data URI محلي، أو صورة شبكة عادية إذا كانت رابطاً حقيقياً من الباك إند.
ImageProvider avatarImageProvider(String avatarUrl) {
  const prefix = 'data:image/jpeg;base64,';
  if (avatarUrl.startsWith(prefix)) {
    return MemoryImage(base64Decode(avatarUrl.substring(prefix.length)));
  }
  return NetworkImage(avatarUrl);
}
