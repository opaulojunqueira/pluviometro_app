import 'package:flutter/material.dart';
import 'package:pluviometro_app/features/dashboard/widgets/rain_classification.dart';

/// Shows the agronomy-based classification of the current month's rainfall.
/// Color and icon change depending on the intensity level.
class RainClassificationCard extends StatelessWidget {
  final double monthlyMm;

  const RainClassificationCard({super.key, required this.monthlyMm});

  @override
  Widget build(BuildContext context) {
    final classification = RainClassification.fromMillimeters(monthlyMm);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: classification.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: classification.color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: classification.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              classification.icon,
              color: classification.color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            classification.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: classification.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'no mês atual',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '${monthlyMm.toStringAsFixed(1)} mm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: classification.color,
            ),
          ),
        ],
      ),
    );
  }
}
