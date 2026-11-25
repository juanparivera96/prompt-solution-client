import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../data/mock_repository.dart';
import '../models/demo_profile.dart';

/// "Usuarios de demostración": lists the demo customers with their username
/// and password. Tapping one calls [onSelected], which fills the login form.
class DemoUsersButton extends StatelessWidget {
  final void Function(DemoProfile profile) onSelected;

  const DemoUsersButton({super.key, required this.onSelected});

  Future<void> _open(BuildContext context) async {
    final profile = await showModalBottomSheet<DemoProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DemoUsersSheet(),
    );
    if (profile != null) onSelected(profile);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.groups_rounded, size: 18),
      label: const Text('USUARIOS DE DEMOSTRACIÓN'),
    );
  }
}

class _DemoUsersSheet extends StatelessWidget {
  const _DemoUsersSheet();

  static const _repo = MockRepository();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Usuarios de demostración',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Clientes sintéticos. Toca uno para llenar el usuario y la '
              'contraseña.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final profile in _repo.demoProfiles()) ...[
              _DemoUserTile(
                profile: profile,
                onTap: () => Navigator.of(context).pop(profile),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _DemoUserTile extends StatelessWidget {
  final DemoProfile profile;
  final VoidCallback onTap;

  const _DemoUserTile({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightOutline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.lightAccent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Usuario: ${profile.username} · '
                      'Contraseña: ${profile.password}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      profile.summary,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
