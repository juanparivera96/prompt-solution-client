import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/session_manager.dart';
import 'widgets/scan_verification_sheet.dart';
import 'widgets/simulate_scan_sheet.dart';

/// Full-screen camera view that reads merchant QR codes.
/// On a successful scan we pause the controller and show a modal login
/// (verification is required before revealing payment recommendations).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    await _handlePayload(code);
  }

  /// Shared post-scan flow: pause camera → require login (if none) → navigate.
  /// Reused by the real detector and by the "SIMULAR QR" demo button.
  Future<void> _handlePayload(String payload) async {
    if (_handled) return;
    _handled = true;
    await _controller.stop();
    if (!mounted) return;

    // Skip verification when the user already has an active session.
    if (SessionManager.instance.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentRecommendation,
        arguments: payload,
      );
      return;
    }

    final loggedIn = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScanVerificationSheet(),
    );

    if (!mounted) return;
    if (loggedIn == true) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentRecommendation,
        arguments: payload,
      );
    } else {
      _handled = false;
      await _controller.start();
    }
  }

  Future<void> _openSimulator() async {
    final payload = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SimulateScanSheet(),
    );
    if (payload == null || !mounted) return;
    await _handlePayload(payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // dim overlay + centered viewfinder
          Container(color: Colors.black.withValues(alpha: 0.35)),
          const Center(child: _Viewfinder()),
          Column(
            children: [
              _TopBar(onClose: () => Navigator.of(context).pop()),
              const Spacer(),
              const _Hint(),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xxl,
                  right: AppSpacing.xxl,
                  bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                ),
                child: _SimulateButton(onPressed: _openSimulator),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightPrimary.withValues(alpha: 0.8),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        bottom: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Banco Inteligente Javeriana',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Escaneando Código QR...',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          color: AppColors.lightAccent,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Alinee el código QR dentro del recuadro',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Demo helper — replaces the need for a printed QR while prototyping.
class _SimulateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SimulateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
        label: Text(
          'SIMULAR QR (DEMO)',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
