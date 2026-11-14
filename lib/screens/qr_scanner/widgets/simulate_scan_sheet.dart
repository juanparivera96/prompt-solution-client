import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/mock_repository.dart';
import '../../../models/demo_profile.dart';
import '../../../services/api_status.dart';
import '../../../services/session_manager.dart';
import '../../../widgets/ai_status_banner.dart';

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
    label: 'Café La Candelaria',
    description: 'Bogotá · \$48.000 · restaurantes',
    icon: Icons.local_cafe_rounded,
    payload: 'TXN-20417-K|Café La Candelaria|Bogotá, COL|restaurant|48000',
  ),
  ScanScenario(
    label: 'Supermercado Central',
    description: 'Medellín · \$320.000 · supermercado',
    icon: Icons.local_grocery_store_rounded,
    payload: 'TXN-55110-A|Supermercado Central|Medellín, COL|grocery|320000',
  ),
  ScanScenario(
    label: 'Estación El Dorado',
    description: 'Bogotá · \$86.000 · combustible',
    icon: Icons.local_gas_station_rounded,
    payload: 'TXN-31876-G|Estación El Dorado|Bogotá, COL|fuel|86000',
  ),
  ScanScenario(
    label: 'Moda Andina',
    description: 'Cali · \$215.000 · ropa',
    icon: Icons.checkroom_rounded,
    payload: 'TXN-64092-R|Moda Andina|Cali, COL|clothing|215000',
  ),
  ScanScenario(
    label: 'Farmacia San Rafael',
    description: 'Bogotá · \$33.500 · farmacia',
    icon: Icons.local_pharmacy_rounded,
    payload: 'TXN-48215-F|Farmacia San Rafael|Bogotá, COL|pharmacy|33500',
  ),
  // Category the AI model was not trained on: shows the rule-based fallback.
  ScanScenario(
    label: 'Aerolínea Andes',
    description: 'Cali · \$980.000 · viaje (fuera del modelo de IA)',
    icon: Icons.flight_takeoff_rounded,
    payload: 'TXN-77321-C|Aerolínea Andes|Cali, COL|travel|980000',
  ),
];

/// Bottom sheet that lets the user pick a buyer profile and a preset QR
/// payload. Returns the selected payload, or null if dismissed; the profile
/// is stored in [SessionManager].
///
/// It also shows whether the recommendation API is awake, and wakes it up
/// if needed, so the demo doesn't start while the AI can't answer.
class SimulateScanSheet extends StatefulWidget {
  /// Injected in tests. By default, the status the whole app shares.
  final ApiStatus? status;

  const SimulateScanSheet({super.key, this.status});

  @override
  State<SimulateScanSheet> createState() => _SimulateScanSheetState();
}

class _SimulateScanSheetState extends State<SimulateScanSheet> {
  static const _repo = MockRepository();

  late final ApiStatus _status = widget.status ?? ApiStatus.instance;

  late DemoProfile _profile =
      _repo.profileById(SessionManager.instance.demoProfileId);

  @override
  void initState() {
    super.initState();
    // Joins the check already in progress, if any.
    if (!_status.isFresh) _status.check();
  }

  void _selectProfile(DemoProfile profile) {
    SessionManager.instance.demoProfileId = profile.id;
    setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            'Elige un comprador y un comercio para ver cómo cambia la '
            'recomendación de pago.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AiStatusBanner(status: _status),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'PERFIL DEL COMPRADOR (DEMO)',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.lightSecondaryText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final p in _repo.demoProfiles())
                ChoiceChip(
                  label: Text(p.name),
                  selected: p.id == _profile.id,
                  onSelected: (_) => _selectProfile(p),
                  showCheckmark: false,
                  selectedColor: AppColors.lightAccent,
                  backgroundColor: AppColors.lightSurface,
                  side: const BorderSide(color: AppColors.lightOutline),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: p.id == _profile.id
                        ? Colors.white
                        : AppColors.lightPrimaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _profile.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'COMERCIO',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.lightSecondaryText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final s in kDemoScenarios) ...[
            _ScenarioTile(
              scenario: s,
              onTap: () => Navigator.of(context).pop(s.payload),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
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
