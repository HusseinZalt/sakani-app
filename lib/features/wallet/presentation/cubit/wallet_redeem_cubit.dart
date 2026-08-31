import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_result.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_redeem_state.dart';

/// يدير حالة شحن الرصيد عبر كود QR واحد، عمر هذا الـ Cubit مرتبط بشاشة
/// المسح (`QrScanScreen`) فقط.
class WalletRedeemCubit extends Cubit<WalletRedeemState> {
  WalletRedeemCubit(this._repository) : super(const WalletRedeemIdle());

  final WalletRepository _repository;

  /// يرسل الكود المستخرج من ملصق QR مباشرة، بدون أي معالجة عليه. لا شيء
  /// يحدث إن كانت هناك محاولة جارية بالفعل — يمنع قارئ QR من إرسال نفس
  /// الكود عدة مرات متتالية أثناء وجوده أمام الكاميرا (يكتشفه عدة مرات
  /// بالثانية إلى أن تُغلق الشاشة).
  Future<void> redeem(String code) async {
    if (state is WalletRedeemLoading) return;

    emit(const WalletRedeemLoading());
    final result = await _repository.redeemVoucher(code);

    switch (result) {
      case ApiSuccess(:final data):
        emit(WalletRedeemSuccess(data));
      case ApiFailureResult(:final failure):
        emit(WalletRedeemFailure(failure));
    }
  }

  /// إعادة الحالة لبانتظار مسح جديد بعد فشل، للسماح بمحاولة كود آخر.
  void reset() => emit(const WalletRedeemIdle());
}
