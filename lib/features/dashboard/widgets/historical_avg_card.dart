import 'package:flutter/material.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// Card showing the historical monthly average rainfall and comparing it
/// to the current month. Shows an up/down badge if history is available.
class HistoricalAvgCard extends StatelessWidget {
  /// Current month total in mm.
  final double monthlyTotal;

  /// Average across all historical months with recorded rainfall.
  final double historicalAvg;

  const HistoricalAvgCard({
    super.key,
    required this.monthlyTotal,
    required this.historicalAvg,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory = historicalAvg > 0;
    final diff = monthlyTotal - historicalAvg;
    final isAbove = diff >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insights,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Média histórica mensal',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasHistory
                        ? '${historicalAvg.toStringAsFixed(1)} mm/mês'
                        : 'Sem dados suficientes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Delta badge — shown only when history is available
            if (hasHistory)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isAbove
                      ? AppColors.successSoft
                      : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: isAbove ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${diff.abs().toStringAsFixed(1)} mm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isAbove ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
