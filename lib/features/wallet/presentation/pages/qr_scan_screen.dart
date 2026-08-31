import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_redeem_result.dart';
import '../cubit/wallet_redeem_cubit.dart';
import '../cubit/wallet_redeem_state.dart';

/// شاشة مسح ملصق QR لشحن رصيد المحفظة — ترجع [WalletRedeemResult] عبر
/// `Navigator.pop` عند نجاح الشحن، أو `null` عند الرجوع بدون شحن.
///
/// **ملاحظة مهمة:** توليد ملصقات الشحن (تحويلها لصور QR) مسؤولية "لوحة
/// التحكم الإدارية" فقط — راجع `flutter-wallet-integration.md`. هذه
/// الشاشة تمسح وترسل نص الكود كما هو فقط، ولا تولّده أبداً.
class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WalletRedeemCubit(WalletRepositoryImpl()),
      child: const _QrScanView(),
    );
  }
}

class _QrScanView extends StatefulWidget {
  const _QrScanView();

  @override
  State<_QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<_QrScanView> {
  final _controller = MobileScannerController();
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BuildContext context, BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    context.read<WalletRedeemCubit>().redeem(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: BlocConsumer<WalletRedeemCubit, WalletRedeemState>(
        listener: (context, state) {
          switch (state) {
            case WalletRedeemSuccess(:final result):
              context.pop(result);
            case WalletRedeemFailure(:final failure):
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(failure.message)));
              context.read<WalletRedeemCubit>().reset();
            case WalletRedeemIdle():
            case WalletRedeemLoading():
              break;
          }
        },
        builder: (context, state) {
          final isLoading = state is WalletRedeemLoading;

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect:
                    isLoading ? (_) {} : (capture) => _handleDetect(context, capture),
              ),
              Container(color: AppColors.black.withValues(alpha: 0.35)),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_forward,
                        onTap: () => context.pop(),
                      ),
                      _RoundIconButton(
                        icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () {
                          _controller.toggleTorch();
                          setState(() => _torchOn = !_torchOn);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 48,
                left: 24,
                right: 24,
                child: Text(
                  'وجّه الكاميرا نحو ملصق QR الخاص بشحن الرصيد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 15),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 20),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
