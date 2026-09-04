import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/session_manager.dart';

/// Modal that requests user credentials after a successful QR scan.
/// Returns `true` when the user proceeds, `false` when it is dismissed.
class ScanVerificationSheet extends StatefulWidget {
  const ScanVerificationSheet({super.key});

  @override
  State<ScanVerificationSheet> createState() => _ScanVerificationSheetState();
}

class _ScanVerificationSheetState extends State<ScanVerificationSheet> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        top: AppSpacing.xxl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.lightPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Verificación Requerida',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Escaneo exitoso. Por favor inicie sesión para consultar sus beneficios.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          TextField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: () {
              SessionManager.instance.login();
              Navigator.of(context).pop(true);
            },
            child: const Text('INGRESAR'),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              SessionManager.instance.login();
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.fingerprint_rounded, size: 18),
            label: const Text('USAR BIOMETRÍA'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_rounded,
                  size: 16, color: AppColors.lightSuccess),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Acceso Seguro Encriptado',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.lightSecondaryText,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
