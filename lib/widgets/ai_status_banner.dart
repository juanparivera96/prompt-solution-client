import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../services/api_status.dart';

/// Rebuilds once a second with the whole seconds elapsed since [since].
class ElapsedBuilder extends StatefulWidget {
  final DateTime since;
  final Widget Function(BuildContext context, int seconds) builder;

  const ElapsedBuilder({super.key, required this.since, required this.builder});

  @override
  State<ElapsedBuilder> createState() => _ElapsedBuilderState();
}

class _ElapsedBuilderState extends State<ElapsedBuilder> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.since).inSeconds;
    return widget.builder(context, elapsed < 0 ? 0 : elapsed);
  }
}

/// Tells whether the recommendation API is awake: connecting, waking up
/// (with the seconds waited), ready, or not answering (with a retry button).
///
/// Shown in the QR simulator, so whoever runs the demo knows the AI will
/// answer before picking a merchant.
class AiStatusBanner extends StatelessWidget {
  final ApiStatus status;

  const AiStatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) {
        final server = 'Servidor: ${status.server}';
        final since = status.checkingSince;
        if (since != null) {
          return ElapsedBuilder(
            since: since,
            builder: (_, seconds) => seconds < ApiStatus.slowAfter.inSeconds
                ? _Banner(
                    color: AppColors.lightAccent,
                    busy: true,
                    title: 'Conectando con la IA…',
                    footnote: server,
                  )
                : _Banner(
                    color: AppColors.lightAccent,
                    busy: true,
                    title: 'Despertando la IA… $seconds s',
                    detail: 'El servidor gratuito se apaga cuando no se usa. '
                        'Puede tardar hasta un minuto.',
                    footnote: server,
                  ),
          );
        }
        switch (status.state) {
          case ApiState.ready:
            return _Banner(
              color: AppColors.lightSuccess,
              icon: Icons.check_circle_rounded,
              title: 'IA lista',
              detail: 'La recomendación saldrá del modelo.',
              footnote: server,
            );
          case ApiState.unreachable:
            return _Banner(
              color: AppColors.lightWarning,
              icon: Icons.cloud_off_rounded,
              title: 'La IA no responde',
              detail: 'La recomendación saldrá por reglas de beneficios.',
              footnote: server,
              actionLabel: 'REINTENTAR',
              onAction: status.check,
            );
          case ApiState.unknown:
          case ApiState.checking:
            return _Banner(
              color: AppColors.lightSecondaryText,
              icon: Icons.help_outline_rounded,
              title: 'IA sin comprobar',
              footnote: server,
              actionLabel: 'COMPROBAR',
              onAction: status.check,
            );
        }
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String title;
  final String? detail;

  /// Small print under the detail, e.g. the server the app talks to.
  final String? footnote;
  final IconData? icon;

  /// Shows a spinner instead of [icon].
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Banner({
    required this.color,
    required this.title,
    this.detail,
    this.footnote,
    this.icon,
    this.busy = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (busy)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightPrimaryText,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightSecondaryText,
                    ),
                  ),
                ],
                if (footnote != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    footnote!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.lightSecondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
