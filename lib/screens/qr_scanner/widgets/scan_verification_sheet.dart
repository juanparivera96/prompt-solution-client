import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/login_controller.dart';
import '../../../widgets/demo_users_button.dart';

/// Modal that requests the customer's credentials after a QR scan, when
/// nobody is logged in. Returns `true` once a demo customer logs in (their
/// data is then in `SessionManager`), and null when it is dismissed.
class ScanVerificationSheet extends StatefulWidget {
  const ScanVerificationSheet({super.key});

  @override
  State<ScanVerificationSheet> createState() => _ScanVerificationSheetState();
}

class _ScanVerificationSheetState extends State<ScanVerificationSheet> {
  final _login = LoginController();
  bool _obscure = true;

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  void _loginWithPassword() {
    if (_login.loginWithPassword() != null) Navigator.of(context).pop(true);
  }

  void _loginWithBiometrics() {
    if (_login.loginWithBiometrics() != null) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
              'Escaneo exitoso. Por favor inicie sesión para consultar sus '
              'beneficios.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _login.username,
              onChanged: (_) => _login.edited(),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _login.password,
              onChanged: (_) => _login.edited(),
              onSubmitted: (_) => _loginWithPassword(),
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
            LoginError(controller: _login),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: _loginWithPassword,
              child: const Text('INGRESAR'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DemoUsersButton(onSelected: _login.fill),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _loginWithBiometrics,
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
      ),
    );
  }
}
