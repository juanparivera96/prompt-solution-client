import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/session_manager.dart';
import '../../widgets/secure_footer.dart';

/// Main login screen for Banco Inteligente Javeriana.
/// Offers a prominent QR shortcut that bypasses full login and jumps
/// straight to the camera (login is later required to see benefits).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    // MVP: no real auth. Any input opens the profile.
    SessionManager.instance.login();
    Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
  }

  void _openScanner() {
    Navigator.of(context).pushNamed(AppRoutes.qrScanner);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BrandHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Bienvenido de nuevo',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        hintText: 'Ingresa tu usuario',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              size: 18,
                              color: AppColors.lightSecondaryText,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Usar Biometría',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.lightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '¿Olvidaste tu contraseña?',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.lightAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _login,
                      child: const Text('INICIAR SESIÓN'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'ACCESO RÁPIDO',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.lightSecondaryText,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _QrShortcutCard(onTap: _openScanner),
                  ],
                ),
              ),
            ),
            const SecureFooter(label: 'CONEXIÓN SEGURA · SSL 256-BIT'),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.xxxl,
        bottom: AppSpacing.xxxl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Banco Inteligente Javeriana',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tu aliado financiero digital',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrShortcutCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QrShortcutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightAccent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/PSC_logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Consultar recomendaciones de pago',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Escanea y encuentra tu mejor opción de pago',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.lightSecondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text('ABRIR CÁMARA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
