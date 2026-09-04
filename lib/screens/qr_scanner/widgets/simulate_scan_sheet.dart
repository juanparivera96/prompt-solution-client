import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// A preset merchant scenario used by the "Simular QR" demo flow.
/// The payload matches the format decoded by MockRepository.decodeQr:
///   `id|name|location|category|amount`
class ScanScenario {
  final String label;
  final String description;
  final IconData icon;
  final String payload;

  const ScanScenario({
    required this.label,
    required this.description,
    required this.icon,
    required this.payload,
  });
}

const List<ScanScenario> kDemoScenarios = [
  ScanScenario(
    label: 'Restaurante El Portal',
    description: 'Bogotá · \$145.200 · restaurantes',
    icon: Icons.restaurant_rounded,
    payload: 'TXN-99284-B|Restaurante El Portal|Bogotá, COL|restaurant|145200',
  ),
  ScanScenario(
    label: 'Supermercado Central',
    description: 'Medellín · \$320.000 · supermercado',
    icon: Icons.local_grocery_store_rounded,
    payload: 'TXN-55110-A|Supermercado Central|Medellín, COL|grocery|320000',
  ),
  ScanScenario(
    label: 'Aerolínea Andes',
    description: 'Cali · \$980.000 · viaje',
    icon: Icons.flight_takeoff_rounded,
    payload: 'TXN-77321-C|Aerolínea Andes|Cali, COL|travel|980000',
  ),
];

/// Bottom sheet that lets the user pick a preset QR payload.
/// Returns the selected payload, or null if dismissed.
class SimulateScanSheet extends StatelessWidget {
  const SimulateScanSheet({super.key});

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
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightOutline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Simular escaneo QR',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Elige un comercio para ver cómo cambia la recomendación de pago.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final s in kDemoScenarios) ...[
            _ScenarioTile(
              scenario: s,
              onTap: () => Navigator.of(context).pop(s.payload),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final ScanScenario scenario;
  final VoidCallback onTap;

  const _ScenarioTile({required this.scenario, required this.onTap});

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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.lightAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(scenario.icon,
                    color: AppColors.lightAccent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.label,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      scenario.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.lightSecondaryText),
            ],
          ),
        ),
      ),
    );
  }
}
