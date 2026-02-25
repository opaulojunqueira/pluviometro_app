import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animated bar chart displaying the last 6 months of total rainfall.
/// The current month bar is highlighted with the primary theme color.
class MonthlyBarChart extends StatelessWidget {
  /// Map of 'yyyy-MM' → total mm for each of the last N months.
  final Map<String, double> monthlyTotals;

  const MonthlyBarChart({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.isEmpty) return const SizedBox.shrink();

    final maxVal =
        monthlyTotals.values.fold(0.0, (a, b) => a > b ? a : b);
    final currentMonthKey =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chuva — Últimos 6 meses',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyTotals.entries.map((entry) {
                  final fraction =
                      maxVal > 0 ? (entry.value / maxVal) : 0.0;
                  final isCurrentMonth = entry.key == currentMonthKey;
                  final parts = entry.key.split('-');
                  final monthLabel = DateFormat('MMM', 'pt_BR').format(
                    DateTime(int.parse(parts[0]), int.parse(parts[1]), 1),
                  );

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Show value label only when there's actual rainfall
                          if (entry.value > 0)
                            Text(
                              entry.value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          // Animated bar — grows proportionally to max value
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: 70 * fraction +
                                (entry.value > 0 ? 4 : 2),
                            decoration: BoxDecoration(
                              color: isCurrentMonth
                                  ? Theme.of(context).primaryColor
                                  : Colors.blue.shade200,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isCurrentMonth
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentMonth
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
