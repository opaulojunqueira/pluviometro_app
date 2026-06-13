import 'package:flutter/material.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// Mostra o número de dias com chuva no mês atual.
///
/// Estilo "soft + borda" — limpo e sólido, sem gradiente nem sombra pesada —
/// para combinar lado a lado com o card de classificação de chuva.
class RainyDaysCard extends StatelessWidget {
  final int rainyDays;

  const RainyDaysCard({super.key, required this.rainyDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            '$rainyDays',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Text(
            'dias com chuva',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'neste mês',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
