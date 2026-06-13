import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pluviometro_app/theme/app_colors.dart';

/// Comparativo de chuva acumulada por ano.
///
/// Ajuda o produtor a comparar safras rapidamente. O ano atual é destacado.
/// Cada barra é proporcional ao maior total do período exibido.
class YearlyComparisonCard extends StatelessWidget {
  /// Mapa ano → total em mm (do mais antigo para o mais recente).
  final Map<int, double> yearlyTotals;

  const YearlyComparisonCard({super.key, required this.yearlyTotals});

  @override
  Widget build(BuildContext context) {
    if (yearlyTotals.isEmpty) return const SizedBox.shrink();

    final maxVal = yearlyTotals.values.fold<double>(
      0.0,
      (a, b) => a > b ? a : b,
    );
    // Sem nenhum dado relevante, não há o que comparar.
    if (maxVal <= 0) return const SizedBox.shrink();

    final currentYear = DateTime.now().year;
    final numberFormat = NumberFormat('#,##0.0', 'pt_BR');
    final entries = yearlyTotals.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comparativo anual',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in entries) ...[
              _buildYearRow(
                year: entry.key,
                value: entry.value,
                maxVal: maxVal,
                isCurrent: entry.key == currentYear,
                numberFormat: numberFormat,
              ),
              if (entry.key != entries.last.key) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYearRow({
    required int year,
    required double value,
    required double maxVal,
    required bool isCurrent,
    required NumberFormat numberFormat,
  }) {
    final fraction = (value / maxVal).clamp(0.0, 1.0);
    final barColor = isCurrent
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.32);

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            '$year',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 10,
              color: AppColors.primarySoft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction == 0 ? 0.02 : fraction,
                child: Container(color: barColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            '${numberFormat.format(value)} mm',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
